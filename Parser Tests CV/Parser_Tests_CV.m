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

- (void)subTestObjectNoStream:(NSUInteger)objectNumber :(NSUInteger)generatedNumber :(PDFValue*)value
{
    PDFObject* srcObj = [_syntaxAnalyzer nextSyntaxObject];
    if (srcObj == nil) {
        XCTAssert(NO, @"Error: %@", _syntaxAnalyzer.errorMessage);
        return;
    }
    PDFObject* tmpObj = [PDFObject pdfObjectWithValue:value objectNumber:objectNumber generatedNumber:generatedNumber];
    XCTAssert([srcObj compairWithoutStream:tmpObj], @"");
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
                       :PDFDict((@{
                            @"/Type" : PDFName(@"/Catalog"),
                            @"/Pages": PDFRef(1, 0)
                            }))];
    [self subTestObject:10
                       :0
                       :PDFDict((@{
                            @"/Type" : PDFName(@"/Page"),
                            @"/Parent" : PDFRef(1, 0),
                            @"/Resources" : PDFDict((@{
                                                @"/ProcSets" : PDFArray(
                                                                 PDFName(@"/PDF"),
                                                                 PDFName(@"/Text"),
                                                                 PDFName(@"/ImageB"),
                                                                 PDFName(@"/ImageC"),
                                                                 PDFName(@"/ImageI")),
                                                @"/ExtGState" : PDFDict((@{
                                                                    @"/G0" : PDFRef(11, 0)
                                                                    })),
                                                @"/Font" : PDFDict((@{
                                                               @"/F0" : PDFRef(12, 0),
                                                               @"/F1" : PDFRef(13, 0)
                                                               }))
                                                })),
                            @"/MediaBox" : PDFArray(
                                                     PDFNum(0),
                                                     PDFNum(0),
                                                     PDFNum(612),
                                                     PDFNum(792)),
                            @"/Contents" : PDFRef(14, 0)
                            }))];
    [self subTestObjectNoStream:14
                               :0
                               :PDFDict((@{
                                    @"/Filter" : PDFName(@"/FlateDecode"),
                                    @"/Length" : PDFNum(6480)
                                    }))];
    [self subTestObjectNoStream:11
                               :0
                               :PDFDict((@{
                                    @"/Type": PDFName(@"/ExtGState"),
                                    @"/CA"  : PDFNum(1),
                                    @"/ca"  : PDFNum(1),
                                    @"/LC"  : PDFNum(0),
                                    @"/LJ"  : PDFNum(0),
                                    @"/LW"  : PDFNum(0),
                                    @"/ML"  : PDFNum(4),
                                    @"/SA"  : PDFTrue,
                                    @"/BM"  : PDFName(@"/Normal")
                                    }))];
//    [self subTestObjectNoStream:12
//                               :0
//                               :PDFDict((@{
//                                    @"/Type"            : PDFName(@"/Font"),
//                                    @"/Subtype"         : PDFName(@"/Type0"),
//                                    @"/BaseFont"        : PDFName(@"/CourierNewPS-BoldMT"),
//                                    @"/Encoding"        : PDFName(@"/Identity-H"),
//                                    @"/DescendantFonts" : PDFArray(
//                                                            PDFRef(15, 0)
//                                                            ),
//                                    @"/ToUnicode"       : PDFRef(16, 0)
//                                    }))];
}

@end
