//
//  PDFXRefSection.m
//  Parser
//
//  Created by demo on 06.06.14.
//  Copyright (c) 2014 Ptenster. All rights reserved.
//

#import "PDFXRefSubSection.h"

@implementation PDFXRefSubSection

+ (PDFXRefSubSection*)pdfXRefSectionWithFirstObjectNumber:(NSUInteger)firstObjectNumber lastObjectNumber:(NSUInteger)lastObjectNumber data:(NSData *)data
{
    return [[[PDFXRefSubSection alloc] initWithFirstObjectNumber:firstObjectNumber lastObjectNumber:lastObjectNumber data:data] autorelease];
}

- (id)initWithFirstObjectNumber:(NSUInteger)firstObjectNumber lastObjectNumber:(NSUInteger)lastObjectNumber data:(NSData *)data
{
    self = [super init];
    if (self) {
        _firstObjectNumber = firstObjectNumber;
        _lastObjectNumber = lastObjectNumber;
        _data = data;
    }
    return self;
}

- (BOOL)isEqualToXRefSubSection:(PDFXRefSubSection*)subSection
{
    NSString *s1 = [[NSString alloc] initWithBytes:_data.bytes              length:_data.length             encoding:NSASCIIStringEncoding];
    NSString *s2 = [[NSString alloc] initWithBytes:subSection.data.bytes    length:subSection.data.length   encoding:NSASCIIStringEncoding];
    
    if ([s1 isEqualToString:s2]) {
        NSLog(@"Hello!!");
    } else {
        if (s1.length == s2.length) {
            NSLog(@"length == %lu", (unsigned long)s1.length);
            for (NSUInteger i = 0; i < s1.length; ++i) {
                if ([s1 characterAtIndex:i] != [s2 characterAtIndex:i]) {
                    NSLog(@"%c ~ %i vs %i", [s1 characterAtIndex:i], (int)[s1 characterAtIndex:i], (int)[s2 characterAtIndex:i]);
                }
            }
        } else {
            
        }
    }
    NSLog(@"\r%@vs\r%@\r!!!!", s1, s2);
    
    return  _firstObjectNumber == subSection.firstObjectNumber &&
            _lastObjectNumber == subSection.lastObjectNumber &&
            [self.data isEqualToData:subSection.data];
}

@end
