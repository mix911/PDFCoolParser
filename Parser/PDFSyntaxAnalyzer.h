//
//  PDFSyntaxAnalyzer.h
//  Parser
//
//  Created by demo on 17.05.14.
//  Copyright (c) 2014 Ptenster. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PDFObject;

@interface PDFSyntaxAnalyzer : NSObject

- (id)initWithData:(NSData*)data;
- (PDFObject*)nextSyntaxObject;

@property (readonly) NSString *errorMessage;

@end
