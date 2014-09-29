//
//  PDFSyntaxAnalyzer.m
//  Parser
//
//  Created by demo on 17.05.14.
//  Copyright (c) 2014 Ptenster. All rights reserved.
//

#import "PDFSyntaxAnalyzer.h"

#import "PDFLexicalAnalyzer.h"
#import "PDFObject.h"
#import "PDFTrue.h"
#import "PDFFalse.h"
#import "PDFRef.h"
#import "PDFStack.h"
#import "PDFXRefTable.h"
#import "PDFXRefSubSection.h"

#define ErrorState(message) {\
    _state = ERROR_STATE;\
    _errorMessage = message;\
}

#define AddToTable(i, method) _statesTable[i] = [NSValue valueWithPointer:@selector(method)]

const char* strncch(const char* str, size_t len, char ch)
{
    for (int i = 0; i < len; ++i) {
        if (str[i] == ch) {
            return str+i;
        }
    }
    return NULL;
}

int isUINTLexeme(const char* lexeme, size_t len)
{
    return len && lexeme[0] != '-' && strncch(lexeme, len, '.') == NULL;
}

enum PDFSyntaxAnalyzerStates
{
    ERROR_STATE = -1,
    BEGIN_STATE = 0,
    OBJ_OBJECT_NUMBER_STATE,
    OBJ_GENERATED_NUMBER_STATE,
    OBJ_KEYWORD_STATE,
    IN_OBJECT_AFTER_NUMBER_STATE,
    IN_OBJECT_AFTER_NUMBER_NEED_R_STATE,
    IN_OBJECT_AFTER_VALUE_STATE,
    IN_OBJECT_IN_DICTIONARY_WAIT_KEY_STATE,
    IN_OBJECT_IN_DICTIONARY_WAIT_VALUE_STATE,
    IN_OBJECT_IN_DICTIONARY_AFTER_UINT_STATE,
    IN_OBJECT_IN_DICTIONARY_NEED_R_STATE,
    IN_OBJECT_IN_ARRAY_STATE,
    IN_OBJECT_AFTER_STREAM_STATE,
    IN_OBJECT_AFTER_ENDSTREAM_STATE,
    IN_XREF_NEED_FIRST_OBJECT_NUMBER_STATE,
    IN_XREF_AFTER_FIRST_OBJECT_NUMBER_STATE,
    IN_TRAILER_STATE,
    IN_TRAILER_IN_DICTIONARY_WAIT_KEY_STATE,
    IN_TRAILER_IN_DICTIONARY_WAIT_VALUE_STATE,
    IN_TRAILER_IN_DICTIONARY_AFTER_UINT_STATE,
    IN_TRAILER_IN_DICTIONARY_NEED_R_STATE,
    IN_TRAILER_IN_ARRAY_STATE,
    IN_TRAILER_AFTER_DICTIONARY_STATE,
    AFTER_STARTXREF_STATE,
    AFTER_TRAILER_OFFSET_STATE,
    END_STATE,
    COUNT_OF_STATES,
};

@interface PDFSyntaxAnalyzer()
{
    PDFLexicalAnalyzer*                 _lexicalAnalyzer;
    NSString*                           _errorMessage;
    struct pdf_lexical_analyzer_state   _pdf_state;
    PDFObject*                          _pdfObj;
    PDFValue *                          _pdfValue;
    NSUInteger                          _objectNumber;
    NSUInteger                          _generatedNumber;
    NSUInteger                          _refObjectNumber;
    NSUInteger                          _refGeneratedNumber;
    NSMutableArray*                     _array;
    NSMutableDictionary*                _dictionary;
    PDFStack*                           _stack;
    NSString*                           _key;
    NSData*                             _stream;
    NSUInteger                          _xrefFirstObjectNumber;
    NSUInteger                          _xrefLastObjectNumber;
    NSMutableArray*                     _subTables;
    PDFXRefSubSection*                  _xrefSection;
    PDFXRefTable*                       _xrefTable;
    NSUInteger                          _trailerOffset;
    enum PDFSyntaxAnalyzerStates        _state;
    const char*                         _lexeme;
    enum PDFLexemeTypes                 _type;
    NSUInteger                          _len;
    NSMutableArray*                     _statesTable;
}

@property (retain) NSString *errorMessage;

@end

@implementation PDFSyntaxAnalyzer

@synthesize errorMessage = _errorMessage;

- (id)initWithData:(NSData *)data
{
    self = [super init];
    if (self) {
        _lexicalAnalyzer    = [[PDFLexicalAnalyzer alloc] init];
        _pdf_state.current  = (char*)data.bytes;
        _pdf_state.end      = (char*)(data.length + data.length);
        _statesTable = [[NSMutableArray alloc] initWithCapacity:COUNT_OF_STATES];
        for (int i = BEGIN_STATE; i < COUNT_OF_STATES; ++i) {
            [_statesTable addObject:@(0)];
        }
        AddToTable(BEGIN_STATE, beginState);
        AddToTable(OBJ_OBJECT_NUMBER_STATE, objObjectNumberState);
        AddToTable(OBJ_GENERATED_NUMBER_STATE, objGeneratedNumberState);
        AddToTable(OBJ_KEYWORD_STATE, objKeywordState);
        AddToTable(IN_OBJECT_AFTER_NUMBER_STATE, inObjectAfterNumberState);
        AddToTable(IN_OBJECT_AFTER_NUMBER_NEED_R_STATE, inObjectAfterNumberNeedRState);
        AddToTable(IN_OBJECT_AFTER_VALUE_STATE, inObjectAfterValueState);
        AddToTable(IN_OBJECT_IN_DICTIONARY_WAIT_KEY_STATE, inObjectInDictionaryWaitKeyState);
        AddToTable(IN_OBJECT_IN_DICTIONARY_WAIT_VALUE_STATE, inObjectInDictionaryWaitValueState);
        AddToTable(IN_OBJECT_IN_DICTIONARY_AFTER_UINT_STATE, inObjectInDictionaryAfterUINTState);
        AddToTable(IN_OBJECT_IN_DICTIONARY_NEED_R_STATE, inObjectInDictionaryNeedRState);
        AddToTable(IN_OBJECT_IN_ARRAY_STATE, inObjectInArrayState);
        AddToTable(IN_OBJECT_AFTER_STREAM_STATE, inObjectAfterStreamState);
        AddToTable(IN_OBJECT_AFTER_ENDSTREAM_STATE, inObjectAfterEndstreamState);
        AddToTable(IN_XREF_NEED_FIRST_OBJECT_NUMBER_STATE, inXRefNeedFirstObjectNumberState);
        AddToTable(IN_XREF_AFTER_FIRST_OBJECT_NUMBER_STATE,inXRefAfterFirstObjectNumberState);
        AddToTable(IN_TRAILER_STATE, inTrailerState);
        AddToTable(IN_TRAILER_IN_DICTIONARY_WAIT_KEY_STATE, inTrailerInDictionaryWaitKeyState);
        AddToTable(IN_TRAILER_IN_DICTIONARY_WAIT_VALUE_STATE, inTrailerInDictionaryWaitValueState);
        AddToTable(IN_TRAILER_IN_DICTIONARY_AFTER_UINT_STATE, inTrailerInDictionaryAfterUINTState);
        AddToTable(IN_TRAILER_IN_DICTIONARY_NEED_R_STATE, inTrailerInDictionaryNeedRState);
        AddToTable(IN_TRAILER_IN_ARRAY_STATE, inTrailerInArrayState);
        AddToTable(IN_TRAILER_AFTER_DICTIONARY_STATE, inTrailerAfterDictionaryState);
        AddToTable(AFTER_STARTXREF_STATE, afterStartXRefState);
        AddToTable(AFTER_TRAILER_OFFSET_STATE, afterTrailerOffsetState);
    }
    return self;
}

- (void)dealloc
{
    [_lexicalAnalyzer release];
    [_statesTable release];
    [super dealloc];
}

- (void)beginState
{
    switch (_type) {
        case PDF_COMMENT_LEXEME_TYPE:
            _pdfObj = [PDFObject pdfComment:[self stringFromLexeme:_lexeme len:_len]];
            _state = END_STATE;
            break;
        case PDF_XREF_KEYWORD_LEXEME_TYPE:
            _state = IN_XREF_NEED_FIRST_OBJECT_NUMBER_STATE;
            break;
        case PDF_UINT_NUMBER_TYPE:
            _state = OBJ_OBJECT_NUMBER_STATE;
            _objectNumber = [self unsignedIntegerFromUINTLexeme:_lexeme len:_len];
            break;
        default:
            ErrorState(@"Bad type in BEGIN_STATE");
            break;
    }
}

- (void)inXRefNeedFirstObjectNumberState
{
    switch (_type) {
        case PDF_UINT_NUMBER_TYPE:
            _state = IN_XREF_AFTER_FIRST_OBJECT_NUMBER_STATE;
            _xrefFirstObjectNumber = [self unsignedIntegerFromUINTLexeme:_lexeme len:_len];
            break;
        case PDF_TRAILER_KEYWORD_LEXEME_TYPE:
            _state = IN_TRAILER_STATE;
            _xrefTable = [PDFXRefTable pdfXRefTableWithSubSections:_subTables];
            break;
        default:
            ErrorState(@"Failed to parse xref subsection");
            break;
    }
}

- (void)objObjectNumberState
{
    switch (_type) {
        case PDF_UINT_NUMBER_TYPE:
            _state = OBJ_GENERATED_NUMBER_STATE;
            _generatedNumber = [self unsignedIntegerFromUINTLexeme:_lexeme len:_len];
            break;
        default:
            ErrorState(@"Bad state in FIRST_OBJECT_NUMBER_STATE");
            break;
    }
}

- (void)objGeneratedNumberState
{
    switch (_type) {
        case PDF_OBJ_KEYWORD_LEXEME_TYPE:
            _state = OBJ_KEYWORD_STATE;
            break;
        default:
            ErrorState(@"Bad type after generated number");
            break;
    }
}

- (void)objKeywordState
{
    switch (_type) {
        case PDF_UINT_NUMBER_TYPE:
            _state = IN_OBJECT_AFTER_NUMBER_STATE;
            _refObjectNumber = [self unsignedIntegerFromUINTLexeme:_lexeme len:_len];
            break;
        case PDF_NUMBER_LEXEME_TYPE:
            _state = IN_OBJECT_AFTER_VALUE_STATE;
            _pdfValue = [self numberValueFromLexeme:_lexeme len:_len];
            break;
        case PDF_STRING_LEXEME_TYPE:
            _state = IN_OBJECT_AFTER_VALUE_STATE;
            _pdfValue = [self stringValueFromLexeme:_lexeme len:_len];
            break;
        case PDF_HEX_STRING_LEXEME_TYPE:
            _state = IN_OBJECT_AFTER_VALUE_STATE;
            _pdfValue = [self hexStringValueFromLexeme:_lexeme len:_len];
            break;
        case PDF_NAME_LEXEME_TYPE:
            _state = IN_OBJECT_AFTER_VALUE_STATE;
            _pdfValue = [self nameValueFromLexeme:_lexeme len:_len];
            break;
        case PDF_TRUE_KEYWORD_LEXEME_TYPE:
            _state = IN_OBJECT_AFTER_VALUE_STATE;
            _pdfValue = [PDFValue trueValue];
            break;
        case PDF_FALSE_KEYWORD_LEXEME_TYPE:
            _state = IN_OBJECT_AFTER_VALUE_STATE;
            _pdfValue = [PDFValue falseValue];
            break;
        case PDF_ENDOBJ_KEYWORD_LEXEME_TYPE:
            _state = END_STATE;
            _pdfObj = [PDFObject pdfObjectWithValue:nil objectNumber:_objectNumber generatedNumber:_generatedNumber];
            break;
        case PDF_OPEN_ARRAY_LEXEME_TYPE:
            _array = [NSMutableArray array];
            _pdfValue = [PDFValue arrayValue:_array];
            _state = IN_OBJECT_IN_ARRAY_STATE;
            break;
        case PDF_OPEN_DICTIONARY_LEXEME_TYPE:
            _dictionary = [NSMutableDictionary dictionary];
            _pdfValue = [PDFValue dictionaryValue:_dictionary];
            _state = IN_OBJECT_IN_DICTIONARY_WAIT_KEY_STATE;
            break;
        case PDF_NULL_KEYWORD_LEXEME:
            _pdfValue = [PDFValue nullValue];
            _state = IN_OBJECT_AFTER_VALUE_STATE;
            break;
        default:
            ErrorState(@"Bad state in OBJ_KEYWORD_STATE");
            break;
    }
}

- (void)inObjectAfterNumberState
{
    switch (_type) {
        case PDF_UINT_NUMBER_TYPE:
            _refGeneratedNumber = [self unsignedIntegerFromUINTLexeme:_lexeme len:_len];
            _state = IN_OBJECT_AFTER_NUMBER_NEED_R_STATE;
            break;
        case PDF_ENDOBJ_KEYWORD_LEXEME_TYPE:
            _state = END_STATE;
            _pdfValue = [PDFValue numberValue:@(_refObjectNumber)];
            _pdfObj = [PDFObject pdfObjectWithValue:_pdfValue objectNumber:_objectNumber generatedNumber:_generatedNumber];
            break;
        default:
            ErrorState(@"Bad state in IN_OBJECT_AFTER_NUMBER_STATE");
            break;
    }
}

- (void)inObjectAfterNumberNeedRState
{
    switch (_type) {
        case PDF_R_KEYWORD_LEXEME:
            _pdfValue = [PDFValue pdfRefValueWithObjectNumber:_refObjectNumber generatedNumber:_refGeneratedNumber];
            _state = IN_OBJECT_AFTER_VALUE_STATE;
            break;
        default:
            break;
    }
}

- (void)inObjectAfterValueState
{
    switch (_type) {
        case PDF_STREAM_KEYWORD_LEXEME_TYPE:
            if (_pdfValue.type != PDF_DICTIONARY_VALUE_TYPE) {
                ErrorState(@"For stream need dictionary");
            } else {
                NSDictionary *dict = (NSDictionary*)_pdfValue.value;
                PDFValue *pdfLength = dict[@"/Length"];
                if (pdfLength == nil) {
                    ErrorState(@"For stream need length");
                } else if (pdfLength.type != PDF_NUMBER_VALUE_TYPE) {
                    ErrorState(@"For stream length must me unsigned integer number");
                } else {
                    NSNumber *numberLength = (NSNumber*)pdfLength.value;
                    if ([numberLength isLessThan:@0]) {
                        ErrorState(@"For stream length must me unsigned integer number");
                    } else {
                        [_lexicalAnalyzer skipBytesByCount:1 state:&_pdf_state];
                        _stream = [_lexicalAnalyzer getAndSkipBytesByCount:numberLength.unsignedIntegerValue state:&_pdf_state];
                        _state = IN_OBJECT_AFTER_STREAM_STATE;
                    }
                }
            }
            break;
        case PDF_ENDOBJ_KEYWORD_LEXEME_TYPE:
            _state = END_STATE;
            _pdfObj = [PDFObject pdfObjectWithValue:_pdfValue objectNumber:_objectNumber generatedNumber:_generatedNumber];
            break;
        default:
            ErrorState(@"Bad type in IN_OBJECT_AFTER_VALUE_STATE");
            break;
    }
}

- (void)inObjectInArrayState
{
    switch (_type) {
        case PDF_UINT_NUMBER_TYPE:
        case PDF_INT_NUMBER_TYPE:
        case PDF_NUMBER_LEXEME_TYPE:
            [_array addObject:[self numberValueFromLexeme:_lexeme len:_len]];
            break;
        case PDF_STRING_LEXEME_TYPE:
            [_array addObject:[self stringValueFromLexeme:_lexeme len:_len]];
            break;
        case PDF_HEX_STRING_LEXEME_TYPE:
            [_array addObject:[self hexStringValueFromLexeme:_lexeme len:_len]];
            break;
        case PDF_NAME_LEXEME_TYPE:
            [_array addObject:[self nameValueFromLexeme:_lexeme len:_len]];
            break;
        case PDF_TRUE_KEYWORD_LEXEME_TYPE:
            [_array addObject:[PDFValue trueValue]];
            break;
        case PDF_FALSE_KEYWORD_LEXEME_TYPE:
            [_array addObject:[PDFValue falseValue]];
            break;
        case PDF_OPEN_ARRAY_LEXEME_TYPE:
            _state = IN_OBJECT_IN_ARRAY_STATE;
            [_stack pushObject:@{@"value" : _pdfValue, @"type" : @0}];
            _array = [NSMutableArray array];
            _pdfValue = [PDFValue arrayValue:_array];
            break;
        case PDF_OPEN_DICTIONARY_LEXEME_TYPE:
            _state = IN_OBJECT_IN_DICTIONARY_WAIT_KEY_STATE;
            [_stack pushObject:@{@"value": _pdfValue, @"type" : @0}];
            _dictionary = [NSMutableDictionary dictionary];
            _pdfValue = [PDFValue dictionaryValue:_dictionary];
            break;
        case PDF_NULL_KEYWORD_LEXEME:
            [_array addObject:[PDFValue nullValue]];
            break;
        case PDF_CLOSE_ARRAY_LEXEME_TYPE:
            if (_stack.count == 0) {
                _state = IN_OBJECT_AFTER_VALUE_STATE;
            } else {
                PDFValue *tmp = _pdfValue;
                _pdfValue = [_stack top][@"value"];
                switch ([[_stack top][@"type"] intValue]) {
                    case 0:
                        _array = (NSMutableArray*)_pdfValue.value;
                        [_array addObject:tmp];
                        _state = IN_OBJECT_IN_ARRAY_STATE;
                        break;
                    case 1:
                    default:
                        _dictionary = (NSMutableDictionary*)_pdfValue.value;
                        _dictionary[[_stack top][@"key"]] = tmp;
                        _state = IN_OBJECT_IN_DICTIONARY_WAIT_KEY_STATE;
                        break;
                }
                [_stack pop];
            }
            break;
        default:
            break;
    }
}

- (void)inObjectInDictionaryWaitKeyState
{
    switch (_type) {
        case PDF_NAME_LEXEME_TYPE:
            _state = IN_OBJECT_IN_DICTIONARY_WAIT_VALUE_STATE;
            _key = [self stringFromLexeme:_lexeme len:_len];
            break;
        case PDF_CLOSE_DICTIONARY_LEXEME_TYPE:
            if (_stack.count == 0) {
                _state = IN_OBJECT_AFTER_VALUE_STATE;
            } else {
                PDFValue *tmp = _pdfValue;
                _pdfValue = [_stack top][@"value"];
                switch ([[_stack top][@"type"] intValue]) {
                    case 0:
                        _array = (NSMutableArray*)_pdfValue.value;
                        [_array addObject:tmp];
                        _state = IN_OBJECT_IN_ARRAY_STATE;
                        break;
                    case 1:
                    default:
                        _state = IN_OBJECT_IN_DICTIONARY_WAIT_KEY_STATE;
                        _dictionary = (NSMutableDictionary*)_pdfValue.value;
                        _dictionary[[_stack top][@"key"]] = tmp;
                        break;
                }
                [_stack pop];
            }
            break;
        default:
            ErrorState(@"Only name type can be dictionary keys");
            break;
    }
}

- (void)inObjectInDictionaryWaitValueState
{
    switch (_type) {
        case PDF_UINT_NUMBER_TYPE:
            _state = IN_OBJECT_IN_DICTIONARY_AFTER_UINT_STATE;
            _refObjectNumber = [self unsignedIntegerFromUINTLexeme:_lexeme len:_len];
            break;
        case PDF_INT_NUMBER_TYPE:
        case PDF_NUMBER_LEXEME_TYPE:
            _dictionary[_key] = [self numberValueFromLexeme:_lexeme len:_len];
            _state = IN_OBJECT_IN_DICTIONARY_WAIT_KEY_STATE;
            break;
        case PDF_NAME_LEXEME_TYPE:
            _dictionary[_key] = [self nameValueFromLexeme:_lexeme len:_len];
            _state = IN_OBJECT_IN_DICTIONARY_WAIT_KEY_STATE;
            break;
        case PDF_STRING_LEXEME_TYPE:
            _dictionary[_key] = [self stringValueFromLexeme:_lexeme len:_len];
            _state = IN_OBJECT_IN_DICTIONARY_WAIT_KEY_STATE;
            break;
        case PDF_HEX_STRING_LEXEME_TYPE:
            _dictionary[_key] = [self hexStringValueFromLexeme:_lexeme len:_len];
            _state = IN_OBJECT_IN_DICTIONARY_WAIT_KEY_STATE;
            break;
        case PDF_TRUE_KEYWORD_LEXEME_TYPE:
            _dictionary[_key] = [PDFValue trueValue];
            _state = IN_OBJECT_IN_DICTIONARY_WAIT_KEY_STATE;
            break;
        case PDF_FALSE_KEYWORD_LEXEME_TYPE:
            _dictionary[_key] = [PDFValue falseValue];
            _state = IN_OBJECT_IN_DICTIONARY_WAIT_KEY_STATE;
            break;
        case PDF_NULL_KEYWORD_LEXEME:
            _dictionary[_key] = [PDFValue nullValue];
            _state = IN_OBJECT_IN_DICTIONARY_WAIT_KEY_STATE;
            break;
        case PDF_OPEN_ARRAY_LEXEME_TYPE:
            [_stack pushObject:@{@"key": _key, @"value" : _pdfValue, @"type" : @1}];
            _state = IN_OBJECT_IN_ARRAY_STATE;
            _array = [NSMutableArray array];
            _pdfValue = [PDFValue arrayValue:_array];
            break;
        case PDF_OPEN_DICTIONARY_LEXEME_TYPE:
            [_stack pushObject:@{@"key" : _key, @"value" : _pdfValue, @"type" : @1}];
            _state = IN_OBJECT_IN_DICTIONARY_WAIT_KEY_STATE;
            _dictionary = [NSMutableDictionary dictionary];
            _pdfValue = [PDFValue dictionaryValue:_dictionary];
            break;
        default:
            break;
    }
}

- (void)inObjectInDictionaryAfterUINTState
{
    switch (_type) {
        case PDF_UINT_NUMBER_TYPE:
            _state = IN_OBJECT_IN_DICTIONARY_NEED_R_STATE;
            _refGeneratedNumber = [self unsignedIntegerFromUINTLexeme:_lexeme len:_len];
            break;
        case PDF_NAME_LEXEME_TYPE:
            _dictionary[_key] = [PDFValue numberValue:@(_refObjectNumber)];
            _key = [self stringFromLexeme:_lexeme len:_len];
            _state = IN_OBJECT_IN_DICTIONARY_WAIT_VALUE_STATE;
            break;
        case PDF_CLOSE_DICTIONARY_LEXEME_TYPE:
            _dictionary[_key] = [PDFValue numberValue:@(_refObjectNumber)];
            if (_stack.count == 0) {
                _state = IN_OBJECT_AFTER_VALUE_STATE;
            } else {
                PDFValue *tmp = _pdfValue;
                _pdfValue = [_stack top][@"value"];
                switch ([[_stack top][@"type"] intValue]) {
                    case 0:
                        _array = (NSMutableArray*)_pdfValue.value;
                        [_array addObject:tmp];
                        _state = IN_OBJECT_IN_ARRAY_STATE;
                        break;
                    case 1:
                    default:
                        _state = IN_OBJECT_IN_DICTIONARY_WAIT_KEY_STATE;
                        _dictionary = (NSMutableDictionary*)_pdfValue.value;
                        _dictionary[[_stack top][@"key"]] = tmp;
                        break;
                }
                [_stack pop];
            }
            break;
        default:
            ErrorState(@"Syntaxis error in dictoinary value");
            break;
    }
}

- (void)inObjectInDictionaryNeedRState
{
    switch (_type) {
        case PDF_R_KEYWORD_LEXEME:
            _dictionary[_key] = [PDFValue pdfRefValueWithObjectNumber:_refObjectNumber generatedNumber:_refGeneratedNumber];
            _state = IN_OBJECT_IN_DICTIONARY_WAIT_KEY_STATE;
            break;
        default:
            ErrorState(@"Syntaxis error in dictionary value");
            break;
    }
}

- (void)inObjectAfterStreamState
{
    switch (_type) {
        case PDF_ENDSTREAM_KEYWORD_LEXEME_TYPE:
            _state = IN_OBJECT_AFTER_ENDSTREAM_STATE;
            break;
        default:
            ErrorState(@"After stream must be endstream");
            break;
    }
}

- (void)inObjectAfterEndstreamState
{
    switch (_type) {
        case PDF_ENDOBJ_KEYWORD_LEXEME_TYPE:
            _pdfObj = [PDFObject pdfObjectWithValue:_pdfValue stream:_stream objectNumber:_objectNumber generatedNumber:_generatedNumber];
            _state = END_STATE;
            break;
        default:
            ErrorState(@"After endstream must be endobj");
            break;
    }
}

- (void)inXRefAfterFirstObjectNumberState
{
    switch (_type) {
        case PDF_UINT_NUMBER_TYPE:
            _xrefLastObjectNumber = [self unsignedIntegerFromUINTLexeme:_lexeme len:_len];
            _state = IN_XREF_NEED_FIRST_OBJECT_NUMBER_STATE;
            [_lexicalAnalyzer skipBytesByCount:2 state:&_pdf_state];
            _xrefSection = [PDFXRefSubSection pdfXRefSectionWithFirstObjectNumber:_xrefFirstObjectNumber
                                                                 lastObjectNumber:_xrefLastObjectNumber
                                                                             data:[_lexicalAnalyzer getAndSkipBytesByCount:19 * _xrefLastObjectNumber
                                                                                                                     state:&_pdf_state]];
            [_subTables addObject:_xrefSection];
            break;
        default:
            ErrorState(@"After xref must be unsigned integer value");
            break;
    }
}

- (void)inTrailerState
{
    switch (_type) {
        case PDF_OPEN_DICTIONARY_LEXEME_TYPE:
            _state = IN_TRAILER_IN_DICTIONARY_WAIT_KEY_STATE;
            _dictionary = [NSMutableDictionary dictionary];
            _pdfValue = [PDFValue dictionaryValue:_dictionary];
            break;
        default:
            ErrorState(@"In trailer always must be non empty dictionary");
            break;
    }
}

- (void)inTrailerInDictionaryWaitKeyState
{
    switch (_type) {
        case PDF_NAME_LEXEME_TYPE:
            _key = [self stringFromLexeme:_lexeme len:_len];
            _state = IN_TRAILER_IN_DICTIONARY_WAIT_VALUE_STATE;
            break;
        case PDF_CLOSE_DICTIONARY_LEXEME_TYPE:
            if (_stack.count == 0) {
                _state = IN_TRAILER_AFTER_DICTIONARY_STATE;
            } else {
                PDFValue *tmp = _pdfValue;
                _pdfValue = [_stack top][@"value"];
                switch ([[_stack top][@"type"] intValue]) {
                    case 0:
                        _array = (NSMutableArray*)_pdfValue.value;
                        [_array addObject:tmp];
                        _state = IN_TRAILER_IN_ARRAY_STATE;
                        break;
                    case 1:
                    default:
                        _state = IN_TRAILER_IN_DICTIONARY_WAIT_KEY_STATE;
                        _dictionary = (NSMutableDictionary*)_pdfValue.value;
                        _dictionary[[_stack top][@"key"]] = tmp;
                        break;
                }
                [_stack pop];
            }
            break;
        default:
            break;
    }
}

- (void)inTrailerInDictionaryWaitValueState
{
    switch (_type) {
        case PDF_UINT_NUMBER_TYPE:
            _refObjectNumber = [self unsignedIntegerFromUINTLexeme:_lexeme len:_len];
            _state = IN_TRAILER_IN_DICTIONARY_AFTER_UINT_STATE;
            break;
        case PDF_INT_NUMBER_TYPE:
        case PDF_NUMBER_LEXEME_TYPE:
            _dictionary[_key] = [self numberValueFromLexeme:_lexeme len:_len];
            _state = IN_TRAILER_IN_DICTIONARY_WAIT_KEY_STATE;
            break;
        case PDF_NAME_LEXEME_TYPE:
            _dictionary[_key] = [self nameValueFromLexeme:_lexeme len:_len];
            _state = IN_TRAILER_IN_DICTIONARY_WAIT_KEY_STATE;
            break;
        case PDF_STRING_LEXEME_TYPE:
            _dictionary[_key] = [self stringValueFromLexeme:_lexeme len:_len];
            _state = IN_TRAILER_IN_DICTIONARY_WAIT_KEY_STATE;
            break;
        case PDF_HEX_STRING_LEXEME_TYPE:
            _dictionary[_key] = [self hexStringValueFromLexeme:_lexeme len:_len];
            _state = IN_TRAILER_IN_DICTIONARY_WAIT_KEY_STATE;
            break;
        case PDF_TRUE_KEYWORD_LEXEME_TYPE:
            _dictionary[_key] = [PDFValue trueValue];
            _state = IN_TRAILER_IN_DICTIONARY_WAIT_KEY_STATE;
            break;
        case PDF_FALSE_KEYWORD_LEXEME_TYPE:
            _dictionary[_key] = [PDFValue falseValue];
            _state = IN_TRAILER_IN_DICTIONARY_WAIT_KEY_STATE;
            break;
        case PDF_NULL_KEYWORD_LEXEME:
            _dictionary[_key] = [PDFValue nullValue];
            _state = IN_TRAILER_IN_DICTIONARY_WAIT_KEY_STATE;
            break;
        case PDF_OPEN_ARRAY_LEXEME_TYPE:
            [_stack pushObject:@{@"key": _key, @"value" : _pdfValue, @"type" : @1}];
            _state = IN_TRAILER_IN_ARRAY_STATE;
            _array = [NSMutableArray array];
            _pdfValue = [PDFValue arrayValue:_array];
            break;
        case PDF_OPEN_DICTIONARY_LEXEME_TYPE:
            [_stack pushObject:@{@"key" : _key, @"value" : _pdfValue, @"type" : @1}];
            _state = IN_TRAILER_IN_DICTIONARY_WAIT_KEY_STATE;
            _dictionary = [NSMutableDictionary dictionary];
            _pdfValue = [PDFValue dictionaryValue:_dictionary];
            break;
        default:
            break;
    }
}

- (void)inTrailerInArrayState
{
    switch (_type) {
        case PDF_UINT_NUMBER_TYPE:
        case PDF_INT_NUMBER_TYPE:
        case PDF_NUMBER_LEXEME_TYPE:
            [_array addObject:[self numberValueFromLexeme:_lexeme len:_len]];
            break;
        case PDF_STRING_LEXEME_TYPE:
            [_array addObject:[self stringValueFromLexeme:_lexeme len:_len]];
            break;
        case PDF_HEX_STRING_LEXEME_TYPE:
            [_array addObject:[self hexStringValueFromLexeme:_lexeme len:_len]];
            break;
        case PDF_NAME_LEXEME_TYPE:
            [_array addObject:[self nameValueFromLexeme:_lexeme len:_len]];
            break;
        case PDF_TRUE_KEYWORD_LEXEME_TYPE:
            [_array addObject:[PDFValue trueValue]];
            break;
        case PDF_FALSE_KEYWORD_LEXEME_TYPE:
            [_array addObject:[PDFValue falseValue]];
            break;
        case PDF_OPEN_ARRAY_LEXEME_TYPE:
            _state = IN_OBJECT_IN_ARRAY_STATE;
            [_stack pushObject:@{@"value" : _pdfValue, @"type" : @0}];
            _array = [NSMutableArray array];
            _pdfValue = [PDFValue arrayValue:_array];
            break;
        case PDF_OPEN_DICTIONARY_LEXEME_TYPE:
            _state = IN_OBJECT_IN_DICTIONARY_WAIT_KEY_STATE;
            [_stack pushObject:@{@"value": _pdfValue, @"type" : @0}];
            _dictionary = [NSMutableDictionary dictionary];
            _pdfValue = [PDFValue dictionaryValue:_dictionary];
            break;
        case PDF_NULL_KEYWORD_LEXEME:
            [_array addObject:[PDFValue nullValue]];
            break;
        case PDF_CLOSE_ARRAY_LEXEME_TYPE:
            if (_stack.count == 0) {
                _state = IN_TRAILER_AFTER_DICTIONARY_STATE;
            } else {
                PDFValue *tmp = _pdfValue;
                _pdfValue = [_stack top][@"value"];
                switch ([[_stack top][@"type"] intValue]) {
                    case 0:
                        _array = (NSMutableArray*)_pdfValue.value;
                        [_array addObject:tmp];
                        _state = IN_TRAILER_IN_ARRAY_STATE;
                        break;
                    case 1:
                    default:
                        _dictionary = (NSMutableDictionary*)_pdfValue.value;
                        _dictionary[[_stack top][@"key"]] = tmp;
                        _state = IN_TRAILER_IN_DICTIONARY_WAIT_KEY_STATE;
                        break;
                }
                [_stack pop];
            }
            break;
        default:
            ErrorState(@"Failed to parse array in trailer");
            break;
    }
}

- (void)inTrailerInDictionaryAfterUINTState
{
    switch (_type) {
        case PDF_UINT_NUMBER_TYPE:
            _state = IN_TRAILER_IN_DICTIONARY_NEED_R_STATE;
            _refGeneratedNumber = [self unsignedIntegerFromUINTLexeme:_lexeme len:_len];
            break;
        case PDF_NAME_LEXEME_TYPE:
            _dictionary[_key] = [PDFValue numberValue:@(_refObjectNumber)];
            _key = [self stringFromLexeme:_lexeme len:_len];
            _state = IN_TRAILER_IN_DICTIONARY_WAIT_VALUE_STATE;
            break;
        case PDF_CLOSE_DICTIONARY_LEXEME_TYPE:
            _dictionary[_key] = [PDFValue numberValue:@(_refObjectNumber)];
            if (_stack.count == 0) {
                _state = IN_TRAILER_AFTER_DICTIONARY_STATE;
            } else {
                PDFValue *tmp = _pdfValue;
                _pdfValue = [_stack top][@"value"];
                switch ([[_stack top][@"type"] intValue]) {
                    case 0:
                        _array = (NSMutableArray*)_pdfValue.value;
                        [_array addObject:tmp];
                        _state = IN_TRAILER_IN_ARRAY_STATE;
                        break;
                    case 1:
                    default:
                        _state = IN_TRAILER_IN_DICTIONARY_WAIT_KEY_STATE;
                        _dictionary = (NSMutableDictionary*)_pdfValue.value;
                        _dictionary[[_stack top][@"key"]] = tmp;
                        break;
                }
                [_stack pop];
            }
            break;
        default:
            ErrorState(@"Syntaxis error in dictoinary value");
            break;
    }
}

- (void)inTrailerInDictionaryNeedRState
{
    switch (_type) {
        case PDF_R_KEYWORD_LEXEME:
            _dictionary[_key] = [PDFValue pdfRefValueWithObjectNumber:_refObjectNumber generatedNumber:_refGeneratedNumber];
            _state = IN_TRAILER_IN_DICTIONARY_WAIT_KEY_STATE;
            break;
        default:
            ErrorState(@"Failed to parse reference in dictionary in trailer");
            break;
    }
}

- (void)inTrailerAfterDictionaryState
{
    switch (_type) {
        case PDF_STARTXREF_KEYWORD_LEXEME_TYPE:
            _state = AFTER_STARTXREF_STATE;
            break;
        default:
            ErrorState(@"After trailer dictionary must be startxref keyword");
            break;
    }
}

- (void)afterStartXRefState
{
    switch (_type) {
        case PDF_UINT_NUMBER_TYPE:
            _trailerOffset = [self unsignedIntegerFromUINTLexeme:_lexeme len:_len];
            _state = AFTER_TRAILER_OFFSET_STATE;
            break;
        default:
            ErrorState(@"After startxref keyword must be unsigned integer number");
            break;
    }
}

- (void)afterTrailerOffsetState
{
    switch (_type) {
        case PDF_COMMENT_LEXEME_TYPE:
        {
            if (_len == 5 && strncmp(_lexeme, "%%EOF", _len) == 0) {
                _state = END_STATE;
                _pdfObj = [PDFObject pdfObjectWithXRefTable:_xrefTable trailer:_dictionary offset:_trailerOffset];
            } else {
                ErrorState(@"After trailer offset must be comment '%%EOF'");
            }
            break;
        }
        default:
            ErrorState(@"After trailer offset must be comment '%%EOF'");
            break;
    }
}

- (void)initIterationState
{
    _state                  = BEGIN_STATE;
    _pdfObj                 = nil;
    _pdfValue               = nil;
    _objectNumber           = 0;
    _generatedNumber        = 0;
    _refObjectNumber        = 0;
    _refGeneratedNumber     = 0;
    _array                  = nil;
    _dictionary             = nil;
    _stack                  = [PDFStack pdfStack];
    _key                    = nil;
    _stream                 = nil;
    _xrefFirstObjectNumber  = 0;
    _xrefLastObjectNumber   = 0;
    _subTables              = [NSMutableArray array];
    _xrefSection            = nil;
    _xrefTable              = nil;
    _trailerOffset          = 0;
}

- (NSObject*)nextSyntaxObject
{
    [self initIterationState];
    
    while (_state != END_STATE && _state != ERROR_STATE) {
        
        _lexeme = [_lexicalAnalyzer nextLexemeByState:&_pdf_state];
        _type   = _pdf_state.current_type;
        _len    = _pdf_state.len;
        
        [self performSelector:(SEL)[[_statesTable objectAtIndex:_state] pointerValue]];
    }
    
    return _pdfObj;
}

- (NSString*)stringFromLexeme:(const char*)lexeme len:(NSUInteger)len
{
    return [[[NSString alloc] initWithData:[NSData dataWithBytes:lexeme length:len] encoding:NSASCIIStringEncoding] autorelease];
}

- (NSUInteger)unsignedIntegerFromUINTLexeme:(const char*)lexeme len:(NSUInteger)len
{
    return (NSUInteger)[[self stringFromLexeme:lexeme len:len] integerValue];
}

- (NSNumber*)numberFromLexeme:(const char*)lexeme len:(NSUInteger)len
{
    NSString *s = [[NSString alloc] initWithData:[NSData dataWithBytes:lexeme length:len] encoding:NSASCIIStringEncoding];
    NSNumberFormatter *formater = [[NSNumberFormatter alloc] init];
    [formater setNumberStyle:NSNumberFormatterNoStyle];
    NSNumber *res = [formater numberFromString:s];
    [formater release];
    return res;
}

- (PDFValue*)numberValueFromLexeme:(const char*)lexeme len:(NSUInteger)len
{
    return [PDFValue numberValue:[self numberFromLexeme:lexeme len:len]];
}

- (PDFValue*)stringValueFromLexeme:(const char*)lexeme len:(NSUInteger)len
{
    return [PDFValue stringValue:[self stringFromLexeme:lexeme len:len]];
}

- (PDFValue*)hexStringValueFromLexeme:(const char*)lexeme len:(NSUInteger)len
{
    return [PDFValue hexStringValue:[self stringFromLexeme:lexeme len:len]];
}

- (PDFValue*)nameValueFromLexeme:(const char*)lexeme len:(NSUInteger)len
{
    return [PDFValue nameValue:[self stringFromLexeme:lexeme len:len]];
}

@end

#undef ErrorState
#undef AddToTable