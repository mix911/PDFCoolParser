//
//  PDFStack.h
//  Parser
//
//  Created by Aliona on 20.05.14.
//  Copyright (c) 2014 Ptenster. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PDFStack : NSObject

+ (PDFStack*)pdfStack;
+ (PDFStack*)pdfStackWithCapacity:(NSUInteger)capacity;

- (id)initWithCapacity:(NSUInteger)capacity;

- (void)pop;
- (void)pushObject:(NSObject*)object;
- (id)top;

@property (readonly, retain) NSArray* allMembers;
@property (readonly) NSUInteger count;

@end
