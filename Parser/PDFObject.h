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
};

@interface PDFObject : NSObject

+ (PDFObject*)pdfComment:(NSString*)comment;
+ (PDFObject*)pdfObjectWithValue:(PDFValue*)value objectNumber:(NSUInteger)objectNumber generatedNumber:(NSUInteger)generatedNumber;

- (id)initWithValue:(PDFValue*)value objectNumber:(NSUInteger)objectNumber generatedNumber:(NSUInteger)generatedNumber;
- (id)initWithComment:(NSString*)comment;

@property NSUInteger objectNumber;
@property NSUInteger generatedNumber;
@property (readonly, retain) PDFValue *value;
@property (readonly, retain) NSString *comment;
@property (readonly) enum PDFObjectTypes type;

@end
