//
//  PDFRef.h
//  Parser
//
//  Created by Aliona on 20.05.14.
//  Copyright (c) 2014 Ptenster. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PDFRef : NSObject

+ (PDFRef*)pdfRefWithObjectNumber:(NSUInteger)objectNumber generatedNumber:(NSUInteger)genertedNumber;

@property NSUInteger objectNumber;
@property NSUInteger generatedNumber;

- (BOOL)isEqualToPDFRef:(PDFRef*)pdfRef;

@end
