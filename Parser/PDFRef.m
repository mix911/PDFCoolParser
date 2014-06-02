//
//  PDFRef.m
//  Parser
//
//  Created by Aliona on 20.05.14.
//  Copyright (c) 2014 Ptenster. All rights reserved.
//

#import "PDFRef.h"

@implementation PDFRef

+ (PDFRef*)pdfRefWithObjectNumber:(NSUInteger)objectNumber generatedNumber:(NSUInteger)genertedNumber
{
    return [[[PDFRef alloc] initWithObjectNumber:objectNumber generatedNumber:genertedNumber] autorelease];
}

- (id)initWithObjectNumber:(NSUInteger)objectNumber generatedNumber:(NSUInteger)genertedNumber
{
    self = [super init];
    if (self) {
        _objectNumber = objectNumber;
        _generatedNumber = genertedNumber;
    }
    return self;
}

- (NSString*)description
{
    return [NSString stringWithFormat:@"%lu %lu R", self.objectNumber, self.generatedNumber];
}

- (BOOL)isEqualToPDFRef:(PDFRef *)pdfRef
{
    return self.objectNumber == self.objectNumber && self.generatedNumber == pdfRef.generatedNumber;
}

@end
