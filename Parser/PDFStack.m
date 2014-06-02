//
//  PDFStack.m
//  Parser
//
//  Created by Aliona on 20.05.14.
//  Copyright (c) 2014 Ptenster. All rights reserved.
//

#import "PDFStack.h"

@interface PDFStack()
{
    NSMutableArray *_array;
}

@end

@implementation PDFStack

@synthesize allMembers = _array;

+ (PDFStack*)pdfStack
{
    return [[[PDFStack alloc] init] autorelease];
}

+ (PDFStack*)pdfStackWithCapacity:(NSUInteger)capacity
{
    return [[[PDFStack alloc] initWithCapacity:capacity] autorelease];
}

- (id)init
{
    self = [super init];
    if (self) {
        _array = [[NSMutableArray alloc] init];
    }
    return self;
}

- (id)initWithCapacity:(NSUInteger)capacity
{
    self = [super init];
    if (self) {
        _array = [[NSMutableArray alloc] initWithCapacity:capacity];
    }
    return self;
}

- (void)pop
{
    [_array removeLastObject];
}

- (void)pushObject:(NSObject *)object
{
    [_array addObject:object];
}

- (id)top
{
    return [_array lastObject];
}

- (NSUInteger)count
{
    return _array.count;
}

@end
