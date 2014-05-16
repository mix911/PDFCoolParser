//
//  PDFObject.m
//  Parser
//
//  Created by demo on 13.05.14.
//  Copyright (c) 2014 Ptenster. All rights reserved.
//

#import "PDFObject.h"

@implementation PDFObject

- (NSString*)description
{
    return [NSString stringWithFormat:@"%lu %lu obj\r%@\rendobj", self.firstNumber, self.secondNumber, self.value];
}

@end
