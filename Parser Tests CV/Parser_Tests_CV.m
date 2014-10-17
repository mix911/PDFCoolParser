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

- (void)subTestObjectNoStream:(NSUInteger)objectNumber :(NSUInteger)generatedNumber :(NSObject*)object
{
    PDFValue* value = [PDFValue valueWithObject:object];
    PDFObject* srcObj = [_syntaxAnalyzer nextSyntaxObject];
    if (srcObj == nil) {
        XCTAssert(NO, @"Error: %@", _syntaxAnalyzer.errorMessage);
        return;
    }
    PDFObject* tmpObj = [PDFObject pdfObjectWithValue:value objectNumber:objectNumber generatedNumber:generatedNumber];
    XCTAssert([srcObj compairWithoutStream:tmpObj], @"");
}

- (void)subTestObject:(NSUInteger)objectNumber :(NSUInteger)generatedNumber :(NSObject*)object
{
    PDFValue *value = [PDFValue valueWithObject:object];
    PDFObject* srcObj = [_syntaxAnalyzer nextSyntaxObject];
    if (srcObj == nil) {
        XCTAssert(NO, @"Error: %@", _syntaxAnalyzer.errorMessage);
        return;
    }
    PDFObject* tmpObj = [PDFObject pdfObjectWithValue:value objectNumber:objectNumber generatedNumber:generatedNumber];
    XCTAssertEqualObjects(srcObj, tmpObj, @"");
}

- (void)subTestObject:(NSUInteger)objectNumber :(NSUInteger)generatedNumber :(NSObject*)object :(NSData*)stream
{
    PDFValue *value = [PDFValue valueWithObject:object];
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
                       :@{
                            @"/Type" : @"/Catalog",
                            @"/Pages": PDFRef(1, 0)
                        }];
    [self subTestObject:10
                       :0
                       :@{
                           @"/Type" : @"/Page",
                           @"/Parent" : PDFRef(1, 0),
                           @"/Resources" : @{
                                @"/ProcSets" : @[@"/PDF", @"/Text", @"/ImageB", @"/ImageC", @"/ImageI"],
                                @"/ExtGState" : @{ @"/G0" : PDFRef(11, 0) },
                                @"/Font" : @{ @"/F0" : PDFRef(12, 0), @"/F1" : PDFRef(13, 0) }
                              },
                           @"/MediaBox" : @[@(0), @(0), @(612), @(792)],
                           @"/Contents" : PDFRef(14, 0)
                        }];
    [self subTestObjectNoStream:14
                               :0
                               :@{
                                  @"/Filter" : @"/FlateDecode",
                                  @"/Length" : @6480
                                }];
    [self subTestObjectNoStream:11
                               :0
                               :@{
                                  @"/Type": @"/ExtGState",
                                  @"/CA"  : @(1),
                                  @"/ca"  : @(1),
                                  @"/LC"  : @(0),
                                  @"/LJ"  : @(0),
                                  @"/LW"  : @(0),
                                  @"/ML"  : @(4),
                                  @"/SA"  : PDFTrue,
                                  @"/BM"  : @"/Normal"
                                }];
    [self subTestObjectNoStream:12
                               :0
                               :@{
                                  @"/Type": @"/Font",
                                  @"/Subtype": @"/Type0",
                                  @"/BaseFont": @"/CourierNewPS-BoldMT",
                                  @"/Encoding": @"/Identity-H",
                                  @"/DescendantFonts": @[PDFRef(15, 0)],
                                  @"/ToUnicode": PDFRef(16, 0)
                                }];
    [self subTestObjectNoStream:13
                               :0
                               :@{
                                  @"/Type" : @"/Font",
                                  @"/Subtype" : @"/Type0",
                                  @"/BaseFont" : @"/CourierNewPSMT",
                                  @"/Encoding" : @"/Identity-H",
                                  @"/DescendantFonts" : @[PDFRef(17, 0)],
                                  @"/ToUnicode" : PDFRef(18, 0)
                                }];
    [self subTestObjectNoStream:15
                               :0
                               :@{
                                  @"/Type" : @"/Font",
                                  @"/FontDescriptor" : PDFRef(19, 0),
                                  @"/BaseFont" : @"/CourierNewPS-BoldMT",
                                  @"/Subtype" : @"/CIDFontType2",
                                  @"/CIDToGIDMap" : @"/Identity",
                                  @"/CIDSystemInfo" : @{
                                                        @"/Registry" : @"(Adobe)",
                                                        @"/Ordering" : @"(Identity)",
                                                        @"/Supplement" : @(0)
                                                       },
                                  @"/W" : @[ @(0), @[ @(600.0977) ] ]
                                }];
    [self subTestObjectNoStream:19
                               :0
                               :@{
                                  @"/Type" : @"/FontDescriptor",
                                  @"/FontFile2" : PDFRef(20, 0),
                                  @"/FontName" : @"/CourierNewPS-BoldMT",
                                  @"/Flags" : @(5),
                                  @"/Ascent" : @(832.5195),
                                  @"/Descent" : @(-300.293),
                                  @"/StemV" : @(160.1563),
                                  @"/CapHeight" : @(0),
                                  @"/ItalicAngle" : @(0),
                                  @"/FontBBox" : @[@(-46.3867), @(-710.4492), @(701.6602), @(1221.1914)]
                                }];
    [self subTestObjectNoStream:20 :0 :@{
                                         @"/Length1" : @(67560),
                                         @"/Filter" : @"/FlateDecode",
                                         @"/Length" : @(38260)
                                        }];
    [self subTestObjectNoStream:16 :0 :@{
                                         @"/Filter" : @"/FlateDecode",
                                         @"/Length" : @(410)
                                        }];
    [self subTestObjectNoStream:17 :0 :@{
                                         @"/Type" : @"/Font",
                                         @"/FontDescriptor" : PDFRef(21, 0),
                                         @"/BaseFont" : @"/CourierNewPSMT",
                                         @"/Subtype" : @"/CIDFontType2",
                                         @"/CIDToGIDMap" : @"/Identity",
                                         @"/CIDSystemInfo" : @{
                                                                @"/Registry" : @"(Adobe)",
                                                                @"/Ordering" : @"(Identity)",
                                                                @"/Supplement" : @(0)
                                                             },
                                         @"/W" : @[@(0), @[@(600.0977)]]
                                        }];
    [self subTestObjectNoStream:21 :0 :@{
                                         @"/Type" : @"/FontDescriptor",
                                         @"/FontFile2" : PDFRef(22, 0),
                                         @"/FontName" : @"/CourierNewPSMT",
                                         @"/Flags" : @(5),
                                         @"/Ascent" : @(832.5195),
                                         @"/Descent" : @(-300.293),
                                         @"/StemV" : @(120.6055),
                                         @"/CapHeight" : @(0),
                                         @"/ItalicAngle" : @(0),
                                         @"/FontBBox" : @[@(-21.4844), @(-679.6875), @(637.6953), @(1020.9961)]
                                        }];
    [self subTestObjectNoStream:22
                               :0
                               :@{
                                  @"/Length1" : @(62980),
                                  @"/Filter" : @"/FlateDecode",
                                  @"/Length" : @(34418)
                                }];
    [self subTestObjectNoStream:18
                               :0
                               :@{
                                  @"/Filter" : @"/FlateDecode",
                                  @"/Length" : @(406)
                                }];
    [self subTestObjectNoStream:2
                               :0
                               :@{
                                  @"/Type" : @"/Page",
                                  @"/Parent" : PDFRef(1, 0),
                                  @"/Resources" : @{
                                          @"/ProcSets" : @[@"/PDF", @"/Text", @"/ImageB", @"/ImageC", @"/ImageI"],
                                                    @"/ExtGState" : @{@"/G0" : PDFRef(11, 0)},
                                                    @"/Font" : @{
                                                                    @"/F0" : PDFRef(13, 0),
                                                                    @"/F1" : PDFRef(12, 0),
                                                                    @"/F2" : PDFRef(3, 0)
                                                                }
                                                  },
                                  @"/MediaBox" : @[@(0), @(0), @(612), @(792)],
                                  @"/Contents" : PDFRef(4, 0)
                                }];
    [self subTestObjectNoStream:1
                               :0
                               :@{
                                  @"/Type" : @"/Pages",
                                  @"/Count" : @(2),
                                  @"/Kids" : @[PDFRef(10, 0), PDFRef(2, 0)]
                                }];
    [self subTestObjectNoStream:4
                               :0
                               :@{
                                  @"/Filter" : @"/FlateDecode",
                                  @"/Length" : @(9596)
                                }];
    [self subTestObjectNoStream:3
                               :0
                               :@{
                                  @"/Type" : @"/Font",
                                  @"/Subtype" : @"/Type0",
                                  @"/BaseFont" : @"/Arial-BoldMT",
                                  @"/Encoding" : @"/Identity-H",
                                  @"/DescendantFonts" : @[PDFRef(5, 0)],
                                  @"/ToUnicode" : PDFRef(6, 0)
                                }];
    [self subTestObjectNoStream:5
                               :0
                               :@{
                                  @"/Type" : @"/Font",
                                  @"/FontDescriptor" : PDFRef(7, 0),
                                  @"/BaseFont" : @"/Arial-BoldMT",
                                  @"/Subtype" : @"/CIDFontType2",
                                  @"/CIDToGIDMap" : @"/Identity",
                                  @"/CIDSystemInfo" : @{
                                                            @"/Registry" : @"(Adobe)",
                                                            @"/Ordering" : @"(Identity)",
                                                            @"/Supplement" : @(0)
                                                    },
                                  @"/W" : @[@(0), @[@(750), @(0), @(0), @(277.832)]]
                                }];
    [self subTestObjectNoStream:7
                               :0
                               :@{
                                  @"/Type" : @"/FontDescriptor",
                                  @"/FontFile2" : PDFRef(8, 0),
                                  @"/FontName" : @"/Arial-BoldMT",
                                  @"/Flags" : @(6),
                                  @"/Ascent" : @(905.2734),
                                  @"/Descent" : @(-211.9141),
                                  @"/StemV" : @(137.207),
                                  @"/CapHeight" : @(715.8203),
                                  @"/ItalicAngle" : @(0),
                                  @"/FontBBox" : @[@(-627.9297), @(-376.4648), @(2033.6914), @(1047.8516)]
                                }];
    [self subTestObjectNoStream:8
                               :0
                               :@{
                                    @"/Length1" : @(30900),
                                    @"/Filter" : @"/FlateDecode",
                                    @"/Length" : @(12735)
                                }];
    [self subTestObjectNoStream:6
                               :0
                               :@{
                                    @"/Filter" : @"/FlateDecode",
                                    @"/Length" : @(224)
                                }];
}

@end
