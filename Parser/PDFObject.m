//
//  PDFObject.m
//  Parser
//
//  Created by demo on 13.05.14.
//  Copyright (c) 2014 Ptenster. All rights reserved.
//

#import "PDFObject.h"
#import "PDFValue.h"
#import "PDFXRefTable.h"

@implementation PDFObject

+ (PDFObject*)pdfComment:(NSString *)comment
{
    return [[[PDFObject alloc] initWithComment:comment] autorelease];
}

+ (PDFObject*)pdfObjectWithValue:(PDFValue *)value objectNumber:(NSUInteger)objectNumber generatedNumber:(NSUInteger)generatedNumber
{
    return [[[PDFObject alloc] initWithValue:value objectNumber:objectNumber generatedNumber:generatedNumber] autorelease];
}

+ (PDFObject*)pdfObjectWithValue:(PDFValue *)value stream:(NSData *)stream objectNumber:(NSUInteger)objectNumber generatedNumber:(NSUInteger)generatedNumber
{
    return [[[PDFObject alloc] initWithValue:value stream:stream objectNumber:objectNumber generatedNumber:generatedNumber] autorelease];
}

+ (PDFObject*)pdfObjectWithXRefTable:(PDFXRefTable*)table trailer:(NSDictionary*)trailer offset:(NSUInteger)offset
{
    return [[[PDFObject alloc] initWithXRefTable:table trailer:trailer offset:offset] autorelease];
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

- (id)initWithValue:(PDFValue *)value stream:(NSData *)stream objectNumber:(NSUInteger)objectNumber generatedNumber:(NSUInteger)generatedNumber
{
    self = [self initWithValue:value objectNumber:objectNumber generatedNumber:generatedNumber];
    if (self) {
        _stream = [stream retain];
    }
    return self;
}

- (id)initWithXRefTable:(PDFXRefTable*)table trailer:(NSDictionary*)trailer offset:(NSUInteger)offset
{
    self = [super init];
    if (self) {
        _xrefTable = [table retain];
        _type = PDF_XREF_TYPE;
        _trailer = [trailer retain];
        _offset = offset;
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
            return  (pdfObj.type == PDF_OBJECT_TYPE) &&
                    (self.objectNumber == pdfObj.objectNumber) &&
                    (self.generatedNumber == pdfObj.generatedNumber) &&
                    (self.value  ? [self.value isEqualToPDFValue:pdfObj.value]  : pdfObj.value  == nil) &&
                    (self.stream ? [self.stream isEqualToData:pdfObj.stream]    : pdfObj.stream == nil);
        case PDF_XREF_TYPE:
            return  (pdfObj.type == PDF_XREF_TYPE) &&
                    (self.offset == pdfObj.offset) &&
                    ([self isTrailerEqualToTrailer:pdfObj.trailer]) &&
                    ([self.xrefTable isEqualToXRefTable:pdfObj.xrefTable]);
        default:
            return NO;
    }
}

- (BOOL)compairWithoutStream:(PDFObject *)other
{
    switch (self.type) {
        case PDF_COMMENT_TYPE:
            return other.type == PDF_COMMENT_TYPE && [self.comment isEqualToString:other.comment];
        case PDF_OBJECT_TYPE:
            return  (other.type == PDF_OBJECT_TYPE) &&
            (self.objectNumber == other.objectNumber) &&
            (self.generatedNumber == other.generatedNumber) &&
            (self.value  ? [self.value isEqualToPDFValue:other.value]  : other.value  == nil);
        case PDF_XREF_TYPE:
            return  (other.type == PDF_XREF_TYPE) &&
            (self.offset == other.offset) &&
            ([self isTrailerEqualToTrailer:other.trailer]) &&
            ([self.xrefTable isEqualToXRefTable:other.xrefTable]);
        default:
            return NO;
    }
}
- (BOOL)isTrailerEqualToTrailer:(NSDictionary*)trailer
{
    if (self.trailer.count != trailer.count) {
        return NO;
    }
    for (NSString *key in [self.trailer allKeys]) {
        if ([((PDFValue*)self.trailer[key]) isEqualToPDFValue:(PDFValue *)trailer[key]] == NO) {
            return NO;
        }
    }
    return YES;
}

@end
