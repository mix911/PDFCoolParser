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
        _state = ERROR_LEXEME_STATE;\
    }

#define EndState(pdfType) {\
        _state = END_LEXEME_STATE;\
        _outState->current_type = pdfType;\
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
    IN_NUMBER_AFTER_ONLY_POINT_STATE,
    IN_NUMBER_AFTER_PLUS_STATE,
    IN_NUMBER_AFTER_MINUS_STATE,
    IN_REAL_NUMBER_STATE,
    IN_INTEGRAL_NUMBER_PART_STATE,
    IN_UINTEGRAL_NUMBER_PART_STATE,
    END_LEXEME_STATE,
    COUNT_OF_STATES,
};


@interface PDFLexicalAnalyzer()
{
    NSString *_errorMessage;
    struct pdf_lexical_analyzer_state* _outState;
    enum PDFLexicalAnalyzerStates _state;
    char _ch;
    int _bracketsCounter;
    int _dddCount;
    NSMutableArray* _statesTable;
}
@end

#define AddToTable(i, method) _statesTable[i] = [NSValue valueWithPointer:@selector(method)]

@implementation PDFLexicalAnalyzer

@synthesize errorMessage = _errorMessage;

- (instancetype)init
{
    self = [super init];
    if (self) {
        _statesTable = [[NSMutableArray alloc] initWithCapacity:COUNT_OF_STATES];
        for (int i = BEGIN_LEXEME_STATE; i < COUNT_OF_STATES; ++i) {
            [_statesTable addObject:@(0)];
        }
        AddToTable(BEGIN_LEXEME_STATE, beginState);
        AddToTable(OPEN_TRIANGLE_BRACKET_STATE, openTriangleBracketState);
        AddToTable(CLOSE_TRIANGLE_BRACKET_STATE, closeTriangleBracketState);
        AddToTable(IN_ARRAY_OPEN_BRACKET_STATE, inArrayOpenBracketState);
        AddToTable(IN_ARRAY_CLOSE_BRACKET_STATE, inArrayCloseBracketState);
        AddToTable(IN_DICTIONARY_OPEN_BRACKET_STATE, inDictionaryOpenBracketState);
        AddToTable(IN_DICTIONARY_CLOSE_BRACKET_STATE, inDictionaryCloseBracketState);
        AddToTable(IN_STRING_STATE, inStringState);
        AddToTable(IN_STRING_CLOSE_STATE, inStringCloseState);
        AddToTable(IN_NAME_STATE, inNameState);
        AddToTable(IN_COMMENT_STATE, inCommentState);
        AddToTable(IN_LEXEME_STATE, inLexemeState);
        AddToTable(IN_HEX_STRING_STATE, inHexStringState);
        AddToTable(IN_HEX_STRING_CLOSE_STATE, inHexStringCloseState);
        AddToTable(UNDER_SLASH_STATE, underSlashState);
        AddToTable(IN_OCTAL_DDD_WAIT_NOT_ZERO_STATE, inOctalDDDWaitNotZeroState);
        AddToTable(IN_OCTAL_DDD_STATE, inOctalDDDState);
        AddToTable(IN_NUMBER_AFTER_ONLY_POINT_STATE, inNumberAfterOnlyPointState);
        AddToTable(IN_NUMBER_AFTER_MINUS_STATE, inNumberAfterMinusState);
        AddToTable(IN_NUMBER_AFTER_PLUS_STATE, inNumberAfterPlusState);
        AddToTable(IN_REAL_NUMBER_STATE, inRealNumberState);
        AddToTable(IN_INTEGRAL_NUMBER_PART_STATE, inIntegralNumberPartState);
        AddToTable(IN_UINTEGRAL_NUMBER_PART_STATE, inUIntegralNumberPartState);
    }
    return self;
}

- (void)beginState
{
    // For current symbol
    switch (_ch) {
        case '[':
            _state = IN_ARRAY_OPEN_BRACKET_STATE;
            break;
        case ']':
            _state = IN_ARRAY_CLOSE_BRACKET_STATE;
            break;
        case '<':
            _state = OPEN_TRIANGLE_BRACKET_STATE;
            break;
        case '(':
            _state = IN_STRING_STATE;
            break;
        case '/':
            _state = IN_NAME_STATE;
            break;
        case '%':
            _state = IN_COMMENT_STATE;
            break;
        case '>':
            _state = CLOSE_TRIANGLE_BRACKET_STATE;
            break;
        case '.':
            _state = IN_NUMBER_AFTER_ONLY_POINT_STATE;
            break;
        case '-':
            _state = IN_NUMBER_AFTER_MINUS_STATE;
            break;
        case '+':
            _state = IN_NUMBER_AFTER_PLUS_STATE;
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
            _state = IN_UINTEGRAL_NUMBER_PART_STATE;
            break;
        default:
            if (isBlankSymbol(_ch) == 0) {
                _state = IN_LEXEME_STATE;
            }
            break;
    }
    _outState->lexeme = _outState->current;
}

- (void)openTriangleBracketState
{
    if (_ch == '<') {
        _state = IN_DICTIONARY_OPEN_BRACKET_STATE;
    } else if (isBlankSymbol(_ch) || isDigitHEXSymbol(_ch)) {
        _state = IN_HEX_STRING_STATE;
    }
}

- (void)closeTriangleBracketState
{
    if (_ch == '>') {
        _state = IN_DICTIONARY_CLOSE_BRACKET_STATE;
    } else {
        ErrorState(@"Brocken close dictionary bracket");
    }
}

- (void)inHexStringState
{
    if (isDigitHEXSymbol(_ch) == 0) {
        if (_ch == '>') {
            _state = IN_HEX_STRING_CLOSE_STATE;
        } else if (isBlankSymbol(_ch) == 0) {
            ErrorState(@"Failed to parse hex string");
        }
    }
}

- (void)inStringState
{
    if (_ch == '\\') {
        _state = UNDER_SLASH_STATE;
    } else if (_ch == '(') {
        ++_bracketsCounter;
    } else if (_ch == ')') {
        if (_bracketsCounter) {
            --_bracketsCounter;
        } else {
            _state = IN_STRING_CLOSE_STATE;
        }
    }
}

- (void)underSlashState
{
    if (isUnderSlashSymbol(_ch)) {
        _state = IN_STRING_STATE;
    } else if ('1' <= _ch && _ch <= '7') {
        _dddCount = 1;
        _state = IN_OCTAL_DDD_STATE;
    } else if (_ch == '0') {
        _state = IN_OCTAL_DDD_WAIT_NOT_ZERO_STATE;
        _dddCount = 0;
    } else {
        ErrorState(@"Bad symbol under slash");
    }
}

- (void)inOctalDDDWaitNotZeroState
{
    if ('1' <= _ch && _ch <= '7') {
        ++_dddCount;
        _state = IN_OCTAL_DDD_STATE;
    } else if (_ch != '0') {
        _dddCount = 0;
        _state = IN_STRING_STATE;
    }
}

- (void)inOctalDDDState
{
    if (isDigitOctSymbol(_ch)) {
        if (_dddCount < 3) {
            ++_dddCount;
        } else {
            _state = IN_STRING_STATE;
            _dddCount = 0;
        }
    } else if (_ch == ')'){
        _state = IN_STRING_CLOSE_STATE;
        _dddCount = 0;
    } else {
        _state = IN_STRING_STATE;
        _dddCount = 0;
    }
}

- (void)inNameState
{
    if (isBlankSymbol(_ch) || _ch == '[' || _ch == '(' || _ch == '<' || _ch == '%' || _ch == '/' || _ch == 0 || _ch == '>' || _ch == ']') {
        EndState(PDF_NAME_LEXEME_TYPE);
    }
}

- (void)inCommentState
{
    if (_ch == '\r' || _ch == '\n' || _ch == 0) {
        EndState(PDF_COMMENT_LEXEME_TYPE);
    }
}

- (void)inNumberAfterMinusState
{
    if (_ch == '.') {
        _state = IN_NUMBER_AFTER_ONLY_POINT_STATE;
    } else if (isDigitSymbol(_ch) == 0 || _ch == 0) {
        ErrorState(@"Number must contain digit after minus");
    } else {
        _state = IN_INTEGRAL_NUMBER_PART_STATE;
    }
}

- (void)inNumberAfterPlusState
{
    if (_ch == '.') {
        _state = IN_NUMBER_AFTER_ONLY_POINT_STATE;
    } else if (isDigitSymbol(_ch) == 0 || _ch == 0) {
        ErrorState(@"Number must contain digit after plus");
    } else {
        _state = IN_UINTEGRAL_NUMBER_PART_STATE;
    }
}

- (void)inIntegralNumberPartState
{
    if (_ch == '.') {
        _state = IN_REAL_NUMBER_STATE;
    } else if (isDigitSymbol(_ch) == 0 || _ch == 0) {
        EndState(PDF_INT_NUMBER_TYPE);
    }
}

- (void)inUIntegralNumberPartState
{
    if (_ch == '.') {
        _state = IN_REAL_NUMBER_STATE;
    } else if (isDigitSymbol(_ch) == 0 || _ch == 0) {
        EndState(PDF_UINT_NUMBER_TYPE);
    }
}

- (void)inNumberAfterOnlyPointState
{
    if (isDigitSymbol(_ch) == 0 || _ch ==0) {
        ErrorState(@"Number must contain digit befor or after point");
    } else {
        _state = IN_REAL_NUMBER_STATE;
    }
}

- (void)inRealNumberState
{
    if (isDigitSymbol(_ch) == 0 || _ch == 0) {
        EndState(PDF_NUMBER_LEXEME_TYPE);
    }
}

- (void)inLexemeState
{
    if (isBlankSymbol(_ch) || _ch == '[' || _ch == '(' || _ch == '<' || _ch == '%' || _ch == '/' || _ch == ']' || _ch == '>' || _ch == 0) {
        _state = END_LEXEME_STATE;
        if (_outState->current - _outState->lexeme == 3 && strncmp(_outState->lexeme, "obj", 3) == 0) {
            _outState->current_type = PDF_OBJ_KEYWORD_LEXEME_TYPE;
        } else if (_outState->current - _outState->lexeme == 6 && strncmp(_outState->lexeme, "endobj", 6) == 0) {
            _outState->current_type = PDF_ENDOBJ_KEYWORD_LEXEME_TYPE;
        } else if (_outState->current - _outState->lexeme == 4 && strncmp(_outState->lexeme, "xref", 4) == 0) {
            _outState->current_type = PDF_XREF_KEYWORD_LEXEME_TYPE;
        } else if (_outState->current - _outState->lexeme == 9 && strncmp(_outState->lexeme, "startxref", 9) == 0) {
            _outState->current_type = PDF_STARTXREF_KEYWORD_LEXEME_TYPE;
        } else if (_outState->current - _outState->lexeme == 6 && strncmp(_outState->lexeme, "stream", 6) == 0) {
            _outState->current_type = PDF_STREAM_KEYWORD_LEXEME_TYPE;
        } else if (_outState->current - _outState->lexeme == 9 && strncmp(_outState->lexeme, "endstream", 9) == 0) {
            _outState->current_type = PDF_ENDSTREAM_KEYWORD_LEXEME_TYPE;
        } else if (_outState->current - _outState->lexeme == 4 && strncmp(_outState->lexeme, "true", 4) == 0) {
            _outState->current_type = PDF_TRUE_KEYWORD_LEXEME_TYPE;
        } else if (_outState->current - _outState->lexeme == 5 && strncmp(_outState->lexeme, "false", 5) == 0) {
            _outState->current_type = PDF_FALSE_KEYWORD_LEXEME_TYPE;
        } else if (_outState->current - _outState->lexeme == 7 && strncmp(_outState->lexeme, "trailer", 7) == 0) {
            _outState->current_type = PDF_TRAILER_KEYWORD_LEXEME_TYPE;
        } else if (_outState->current - _outState->lexeme == 1 && strncmp(_outState->lexeme, "R", 1) == 0) {
            _outState->current_type = PDF_R_KEYWORD_LEXEME;
        } else if (_outState->current - _outState->lexeme == 4 && strncmp(_outState->lexeme, "null", 4) == 0) {
            _outState->current_type = PDF_NULL_KEYWORD_LEXEME;
        }
    }
}

- (void)inArrayOpenBracketState
{
    EndState(PDF_OPEN_ARRAY_LEXEME_TYPE);
}

- (void)inArrayCloseBracketState
{
    EndState(PDF_CLOSE_ARRAY_LEXEME_TYPE);
}

- (void)inDictionaryOpenBracketState
{
    EndState(PDF_OPEN_DICTIONARY_LEXEME_TYPE);
}

- (void)inDictionaryCloseBracketState
{
    EndState(PDF_CLOSE_DICTIONARY_LEXEME_TYPE);
}

- (void)inHexStringCloseState
{
    EndState(PDF_HEX_STRING_LEXEME_TYPE);
}

- (void)inStringCloseState
{
    EndState(PDF_STRING_LEXEME_TYPE);
}

- (void)checkState:(struct pdf_lexical_analyzer_state *)outState
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
}

- (void)initIterationState:(struct pdf_lexical_analyzer_state *)outState
{
    // Default values
    _outState = outState;
    _outState->current_type = PDF_UNKNOWN_LEXEME;
    _outState->len = 0;
    _state = BEGIN_LEXEME_STATE;
    _bracketsCounter = 0;
    _dddCount = 0;
}

- (const char*)nextLexemeByState:(struct pdf_lexical_analyzer_state*)outState
{
    [self checkState:outState];
    [self initIterationState:outState];
    // Find lexeme
    while (_state != ERROR_LEXEME_STATE && _state != END_LEXEME_STATE && _outState->current != _outState->end) {
        // Get current symbol
        _ch = *_outState->current;
        [self performSelector:(SEL)[[_statesTable objectAtIndex:_state] pointerValue]];
        
        if (_state != END_LEXEME_STATE) {
            ++_outState->current;
        }
    }
    if (_state == END_LEXEME_STATE) {
        _outState->len = _outState->current - _outState->lexeme;
        return _outState->lexeme;
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