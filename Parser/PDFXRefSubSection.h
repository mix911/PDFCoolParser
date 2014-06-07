//
//  PDFXRefSection.h
//  Parser
//
//  Created by demo on 06.06.14.
//  Copyright (c) 2014 Ptenster. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PDFXRefSubSection : NSObject

+ (PDFXRefSubSection*) pdfXRefSectionWithFirstObjectNumber:(NSUInteger)firstObjectNumber lastObjectNumber:(NSUInteger)lastObjectNumber data:(NSData*)data;
- (id)initWithFirstObjectNumber:(NSUInteger)firstObjectNumber lastObjectNumber:(NSUInteger)lastObjectNumber data:(NSData*)data;

@property (readonly) NSUInteger firstObjectNumber;
@property (readonly) NSUInteger lastObjectNumber;
@property (readonly, retain) NSData *data;

- (BOOL)isEqualToXRefSubSection:(PDFXRefSubSection*)subSection;

@end
