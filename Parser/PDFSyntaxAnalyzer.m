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

#define ErrorState(message) {\
    state = ERROR_STATE;\
    _errorMessage = message;\
}

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
    XREF_STATE,
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
    
    END_STATE,
};

@interface PDFSyntaxAnalyzer()
{
    PDFLexicalAnalyzer *_lexicalAnalyzer;
    NSString *_errorMessage;
}

@property (retain) NSString *errorMessage;

@end

@implementation PDFSyntaxAnalyzer

@synthesize errorMessage = _errorMessage;

- (id)initWithData:(NSData *)data
{
    self = [super init];
    if (self) {
        _lexicalAnalyzer = [[PDFLexicalAnalyzer alloc] initWithData:data];
    }
    return self;
}

- (void)dealloc
{
    [_lexicalAnalyzer release];
    [super dealloc];
}

- (PDFObject*)nextSyntaxObjectIterWithState:(enum PDFSyntaxAnalyzerStates)state
{
    PDFObject *pdfObj = nil;
    PDFValue *pdfValue = nil;
    NSUInteger objectNumber = 0;
    NSUInteger generatedNumber = 0;
    NSUInteger refObjectNumber = 0;
    NSUInteger refGeneratedNumber = 0;
    NSMutableArray *array = nil;
    NSMutableDictionary *dictionary = nil;
    PDFStack* stack = [PDFStack pdfStack];
    NSString* key = nil;
    
    while (state != END_STATE && state != ERROR_STATE) {
        
        enum PDFLexemeTypes type = PDF_UNKNOWN_LEXEME;
        NSUInteger len = 0;
        const char* lexeme = [_lexicalAnalyzer nextLexeme:&len type:&type];
        
        switch (state) {
            case BEGIN_STATE:
                switch (type) {
                    case PDF_COMMENT_LEXEME_TYPE:
                        pdfObj = [PDFObject pdfComment:[self stringFromLexeme:lexeme len:len]];
                        state = END_STATE;
                        break;
                    case PDF_XREF_KEYWORD_LEXEME_TYPE:
                        state = XREF_STATE;
                        break;
                    case PDF_UINT_NUMBER_TYPE:
                        state = OBJ_OBJECT_NUMBER_STATE;
                        objectNumber = [self unsignedIntegerFromUINTLexeme:lexeme len:len];
                        break;
                    default:
                        ErrorState(@"Bad type in BEGIN_STATE");
                        break;
                }
                break;
            case XREF_STATE:
                NSAssert(NO, @"Xref!!!!! Sheep happened");
                break;
            case OBJ_OBJECT_NUMBER_STATE:
                switch (type) {
                    case PDF_UINT_NUMBER_TYPE:
                        state = OBJ_GENERATED_NUMBER_STATE;
                        generatedNumber = [self unsignedIntegerFromUINTLexeme:lexeme len:len];
                        break;
                    default:
                        ErrorState(@"Bad state in FIRST_OBJECT_NUMBER_STATE");
                        break;
                }
                break;
            case OBJ_GENERATED_NUMBER_STATE:
                switch (type) {
                    case PDF_OBJ_KEYWORD_LEXEME_TYPE:
                        state = OBJ_KEYWORD_STATE;
                        break;
                    default:
                        ErrorState(@"Bad type after generated number");
                        break;
                }
                break;
            case OBJ_KEYWORD_STATE:
                switch (type) {
                    case PDF_UINT_NUMBER_TYPE:
                        state = IN_OBJECT_AFTER_NUMBER_STATE;
                        refObjectNumber = [self unsignedIntegerFromUINTLexeme:lexeme len:len];
                        break;
                    case PDF_NUMBER_LEXEME_TYPE:
                        state = IN_OBJECT_AFTER_VALUE_STATE;
                        pdfValue = [self numberValueFromLexeme:lexeme len:len];
                        break;
                    case PDF_STRING_LEXEME_TYPE:
                        state = IN_OBJECT_AFTER_VALUE_STATE;
                        pdfValue = [self stringValueFromLexeme:lexeme len:len];
                        break;
                    case PDF_HEX_STRING_LEXEME_TYPE:
                        state = IN_OBJECT_AFTER_VALUE_STATE;
                        pdfValue = [self hexStringValueFromLexeme:lexeme len:len];
                        break;
                    case PDF_NAME_LEXEME_TYPE:
                        state = IN_OBJECT_AFTER_VALUE_STATE;
                        pdfValue = [self nameValueFromLexeme:lexeme len:len];
                        break;
                    case PDF_TRUE_KEYWORD_LEXEME_TYPE:
                        state = IN_OBJECT_AFTER_VALUE_STATE;
                        pdfValue = [PDFValue trueValue];
                        break;
                    case PDF_FALSE_KEYWORD_LEXEME_TYPE:
                        state = IN_OBJECT_AFTER_VALUE_STATE;
                        pdfValue = [PDFValue falseValue];
                        break;
                    case PDF_ENDOBJ_KEYWORD_LEXEME_TYPE:
                        state = END_STATE;
                        pdfObj = [PDFObject pdfObjectWithValue:nil objectNumber:objectNumber generatedNumber:generatedNumber];
                        break;
                    case PDF_OPEN_ARRAY_LEXEME_TYPE:
                        array = [NSMutableArray array];
                        pdfValue = [PDFValue arrayValue:array];
                        state = IN_OBJECT_IN_ARRAY_STATE;
                        break;
                    case PDF_OPEN_DICTIONARY_LEXEME_TYPE:
                        dictionary = [NSMutableDictionary dictionary];
                        pdfValue = [PDFValue dictionaryValue:dictionary];
                        state = IN_OBJECT_IN_DICTIONARY_WAIT_KEY_STATE;
                        break;
                    case PDF_NULL_KEYWORD_LEXEME:
                        pdfValue = [PDFValue nullValue];
                        state = IN_OBJECT_AFTER_VALUE_STATE;
                        break;
                    default:
                        ErrorState(@"Bad state in OBJ_KEYWORD_STATE");
                        break;
                }
                break;
            case IN_OBJECT_AFTER_NUMBER_STATE:
                switch (type) {
                    case PDF_UINT_NUMBER_TYPE:
                        refGeneratedNumber = [self unsignedIntegerFromUINTLexeme:lexeme len:len];
                        state = IN_OBJECT_AFTER_NUMBER_NEED_R_STATE;
                        break;
                    case PDF_ENDOBJ_KEYWORD_LEXEME_TYPE:
                        state = END_STATE;
                        pdfValue = [PDFValue numberValue:@(refObjectNumber)];
                        pdfObj = [PDFObject pdfObjectWithValue:pdfValue objectNumber:objectNumber generatedNumber:generatedNumber];
                        break;
                    default:
                        ErrorState(@"Bad state in IN_OBJECT_AFTER_NUMBER_STATE");
                        break;
                }
                break;
            case IN_OBJECT_AFTER_NUMBER_NEED_R_STATE:
                switch (type) {
                    case PDF_R_KEYWORD_LEXEME:
                        pdfValue = [PDFValue pdfRefValueWithObjectNumber:refObjectNumber generatedNumber:refGeneratedNumber];
                        state = IN_OBJECT_AFTER_VALUE_STATE;
                        break;
                    default:
                        break;
                }
                break;
            case IN_OBJECT_AFTER_VALUE_STATE:
                switch (type) {
                    case PDF_ENDOBJ_KEYWORD_LEXEME_TYPE:
                        pdfObj = [PDFObject pdfObjectWithValue:pdfValue objectNumber:objectNumber generatedNumber:generatedNumber];
                        state = END_STATE;
                        break;
                    default:
                        ErrorState(@"Bad type in IN_OBJECT_AFTER_VALUE_STATE");
                        break;
                }
                break;
            case IN_OBJECT_IN_ARRAY_STATE:
                switch (type) {
                    case PDF_UINT_NUMBER_TYPE:
                    case PDF_INT_NUMBER_TYPE:
                    case PDF_NUMBER_LEXEME_TYPE:
                        [array addObject:[self numberValueFromLexeme:lexeme len:len]];
                        break;
                    case PDF_STRING_LEXEME_TYPE:
                        [array addObject:[self stringValueFromLexeme:lexeme len:len]];
                        break;
                    case PDF_HEX_STRING_LEXEME_TYPE:
                        [array addObject:[self hexStringValueFromLexeme:lexeme len:len]];
                        break;
                    case PDF_NAME_LEXEME_TYPE:
                        [array addObject:[self nameValueFromLexeme:lexeme len:len]];
                        break;
                    case PDF_TRUE_KEYWORD_LEXEME_TYPE:
                        [array addObject:[PDFValue trueValue]];
                        break;
                    case PDF_FALSE_KEYWORD_LEXEME_TYPE:
                        [array addObject:[PDFValue falseValue]];
                        break;
                    case PDF_OPEN_ARRAY_LEXEME_TYPE:
                        state = IN_OBJECT_IN_ARRAY_STATE;
                        [stack pushObject:@{@"value" : pdfValue, @"type" : @0}];
                        array = [NSMutableArray array];
                        pdfValue = [PDFValue arrayValue:array];
                        break;
                    case PDF_NULL_KEYWORD_LEXEME:
                        [array addObject:[PDFValue nullValue]];
                        break;
                    case PDF_CLOSE_ARRAY_LEXEME_TYPE:
                        if (stack.count == 0) {
                            state = IN_OBJECT_AFTER_VALUE_STATE;
                        } else {
                            PDFValue *tmp = pdfValue;
                            pdfValue = [stack top][@"value"];
                            switch ([[stack top][@"type"] intValue]) {
                                case 0:
                                    array = (NSMutableArray*)pdfValue.value;
                                    [array addObject:tmp];
                                    state = IN_OBJECT_IN_ARRAY_STATE;
                                    break;
                                    
                                default:
                                    dictionary = (NSMutableDictionary*)pdfValue.value;
                                    dictionary[[stack top][@"key"]] = tmp;
                                    state = IN_OBJECT_IN_DICTIONARY_WAIT_KEY_STATE;
                                    break;
                            }
                            [stack pop];
                        }
                        break;
                    default:
                        break;
                }
                break;
            case IN_OBJECT_IN_DICTIONARY_WAIT_KEY_STATE:
                switch (type) {
                    case PDF_NAME_LEXEME_TYPE:
                        state = IN_OBJECT_IN_DICTIONARY_WAIT_VALUE_STATE;
                        key = [self stringFromLexeme:lexeme len:len];
                        break;
                    case PDF_CLOSE_DICTIONARY_LEXEME_TYPE:
                        state = IN_OBJECT_AFTER_VALUE_STATE;
                        break;
                    default:
                        ErrorState(@"Only name type can be dictionary keys");
                        break;
                }
                break;
            case IN_OBJECT_IN_DICTIONARY_WAIT_VALUE_STATE:
                switch (type) {
                    case PDF_UINT_NUMBER_TYPE:
                        state = IN_OBJECT_IN_DICTIONARY_AFTER_UINT_STATE;
                        refObjectNumber = [self unsignedIntegerFromUINTLexeme:lexeme len:len];
                        break;
                    case PDF_INT_NUMBER_TYPE:
                    case PDF_NUMBER_LEXEME_TYPE:
                        dictionary[key] = [self numberValueFromLexeme:lexeme len:len];
                        state = IN_OBJECT_IN_DICTIONARY_WAIT_KEY_STATE;
                        break;
                    case PDF_NAME_LEXEME_TYPE:
                        dictionary[key] = [self nameValueFromLexeme:lexeme len:len];
                        state = IN_OBJECT_IN_DICTIONARY_WAIT_KEY_STATE;
                        break;
                    case PDF_STRING_LEXEME_TYPE:
                        dictionary[key] = [self stringValueFromLexeme:lexeme len:len];
                        state = IN_OBJECT_IN_DICTIONARY_WAIT_KEY_STATE;
                        break;
                    case PDF_HEX_STRING_LEXEME_TYPE:
                        dictionary[key] = [self hexStringValueFromLexeme:lexeme len:len];
                        state = IN_OBJECT_IN_DICTIONARY_WAIT_KEY_STATE;
                        break;
                    case PDF_TRUE_KEYWORD_LEXEME_TYPE:
                        dictionary[key] = [PDFValue trueValue];
                        state = IN_OBJECT_IN_DICTIONARY_WAIT_KEY_STATE;
                        break;
                    case PDF_FALSE_KEYWORD_LEXEME_TYPE:
                        dictionary[key] = [PDFValue falseValue];
                        state = IN_OBJECT_IN_DICTIONARY_WAIT_KEY_STATE;
                        break;
                    case PDF_NULL_KEYWORD_LEXEME:
                        dictionary[key] = [PDFValue nullValue];
                        state = IN_OBJECT_IN_DICTIONARY_WAIT_KEY_STATE;
                    default:
                        break;
                }
                break;
            case IN_OBJECT_IN_DICTIONARY_AFTER_UINT_STATE:
                switch (type) {
                    case PDF_UINT_NUMBER_TYPE:
                        state = IN_OBJECT_IN_DICTIONARY_NEED_R_STATE;
                        refGeneratedNumber = [self unsignedIntegerFromUINTLexeme:lexeme len:len];
                        break;
                    default:
                        ErrorState(@"Syntaxis error in dictoinary value");
                        break;
                }
                break;
            case IN_OBJECT_IN_DICTIONARY_NEED_R_STATE:
                switch (type) {
                    case PDF_R_KEYWORD_LEXEME:
                        dictionary[key] = [PDFValue pdfRefValueWithObjectNumber:refObjectNumber generatedNumber:refGeneratedNumber];
                        state = IN_OBJECT_IN_DICTIONARY_WAIT_KEY_STATE;
                        break;
                    default:
                        ErrorState(@"Syntaxis error in dictionary value");
                        break;
                }
            default:
                break;
        }
    }
    
    return pdfObj;
}

- (NSObject*)nextSyntaxObject
{
    enum PDFSyntaxAnalyzerStates state = BEGIN_STATE;
    return [self nextSyntaxObjectIterWithState:state];
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