//
//  PDFComment.m
//  Parser
//
//  Created by demo on 13.05.14.
//  Copyright (c) 2014 Ptenster. All rights reserved.
//

#import "PDFComment.h"

@interface PDFComment()
{
    NSString *_comment;
}
@end

@implementation PDFComment

- (id)initWithString:(NSString *)string
{
    if (self = [super init]) {
        _comment = string;
    }
    return self;
}

@end
