//
//  PDFObject.m
//  Parser
//
//  Created by demo on 13.05.14.
//  Copyright (c) 2014 Ptenster. All rights reserved.
//

#import "PDFObject.h"
#import "PDFValue.h"

@implementation PDFObject

+ (PDFObject*)pdfComment:(NSString *)comment
{
    return [[[PDFObject alloc] initWithComment:comment] autorelease];
}

+ (PDFObject*)pdfObjectWithValue:(PDFValue *)value objectNumber:(NSUInteger)objectNumber generatedNumber:(NSUInteger)generatedNumber
{
    return [[[PDFObject alloc] initWithValue:value objectNumber:objectNumber generatedNumber:generatedNumber] autorelease];
}

- (id)initWithValue:(PDFValue *)value objectNumber:(NSUInteger)objectNumber generatedNumber:(NSUInteger)generatedNumber
{
    self = [super init];
    if (self) {
        _objectNumber = objectNumber;
        _generatedNumber = generatedNumber;
        _value = [value retain];
        _type = PDF_OBJECT_TYPE;
    }
    return self;
}

- (id)initWithComment:(NSString *)comment
{
    self = [super init];
    if (self) {
        _comment = [comment retain];
        _type = PDF_COMMENT_TYPE;
    }
    return self;
}

- (NSString*)description
{
    switch (self.type) {
        case PDF_COMMENT_TYPE:
            return self.comment.description;
        case PDF_OBJECT_TYPE:
            return [NSString stringWithFormat:@"%lu %lu obj\r%@\rendobj", self.objectNumber, self.generatedNumber, self.value];
        default:
            return [NSString stringWithFormat:@"Unkown object type: %@", [super description]];
    }
}

- (BOOL)isEqual:(id)object
{
    PDFObject *pdfObj = (PDFObject*)object;
    
    switch (self.type) {
        case PDF_COMMENT_TYPE:
            return pdfObj.type == PDF_COMMENT_TYPE && [self.comment isEqualToString:pdfObj.comment];
        case PDF_OBJECT_TYPE:
            if (self.value) {
                return pdfObj.type == PDF_OBJECT_TYPE && self.objectNumber == pdfObj.objectNumber && self.generatedNumber == pdfObj.generatedNumber && [self.value isEqualToPDFValue:pdfObj.value];
            } else {
                return pdfObj.type == PDF_OBJECT_TYPE && self.objectNumber == pdfObj.objectNumber && self.generatedNumber == pdfObj.generatedNumber && pdfObj.value == nil;
            }
        default:
            return NO;
    }
}

@end
