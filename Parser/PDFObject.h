//
//  PDFObject.h
//  Parser
//
//  Created by demo on 13.05.14.
//  Copyright (c) 2014 Ptenster. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PDFObject : NSObject

@property NSUInteger firstNumber;
@property NSUInteger secondNumber;
@property (retain) NSObject *value;

@end
