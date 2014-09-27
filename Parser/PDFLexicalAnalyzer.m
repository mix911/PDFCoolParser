//
//  PDFLexicalAnalyzer.m
//  Parser
//
//  Created by demo on 13.05.14.
//  Copyright (c) 2014 Ptenster. All rights reserved.
//

#import "PDFLexicalAnalyzer.h"

#define ErrorState(message)\
    {\
        _errorMessage = message;\
        state = ERROR_LEXEME_STATE;\
    }

#define EndState(pdfType) {\
        state = END_LEXEME_STATE;\
        outState->current_type = pdfType;\
    }


static int isBlankSymbol(char ch)
{
    return ch == ' ' || ch == '\r' || ch == '\n' || ch == '\t';
}

static int isDigitSymbol(char ch)
{
    return '0' <= ch && ch <= '9';
}

static int isDigitOctSymbol(char ch)
{
    return '0' <= ch && ch <= '7';
}

static int isDigitHEXSymbol(char ch)
{
    return isDigitSymbol(ch) || ('A' <= ch && ch <= 'F') || ('a' <= ch && ch <= 'f');
}

static int isUnderSlashSymbol(char ch)
{
    return ch == 'n' || ch == 'r' || ch == 't' || ch == 'b' || ch == 'f' || ch == '(' || ch == ')' || ch == '\\';
}

@interface PDFLexicalAnalyzer()
{
    NSString *_errorMessage;
}
@end

@implementation PDFLexicalAnalyzer

@synthesize errorMessage = _errorMessage;

enum PDFLexicalAnalyzerStates
{
    ERROR_LEXEME_STATE = -1,
    BEGIN_LEXEME_STATE = 0,
    OPEN_TRIANGLE_BRACKET_STATE,
    CLOSE_TRIANGLE_BRACKET_STATE,
    IN_ARRAY_OPEN_BRACKET_STATE,
    IN_ARRAY_CLOSE_BRACKET_STATE,
    IN_DICTIONARY_OPEN_BRACKET_STATE,
    IN_DICTIONARY_CLOSE_BRACKET_STATE,
    IN_STRING_STATE,
    IN_STRING_CLOSE_STATE,
    IN_NAME_STATE,
    IN_COMMENT_STATE,
    IN_LEXEME_STATE,
    IN_HEX_STRING_STATE,
    IN_HEX_STRING_CLOSE_STATE,
    UNDER_SLASH_STATE,
    IN_OCTAL_DDD_WAIT_NOT_ZERO_STATE,
    IN_OCTAL_DDD_STATE,
    IN_NUMBER_AFTER_ONLY_POINT,
    IN_NUMBER_AFTER_PLUS,
    IN_NUMBER_AFTER_MINUS,
    IN_REAL_NUMBER,
    IN_INTEGRAL_NUMBER_PART_STATE,
    IN_UINTEGRAL_NUMBER_PART_STATE,
    END_LEXEME_STATE,
};

- (const char*)nextLexemeByState:(struct pdf_lexical_analyzer_state*)outState
{
    if (outState == NULL) {
        @throw [NSException exceptionWithName:@"Bad arguments" reason:@"'state' must be not NULL" userInfo:nil];
    }
    if (outState->current == NULL) {
        @throw [NSException exceptionWithName:@"Bad struct pdf_lexical_analyzer_state" reason:@"pdf_lexical_analyzer_state.current must be not NULL" userInfo:nil];
    }
    if (outState->end == NULL) {
        @throw [NSException exceptionWithName:@"Bad struct pdf_lexical_analyzer_state" reason:@"pdf_lexical_analyzer_state.end nust be not NULL" userInfo:nil];
    }
    // Default falues
    outState->current_type = PDF_UNKNOWN_LEXEME;
    outState->len = 0;
    enum PDFLexicalAnalyzerStates state = BEGIN_LEXEME_STATE;
    int bracketsCounter = 0;
    int dddCount = 0;
    // Find lexeme
    while (state != ERROR_LEXEME_STATE && state != END_LEXEME_STATE && outState->current != outState->end) {
        // Get current symbol
        char ch = *outState->current;
        // Analyze current state
        switch (state) {
            case BEGIN_LEXEME_STATE:
                // For current symbol
                switch (ch) {
                    case '[':
                        state = IN_ARRAY_OPEN_BRACKET_STATE;
                        break;
                    case ']':
                        state = IN_ARRAY_CLOSE_BRACKET_STATE;
                        break;
                    case '<':
                        state = OPEN_TRIANGLE_BRACKET_STATE;
                        break;
                    case '(':
                        state = IN_STRING_STATE;
                        break;
                    case '/':
                        state = IN_NAME_STATE;
                        break;
                    case '%':
                        state = IN_COMMENT_STATE;
                        break;
                    case '>':
                        state = CLOSE_TRIANGLE_BRACKET_STATE;
                        break;
                    case '.':
                        state = IN_NUMBER_AFTER_ONLY_POINT;
                        break;
                    case '-':
                        state = IN_NUMBER_AFTER_MINUS;
                        break;
                    case '+':
                        state = IN_NUMBER_AFTER_PLUS;
                        break;
                    case '0':
                    case '1':
                    case '2':
                    case '3':
                    case '4':
                    case '5':
                    case '6':
                    case '7':
                    case '8':
                    case '9':
                        state = IN_UINTEGRAL_NUMBER_PART_STATE;
                        break;
                    default:
                        if (isBlankSymbol(ch) == 0) {
                            state = IN_LEXEME_STATE;
                        }
                        break;
                }
                outState->lexeme = outState->current;
                break;
                
            case IN_ARRAY_OPEN_BRACKET_STATE:
                EndState(PDF_OPEN_ARRAY_LEXEME_TYPE);
                break;
                
            case IN_ARRAY_CLOSE_BRACKET_STATE:
                EndState(PDF_CLOSE_ARRAY_LEXEME_TYPE);
                break;
                
            case OPEN_TRIANGLE_BRACKET_STATE:
                if (ch == '<') {
                    state = IN_DICTIONARY_OPEN_BRACKET_STATE;
                } else if (isBlankSymbol(ch) || isDigitHEXSymbol(ch)) {
                    state = IN_HEX_STRING_STATE;
                }
                break;
                
            case CLOSE_TRIANGLE_BRACKET_STATE:
                if (ch == '>') {
                    state = IN_DICTIONARY_CLOSE_BRACKET_STATE;
                } else {
                    ErrorState(@"Brocken close dictionary bracket");
                }
                break;
                
            case IN_DICTIONARY_OPEN_BRACKET_STATE:
                EndState(PDF_OPEN_DICTIONARY_LEXEME_TYPE);
                break;
                
            case IN_DICTIONARY_CLOSE_BRACKET_STATE:
                EndState(PDF_CLOSE_DICTIONARY_LEXEME_TYPE);
                break;
                
            case IN_HEX_STRING_STATE:
                if (isDigitHEXSymbol(ch) == 0) {
                    if (ch == '>') {
                        state = IN_HEX_STRING_CLOSE_STATE;
                    } else if (isBlankSymbol(ch) == 0) {
                        ErrorState(@"Failed to parse hex string");
                    }
                }
                break;
                
            case IN_HEX_STRING_CLOSE_STATE:
                EndState(PDF_HEX_STRING_LEXEME_TYPE);
                break;
                
            case IN_STRING_STATE:
                if (ch == '\\') {
                    state = UNDER_SLASH_STATE;
                } else if (ch == '(') {
                    ++bracketsCounter;
                } else if (ch == ')') {
                    if (bracketsCounter) {
                        --bracketsCounter;
                    } else {
                        state = IN_STRING_CLOSE_STATE;
                    }
                }
                break;
                
            case IN_STRING_CLOSE_STATE:
                EndState(PDF_STRING_LEXEME_TYPE);
                break;
                
            case UNDER_SLASH_STATE:
                if (isUnderSlashSymbol(ch)) {
                    state = IN_STRING_STATE;
                } else if ('1' <= ch && ch <= '7') {
                    dddCount = 1;
                    state = IN_OCTAL_DDD_STATE;
                } else if (ch == '0') {
                    state = IN_OCTAL_DDD_WAIT_NOT_ZERO_STATE;
                    dddCount = 0;
                } else {
                    ErrorState(@"Bad symbol under slash");
                }
                break;
                
            case IN_OCTAL_DDD_WAIT_NOT_ZERO_STATE:
                if ('1' <= ch && ch <= '7') {
                    ++dddCount;
                    state = IN_OCTAL_DDD_STATE;
                } else if (ch != '0') {
                    dddCount = 0;
                    state = IN_STRING_STATE;
                }
                break;
                
            case IN_OCTAL_DDD_STATE:
                if (isDigitOctSymbol(ch)) {
                    if (dddCount < 3) {
                        ++dddCount;
                    } else {
                        state = IN_STRING_STATE;
                        dddCount = 0;
                    }
                } else if (ch == ')'){
                    state = IN_STRING_CLOSE_STATE;
                    dddCount = 0;
                } else {
                    state = IN_STRING_STATE;
                    dddCount = 0;
                }
                break;
                
            case IN_NAME_STATE:
                if (isBlankSymbol(ch) || ch == '[' || ch == '(' || ch == '<' || ch == '%' || ch == '/' || ch == 0) {
                    EndState(PDF_NAME_LEXEME_TYPE);
                }
                break;
                
            case IN_COMMENT_STATE:
                if (ch == '\r' || ch == '\n' || ch == 0) {
                    EndState(PDF_COMMENT_LEXEME_TYPE);
                }
                break;
                
            case IN_NUMBER_AFTER_MINUS:
                if (ch == '.') {
                    state = IN_NUMBER_AFTER_ONLY_POINT;
                } else if (isDigitSymbol(ch) == 0 || ch == 0) {
                    ErrorState(@"Number must contain digit after minus");
                } else {
                    state = IN_INTEGRAL_NUMBER_PART_STATE;
                }
                break;
                
            case IN_NUMBER_AFTER_PLUS:
                if (ch == '.') {
                    state = IN_NUMBER_AFTER_ONLY_POINT;
                } else if (isDigitSymbol(ch) == 0 || ch == 0) {
                    ErrorState(@"Number must contain digit after plus");
                } else {
                    state = IN_UINTEGRAL_NUMBER_PART_STATE;
                }
                break;
                
            case IN_INTEGRAL_NUMBER_PART_STATE:
                if (ch == '.') {
                    state = IN_REAL_NUMBER;
                } else if (isDigitSymbol(ch) == 0 || ch == 0) {
                    EndState(PDF_INT_NUMBER_TYPE);
                }
                break;
                
            case IN_UINTEGRAL_NUMBER_PART_STATE:
                if (ch == '.') {
                    state = IN_REAL_NUMBER;
                } else if (isDigitSymbol(ch) == 0 || ch == 0) {
                    EndState(PDF_UINT_NUMBER_TYPE);
                }
                break;
                
            case IN_NUMBER_AFTER_ONLY_POINT:
                if (isDigitSymbol(ch) == 0 || ch ==0) {
                    ErrorState(@"Number must contain digit befor or after point");
                } else {
                    state = IN_REAL_NUMBER;
                }
                break;
                
            case IN_REAL_NUMBER:
                if (isDigitSymbol(ch) == 0 || ch == 0) {
                    EndState(PDF_NUMBER_LEXEME_TYPE);
                }
                break;
                
            case IN_LEXEME_STATE:
                if (isBlankSymbol(ch) || ch == '[' || ch == '(' || ch == '<' || ch == '%' || ch == '/' || ch == ']' || ch == '>' || ch == 0) {
                    state = END_LEXEME_STATE;
                    if (outState->current - outState->lexeme == 3 && strncmp(outState->lexeme, "obj", 3) == 0) {
                        outState->current_type = PDF_OBJ_KEYWORD_LEXEME_TYPE;
                    } else if (outState->current - outState->lexeme == 6 && strncmp(outState->lexeme, "endobj", 6) == 0) {
                        outState->current_type = PDF_ENDOBJ_KEYWORD_LEXEME_TYPE;
                    } else if (outState->current - outState->lexeme == 4 && strncmp(outState->lexeme, "xref", 4) == 0) {
                        outState->current_type = PDF_XREF_KEYWORD_LEXEME_TYPE;
                    } else if (outState->current - outState->lexeme == 9 && strncmp(outState->lexeme, "startxref", 9) == 0) {
                        outState->current_type = PDF_STARTXREF_KEYWORD_LEXEME_TYPE;
                    } else if (outState->current - outState->lexeme == 6 && strncmp(outState->lexeme, "stream", 6) == 0) {
                        outState->current_type = PDF_STREAM_KEYWORD_LEXEME_TYPE;
                    } else if (outState->current - outState->lexeme == 9 && strncmp(outState->lexeme, "endstream", 9) == 0) {
                        outState->current_type = PDF_ENDSTREAM_KEYWORD_LEXEME_TYPE;
                    } else if (outState->current - outState->lexeme == 4 && strncmp(outState->lexeme, "true", 4) == 0) {
                        outState->current_type = PDF_TRUE_KEYWORD_LEXEME_TYPE;
                    } else if (outState->current - outState->lexeme == 5 && strncmp(outState->lexeme, "false", 5) == 0) {
                        outState->current_type = PDF_FALSE_KEYWORD_LEXEME_TYPE;
                    } else if (outState->current - outState->lexeme == 7 && strncmp(outState->lexeme, "trailer", 7) == 0) {
                        outState->current_type = PDF_TRAILER_KEYWORD_LEXEME_TYPE;
                    } else if (outState->current - outState->lexeme == 1 && strncmp(outState->lexeme, "R", 1) == 0) {
                        outState->current_type = PDF_R_KEYWORD_LEXEME;
                    } else if (outState->current - outState->lexeme == 4 && strncmp(outState->lexeme, "null", 4) == 0) {
                        outState->current_type = PDF_NULL_KEYWORD_LEXEME;
                    }
                }
                break;
                
            default:
                break;
        }
        
        if (state != END_LEXEME_STATE) {
            ++outState->current;
        }
    }
    
    if (state == END_LEXEME_STATE) {
        outState->len = outState->current - outState->lexeme;
        return outState->lexeme;
    }
    
    return NULL;
}

- (NSData*)getAndSkipBytesByCount:(NSUInteger)count state:(struct pdf_lexical_analyzer_state*)state
{
    NSData *res = nil;
    if (state->end - state->current <= count) {
        res = [NSData dataWithBytes:state->current length:state->end - state->current];
        state->current = state->end;
    } else {
        res = [NSData dataWithBytes:state->current length:count];
        state->current += count;
    }
    return res;
}

- (NSUInteger)skipBytesByCount:(NSUInteger)count state:(struct pdf_lexical_analyzer_state*)state
{
    if (state->end - state->current <= count) {
        count = state->end - state->current;
    }
    state->current += count;
    return count;
}

@end

#undef EndState
#undef ErrorState