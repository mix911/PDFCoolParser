//
//  PDFXRefTable.h
//  Parser
//
//  Created by demo on 06.06.14.
//  Copyright (c) 2014 Ptenster. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PDFXRefTable : NSObject

+ (PDFXRefTable*)pdfXRefTableWithSubSections:(NSArray*)subSections;
- (id)initWithXRefTableWithSubSections:(NSArray*)subSections;

@property (readonly, retain) NSArray *subSections;

- (BOOL)isEqualToXRefTable:(PDFXRefTable*)xrefTable;

@end
