//
//  PDFValue.m
//  Parser
//
//  Created by Aliona on 31.05.14.
//  Copyright (c) 2014 Ptenster. All rights reserved.
//

#import "PDFValue.h"
#import "PDFRef.h"

@implementation PDFValue

+ (PDFValue*)pdfValueWithValue:(NSObject *)value type:(enum PDFValueTypes)type
{
    return [[[PDFValue alloc] initValueWithValue:value type:type] autorelease];
}

+ (PDFValue*)trueValue
{
    return [self pdfValueWithValue:@YES type:PDF_BOOL_VALUE_TYPE];
}

+ (PDFValue*)falseValue
{
    return [self pdfValueWithValue:@NO type:PDF_BOOL_VALUE_TYPE];
}

+ (PDFValue*)numberValue:(NSNumber *)number
{
    return [self pdfValueWithValue:number type:PDF_NUMBER_VALUE_TYPE];
}

+ (PDFValue*)stringValue:(NSString *)string
{
    return [self pdfValueWithValue:string type:PDF_STRING_VALUE_TYPE];
}

+ (PDFValue*)hexStringValue:(NSString *)string
{
    return [self pdfValueWithValue:string type:PDF_HEX_STRING_VALUE_TYPE];
}

+ (PDFValue*)nameValue:(NSString *)name
{
    return [self pdfValueWithValue:name type:PDF_NAME_VALUE_TYPE];
}

+ (PDFValue*)dictionaryValue:(NSMutableDictionary *)dict
{
    return [self pdfValueWithValue:dict type:PDF_DICTIONARY_VALUE_TYPE];
}

+ (PDFValue*)arrayValue:(NSMutableArray *)array
{
    return [self pdfValueWithValue:array type:PDF_ARRAY_VALUE_TYPE];
}

+ (PDFValue*)nullValue
{
    return [self pdfValueWithValue:[NSNull null] type:PDF_NULL_VALUE_TYPE];
}

+ (PDFValue*)refValueWithObjectNumber:(NSUInteger)objectNumber generatedNumber:(NSUInteger)generatedNumber
{
    return [self pdfValueWithValue:[PDFRef pdfRefWithObjectNumber:objectNumber generatedNumber:generatedNumber] type:PDF_REF_VALUE_TYPE];
}

- (id)initValueWithValue:(NSObject *)value type:(enum PDFValueTypes)type
{
    self = [super init];
    if (self) {
        _value = [value retain];
        _type = type;
    }
    return self;
}

- (NSString *)description
{
    return self.value.description;
}

- (BOOL)isEqualToPDFValue:(PDFValue *)pdfValue
{
    if (pdfValue.type != self.type) {
        return NO;
    }
    switch (self.type) {
        case PDF_NUMBER_VALUE_TYPE:
        case PDF_BOOL_VALUE_TYPE:
            return [((NSNumber*)self.value) isEqualToNumber:(NSNumber*)pdfValue.value];
        case PDF_NAME_VALUE_TYPE:
        case PDF_STRING_VALUE_TYPE:
        case PDF_HEX_STRING_VALUE_TYPE:
            return [((NSString*)self.value) isEqualToString:(NSString*)pdfValue.value];
        case PDF_REF_VALUE_TYPE:
            return [((PDFRef*)self.value) isEqualToPDFRef:(PDFRef*)pdfValue.value];
        case PDF_ARRAY_VALUE_TYPE:
        {
            NSArray *selfArr = (NSArray*)self.value;
            NSArray *otheArr = (NSArray*)pdfValue.value;
            if (selfArr.count != otheArr.count) {
                return NO;
            }
            for (NSUInteger i = 0; i < selfArr.count; ++i) {
                if ([((PDFValue*)[selfArr objectAtIndex:i]) isEqualToPDFValue:(PDFValue*)[otheArr objectAtIndex:i]] == NO) {
                    return NO;
                }
            }
            return YES;
        }
        case PDF_DICTIONARY_VALUE_TYPE:
        {
            NSDictionary *selfDict = (NSDictionary*)self.value;
            NSDictionary *otheDict = (NSDictionary*)pdfValue.value;
            if (selfDict.count != otheDict.count) {
                return NO;
            }
            for (NSString *key in [selfDict keyEnumerator]) {
                PDFValue *selfVal = selfDict[key];
                PDFValue *otheVal = otheDict[key];
                if ([selfVal isEqualToPDFValue:otheVal] == NO) {
                    return NO;
                }
            }
            return YES;
        }
        default:
            return [self.value isEqualTo:pdfValue.value];
    }
    return NO;
}

@end
