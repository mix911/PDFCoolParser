//
//  main.m
//  Parser
//
//  Created by Aliona on 10.05.14.
//  Copyright (c) 2014 Ptenster. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Foundation/NSObject.h>

#import "PDFDocument.h"

#import "PDFSyntaxAnalyzer.h"

int main(int argc, const char * argv[])
{

    @autoreleasepool {
        
        NSData *fileData = [NSData dataWithContentsOfFile:@"/Users/demo/Documents/Projects/PDFCoolParser/test_in.pdf"];
        
        PDFDocument *document = [[PDFDocument alloc] initWithData:fileData];
        if ([document errorMessage]) {
            NSLog(@"%@", [document errorMessage]);
        }
        else {
            NSLog(@"%@", [document version]);
        }
    }
    return 0;
}
