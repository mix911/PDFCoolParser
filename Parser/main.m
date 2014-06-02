//
//  main.m
//  Parser
//
//  Created by Aliona on 10.05.14.
//  Copyright (c) 2014 Ptenster. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Foundation/NSObject.h>

#import "PDFSyntaxAnalyzer.h"

int main(int argc, const char * argv[])
{
    @autoreleasepool {
        NSData *fileData = [NSData dataWithContentsOfFile:@"/Users/kozliappi/Downloads/PDFCoolParser-master/test_in.pdf"];
        
        PDFSyntaxAnalyzer *syntaxAnalyzer = [[PDFSyntaxAnalyzer alloc] initWithData:fileData];
        for (PDFObject *syntaxObject = [syntaxAnalyzer nextSyntaxObject]; syntaxObject; syntaxObject = [syntaxAnalyzer nextSyntaxObject]) {
            NSLog(@"%@", syntaxObject);
        }
    }
    return 0;
}
