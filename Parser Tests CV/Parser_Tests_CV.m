//
//  Parser_Tests_CV.m
//  Parser Tests CV
//
//  Created by demo on 14.06.14.
//  Copyright (c) 2014 Ptenster. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "PDFSyntaxAnalyzer.h"
#import "PDFObject.h"
#import "PDFValue.h"

@interface Parser_Tests_CV : XCTestCase
{
    PDFSyntaxAnalyzer *_syntaxAnalyzer;
    NSData *_syntaxAnalyzerData;
}

@end

@implementation Parser_Tests_CV

- (void)setUp
{
    [super setUp];
    
    _syntaxAnalyzerData = [NSData dataWithContentsOfFile:@"/Users/demo/Downloads/CV.pdf"];
    char* buffer = malloc(_syntaxAnalyzerData.length+1);
    memcpy(buffer, _syntaxAnalyzerData.bytes, _syntaxAnalyzerData.length);
    buffer[_syntaxAnalyzerData.length] = 0;
    _syntaxAnalyzerData = [NSData dataWithBytes:buffer length:_syntaxAnalyzerData.length];
    free(buffer);
    
    _syntaxAnalyzer = [[PDFSyntaxAnalyzer alloc] initWithData:_syntaxAnalyzerData];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)subTestComment:(NSString*)comment
{
    XCTAssertEqualObjects([_syntaxAnalyzer nextSyntaxObject], [PDFObject pdfComment:comment], @"");
}

- (void)subTestObject:(NSUInteger)objectNumber :(NSUInteger)generatedNumber :(PDFValue*)value
{
    PDFObject* srcObj = [_syntaxAnalyzer nextSyntaxObject];
    if (srcObj == nil) {
        XCTAssert(NO, @"Error: %@", _syntaxAnalyzer.errorMessage);
        return;
    }
    PDFObject* tmpObj = [PDFObject pdfObjectWithValue:value objectNumber:objectNumber generatedNumber:generatedNumber];
    XCTAssertEqualObjects(srcObj, tmpObj, @"");
}

- (void)subTestObject:(NSUInteger)objectNumber :(NSUInteger)generatedNumber :(PDFValue*)value :(NSData*)stream
{
    PDFObject* srcObj = [_syntaxAnalyzer nextSyntaxObject];
    if (srcObj == nil) {
        XCTAssert(NO, @"Error: %@", _syntaxAnalyzer.errorMessage);
        return;
    }
    PDFObject* tmpObj = [PDFObject pdfObjectWithValue:value stream:stream objectNumber:objectNumber generatedNumber:generatedNumber];
    XCTAssertEqualObjects(srcObj, tmpObj, @"");
}

- (void)subTestXRefTable:(PDFXRefTable*)table trailer:(NSDictionary*)trailer offset:(NSUInteger)offset
{
    PDFObject* srcObj = [_syntaxAnalyzer nextSyntaxObject];
    if (srcObj == nil) {
        XCTAssert(NO, @"Error: %@", _syntaxAnalyzer.errorMessage);
        return;
    }
    PDFObject* tmpObj = [PDFObject pdfObjectWithXRefTable:table trailer:trailer offset:offset];
    XCTAssertEqualObjects(srcObj, tmpObj, @"");
}


- (void)testCV
{
    [self subTestComment:@"%PDF-1.4"];
    [self subTestComment:@"%áéëÓ"];
    [self subTestObject:9
                       :0
                       :[PDFValue dictionaryValue:
                         [NSMutableDictionary dictionaryWithDictionary:
                          @{
                            @"/Type" : [PDFValue nameValue:@"/Catalog"],
                            @"/Pages": [PDFValue pdfRefValueWithObjectNumber:1 generatedNumber:0]
                            }]]];
    [self subTestObject:10
                       :0
                       :[PDFValue dictionaryValue:
                         [NSMutableDictionary dictionaryWithDictionary:
                          @{
                            @"/Type" : [PDFValue nameValue:@"/Page"],
                            @"/Parent" : [PDFValue pdfRefValueWithObjectNumber:1 generatedNumber:0],
                            @"/Resources" : [PDFValue dictionaryValue:
                                             [NSMutableDictionary dictionaryWithDictionary:
                                              @{
                                                @"/ProcSets" : [PDFValue arrayValue:
                                                                [NSMutableArray arrayWithObjects:
                                                                 [PDFValue nameValue:@"/PDF"],
                                                                 [PDFValue nameValue:@"/Text"],
                                                                 [PDFValue nameValue:@"/ImageB"],
                                                                 [PDFValue nameValue:@"/ImageC"],
                                                                 [PDFValue nameValue:@"/ImageI"],
                                                                 nil]],
                                                @"/ExtGState" : [PDFValue dictionaryValue:
                                                                 [NSMutableDictionary dictionaryWithDictionary:
                                                                  @{
                                                                    @"/G0" : [PDFValue pdfRefValueWithObjectNumber:11 generatedNumber:0]
                                                                    }]],
                                                @"/Font" : [PDFValue dictionaryValue:
                                                            [NSMutableDictionary dictionaryWithDictionary:
                                                             @{
                                                               @"/F0" : [PDFValue pdfRefValueWithObjectNumber:12 generatedNumber:0],
                                                               @"/F1" : [PDFValue pdfRefValueWithObjectNumber:13 generatedNumber:0]
                                                               }]]
                                                }]],
                            @"/MediaBox" : [PDFValue arrayValue:[NSMutableArray arrayWithObjects:
                                                                 [PDFValue numberValue:@(0)],
                                                                 [PDFValue numberValue:@(0)],
                                                                 [PDFValue numberValue:@(612)],
                                                                 [PDFValue numberValue:@(792)],
                                                                 nil]],
                            @"/Contents" : [PDFValue pdfRefValueWithObjectNumber:14 generatedNumber:0]
                            }]]];
}

@end
