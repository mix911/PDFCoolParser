//
//  PDFXRefTable.m
//  Parser
//
//  Created by demo on 06.06.14.
//  Copyright (c) 2014 Ptenster. All rights reserved.
//

#import "PDFXRefTable.h"

@implementation PDFXRefTable

+ (PDFXRefTable*)pdfXRefTableWithSubSections:(NSArray*)subSections
{
    return [[[PDFXRefTable alloc] initWithXRefTableWithSubSections:subSections] autorelease];
}

- (id)initWithXRefTableWithSubSections:(NSArray*)subSections
{
    self = [super init];
    if (self) {
        _subSections = subSections;
    }
    return self;
}

- (BOOL)isEqualToXRefTable:(PDFXRefTable*)xrefTable
{
    return YES;
}

@end
