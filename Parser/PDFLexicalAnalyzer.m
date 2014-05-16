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
        state = ERROR_STATE;\
    }

#define EndState(pdfType) {\
        state = END_LEXEME_STATE;\
        *type = pdfType;\
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
    char *_pointer;
    char *_dataBegin;
    NSUInteger _len;
    NSString *_errorMessage;
}
@end

@implementation PDFLexicalAnalyzer

@synthesize errorMessage = _errorMessage;

- (id)initWithData:(NSData *)data
{
    if (self = [super init]) {
        _len = data.length;
        _dataBegin = (char*)data.bytes;
        _pointer = _dataBegin;
    }
    return self;
}

enum PDFLexicalAnalyzerStates
{
    ERROR_STATE = -1,
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
    IN_NUMBER_STATE,

    END_LEXEME_STATE,
};

- (const char*)nextLexeme:(NSUInteger*)len type:(enum PDFLexemeTypes*)type;
{
    *type = PDF_UNKNOWN_LEXEME;
    *len  = 0;
    
    enum PDFLexicalAnalyzerStates state = BEGIN_LEXEME_STATE;
    const char* lexeme = NULL;
    
    int bracketsCounter = 0;
    int dddCount = 0;
    
    while (state != ERROR_STATE && state != END_LEXEME_STATE && _pointer - _dataBegin < _len) {
        
        char ch = *_pointer;
        
        switch (state) {
            case BEGIN_LEXEME_STATE:
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
                        state = IN_NUMBER_STATE;
                        break;
                    default:
                        if (isBlankSymbol(ch) == 0) {
                            state = IN_LEXEME_STATE;
                        }
                        break;
                }
                
                lexeme = _pointer;
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
                
            case IN_NUMBER_STATE:
                if (isDigitSymbol(ch) == 0 || ch == 0) {
                    EndState(PDF_NUMBER_LEXEME_TYPE);
                }
                break;
                
            case IN_LEXEME_STATE:
                if (isBlankSymbol(ch) || ch == '[' || ch == '(' || ch == '<' || ch == '%' || ch == '/' || ch == ']' || ch == '>' || ch == 0) {
                    state = END_LEXEME_STATE;
                    if (_pointer - lexeme == 3 && strncmp(lexeme, "obj", 3) == 0) {
                        *type = PDF_OBJ_KEYWORD_LEXEME_TYPE;
                    } else if (_pointer - lexeme == 6 && strncmp(lexeme, "endobj", 6)) {
                        *type = PDF_ENDOBJ_KEYWORD_LEXEME_TYPE;
                    } else if (_pointer - lexeme == 4 && strncmp(lexeme, "xref", 4)) {
                        *type = PDF_XREF_KEYWORD_LEXEME_TYPE;
                    } else if (_pointer - lexeme == 9 && strncmp(lexeme, "startxref", 9)) {
                        *type = PDF_STARTXREF_KEYWORD_LEXEME_TYPE;
                    } else if (_pointer - lexeme == 6 && strncmp(lexeme, "stream", 6)) {
                        *type = PDF_STREAM_KEYWORD_LEXEME_TYPE;
                    } else if (_pointer - lexeme == 9 && strncmp(lexeme, "endstream", 9)) {
                        *type = PDF_ENDSTREAM_KEYWORD_LEXEME_TYPE;
                    } else if (_pointer - lexeme == 4 && strncmp(lexeme, "true", 4)) {
                        *type = PDF_TRUE_KEYWORD_LEXEME_TYPE;
                    } else if (_pointer - lexeme == 5 && strncmp(lexeme, "false", 5)) {
                        *type = PDF_FALSE_KEYWORD_LEXEME_TYPE;
                    } else if (_pointer - lexeme == 7 && strncmp(lexeme, "trailer", 7)) {
                        *type = PDF_TRAILER_KEYWORD_LEXEME_TYPE;
                    }
                }
                break;
                
            default:
                break;
        }
        
        if (state != END_LEXEME_STATE) {
            ++_pointer;
        }
    }
    
    if (state == END_LEXEME_STATE) {
        *len = _pointer - lexeme;
        return lexeme;
    }
    
    return NULL;
}

- (BOOL)skipBytesByCount:(NSUInteger)count
{
    if (_pointer + count - _dataBegin < _len) {
        _pointer += count;
        return YES;
    }
    return NO;
}

@end

#undef EndState
#undef ErrorState