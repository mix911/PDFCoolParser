//
//  PDFXRefSection.m
//  Parser
//
//  Created by demo on 06.06.14.
//  Copyright (c) 2014 Ptenster. All rights reserved.
//

#import "PDFXRefSection.h"

@implementation PDFXRefSection

+ (PDFXRefSection*)pdfXRefSectionWithFirstObjectNumber:(NSUInteger)firstObjectNumber lastObjectNumber:(NSUInteger)lastObjectNumber data:(NSData *)data
{
    return [[[PDFXRefSection alloc] initWithFirstObjectNumber:firstObjectNumber lastObjectNumber:lastObjectNumber data:data] autorelease];
}

- (id)initWithFirstObjectNumber:(NSUInteger)firstObjectNumber lastObjectNumber:(NSUInteger)lastObjectNumber data:(NSData *)data
{
    self = [super init];
    if (self) {
        _firstObjectNumber = firstObjectNumber;
        _lastObjectNumber = lastObjectNumber;
        _data = data;
    }
    return self;
}

@end
