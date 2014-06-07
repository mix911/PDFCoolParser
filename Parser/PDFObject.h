//
//  PDFObject.h
//  Parser
//
//  Created by demo on 13.05.14.
//  Copyright (c) 2014 Ptenster. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PDFValue.h"

enum PDFObjectTypes
{
    PDF_COMMENT_TYPE,
    PDF_OBJECT_TYPE,
    PDF_XREF_TYPE,
};

@class PDFXRefTable;

@interface PDFObject : NSObject

+ (PDFObject*)pdfComment:(NSString*)comment;
+ (PDFObject*)pdfObjectWithValue:(PDFValue*)value objectNumber:(NSUInteger)objectNumber generatedNumber:(NSUInteger)generatedNumber;
+ (PDFObject*)pdfObjectWithValue:(PDFValue*)value stream:(NSData*)stream objectNumber:(NSUInteger)objectNumber generatedNumber:(NSUInteger)generatedNumber;
+ (PDFObject*)pdfObjectWithXRefTable:(PDFXRefTable*)table trailer:(NSDictionary*)trailer offset:(NSUInteger)offset;

- (id)initWithValue:(PDFValue*)value objectNumber:(NSUInteger)objectNumber generatedNumber:(NSUInteger)generatedNumber;
- (id)initWithValue:(PDFValue*)value stream:(NSData*)stream objectNumber:(NSUInteger)objectNumber generatedNumber:(NSUInteger)generatedNumber;
- (id)initWithXRefTable:(PDFXRefTable*)table trailer:(NSDictionary*)trailer offset:(NSUInteger)offset;
- (id)initWithComment:(NSString*)comment;

@property (readonly) NSUInteger objectNumber;
@property (readonly) NSUInteger generatedNumber;

@property (readonly, retain) PDFValue *value;
@property (readonly, retain) NSData *stream;

@property (readonly, retain) NSString *comment;

@property (readonly, retain) PDFXRefTable *xrefTable;
@property (readonly, retain) NSDictionary *trailer;
@property (readonly) NSUInteger offset;

@property (readonly) enum PDFObjectTypes type;


@end
