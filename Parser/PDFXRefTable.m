//
//  PDFXRefTable.m
//  Parser
//
//  Created by demo on 06.06.14.
//  Copyright (c) 2014 Ptenster. All rights reserved.
//

#import "PDFXRefTable.h"
#import "PDFXRefSubSection.h"

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
    if (self.subSections.count != xrefTable.subSections.count) {
        return NO;
    }
    for (NSUInteger i = 0; i < self.subSections.count; ++i) {
        if ([[self.subSections objectAtIndex:i] isEqualToXRefSubSection:[xrefTable.subSections objectAtIndex:i]] == NO) {
            return NO;
        }
    }
    return YES;
}

@end
