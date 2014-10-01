//
//  PDFValue.h
//  Parser
//
//  Created by Aliona on 31.05.14.
//  Copyright (c) 2014 Ptenster. All rights reserved.
//

#import <Foundation/Foundation.h>

enum PDFValueTypes
{
    PDF_BOOL_VALUE_TYPE,
    PDF_NUMBER_VALUE_TYPE,
    PDF_STRING_VALUE_TYPE,
    PDF_HEX_STRING_VALUE_TYPE,
    PDF_NAME_VALUE_TYPE,
    PDF_ARRAY_VALUE_TYPE,
    PDF_DICTIONARY_VALUE_TYPE,
    PDF_NULL_VALUE_TYPE,
    PDF_REF_VALUE_TYPE,
};

@class PDFRef;

@interface PDFValue : NSObject

+ (PDFValue*)trueValue;
+ (PDFValue*)falseValue;
+ (PDFValue*)numberValue:(NSNumber*)number;
+ (PDFValue*)stringValue:(NSString*)string;
+ (PDFValue*)hexStringValue:(NSString*)string;
+ (PDFValue*)nameValue:(NSString*)name;
+ (PDFValue*)dictionaryValue:(NSMutableDictionary*)dict;
+ (PDFValue*)arrayValue:(NSMutableArray*)array;
+ (PDFValue*)nullValue;
+ (PDFValue*)refValueWithObjectNumber:(NSUInteger)objectNumber generatedNumber:(NSUInteger)generatedNumber;

- (id)initValueWithValue:(NSObject*)value type:(enum PDFValueTypes)type;

@property (readonly, retain) NSObject *value;
@property enum PDFValueTypes type;

- (BOOL)isEqualToPDFValue:(PDFValue*)pdfValue;

@end

#define PDFNum(x) [PDFValue numberValue:@(x)]
#define PDFHStr(s) [PDFValue hexStringValue:s]
#define PDFStr(s) [PDFValue stringValue:s]
#define PDFRef(o, g) [PDFValue refValueWithObjectNumber:o generatedNumber:g]
#define PDFFalse [PDFValue falseValue]
#define PDFTrue [PDFValue trueValue]
#define PDFNull [PDFValue nullValue]
#define __PDFArrayHelper__(constNil, ...)
#define PDFArray(...) [PDFValue arrayValue:[NSMutableArray arrayWithObjects:__VA_ARGS__, nil]]
#define PDFArrayNil [PDFValue arrayValue:[NSMutableArray array]]
#define PDFDictNil [PDFValue dictionaryValue:[NSMutableDictionary dictionary]]
#define PDFDict(dict) [PDFValue dictionaryValue:[NSMutableDictionary dictionaryWithDictionary:dict]]
#define PDFName(n) [PDFValue nameValue:n]