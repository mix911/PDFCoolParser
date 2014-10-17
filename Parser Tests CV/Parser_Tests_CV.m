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
                                    PDFName(@"/ImageI")
                                ),
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
                                PDFNum(792)
                            ),
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
    [self subTestObjectNoStream:12
                               :0
                               :PDFDict((@{
                                    @"/Type": PDFName(@"/Font"),
                                    @"/Subtype": PDFName(@"/Type0"),
                                    @"/BaseFont": PDFName(@"/CourierNewPS-BoldMT"),
                                    @"/Encoding": PDFName(@"/Identity-H"),
                                    @"/DescendantFonts": PDFArray(PDFRef(15, 0)),
                                    @"/ToUnicode": PDFRef(16, 0)
                                }))];
    [self subTestObjectNoStream:13
                               :0
                               :PDFDict((@{
                                    @"/Type" : PDFName(@"/Font"),
                                    @"/Subtype" : PDFName(@"/Type0"),
                                    @"/BaseFont" : PDFName(@"/CourierNewPSMT"),
                                    @"/Encoding" : PDFName(@"/Identity-H"),
                                    @"/DescendantFonts" : PDFArray(PDFRef(17, 0)),
                                    @"/ToUnicode" : PDFRef(18, 0)
                                }))];
    [self subTestObjectNoStream:15
                               :0
                               :PDFDict((@{
                                           @"/Type" : PDFName(@"/Font"),
                                           @"/FontDescriptor" : PDFRef(19, 0),
                                           @"/BaseFont" : PDFName(@"/CourierNewPS-BoldMT"),
                                           @"/Subtype" : PDFName(@"/CIDFontType2"),
                                           @"/CIDToGIDMap" : PDFName(@"/Identity"),
                                           @"/CIDSystemInfo" : PDFDict((@{
                                                                          @"/Registry" : PDFStr(@"(Adobe)"),
                                                                          @"/Ordering" : PDFStr(@"(Identity)"),
                                                                          @"/Supplement" : PDFNum(0)
                                                                })),
                                           @"/W" : PDFArray(PDFNum(0), PDFArray(PDFNum(600.0977)))
                                }))];
    [self subTestObjectNoStream:19
                               :0
                               :PDFDict((@{
                                           @"/Type" : PDFName(@"/FontDescriptor"),
                                           @"/FontFile2" : PDFRef(20, 0),
                                           @"/FontName" : PDFName(@"/CourierNewPS-BoldMT"),
                                           @"/Flags" : PDFNum(5),
                                           @"/Ascent" : PDFNum(832.5195),
                                           @"/Descent" : PDFNum(-300.293),
                                           @"/StemV" : PDFNum(160.1563),
                                           @"/CapHeight" : PDFNum(0),
                                           @"/ItalicAngle" : PDFNum(0),
                                           @"/FontBBox" : PDFArray(PDFNum(-46.3867), PDFNum(-710.4492), PDFNum(701.6602), PDFNum(1221.1914))
                                }))];
    [self subTestObjectNoStream:20 :0 :PDFDict((@{
                                            @"/Length1" : PDFNum(67560),
                                            @"/Filter" : PDFName(@"/FlateDecode"),
                                            @"/Length" : PDFNum(38260)
                                        }))];
    [self subTestObjectNoStream:16 :0 :PDFDict((@{
                                            @"/Filter" : PDFName(@"/FlateDecode"),
                                            @"/Length" : PDFNum(410)
                                        }))];
    [self subTestObjectNoStream:17 :0 :PDFDict((@{
                                            @"/Type" : PDFName(@"/Font"),
                                            @"/FontDescriptor" : PDFRef(21, 0),
                                            @"/BaseFont" : PDFName(@"/CourierNewPSMT"),
                                            @"/Subtype" : PDFName(@"/CIDFontType2"),
                                            @"/CIDToGIDMap" : PDFName(@"/Identity"),
                                            @"/CIDSystemInfo" : PDFDict((@{
                                                                    @"/Registry" : PDFStr(@"(Adobe)"),
                                                                    @"/Ordering" : PDFStr(@"(Identity)"),
                                                                    @"/Supplement" : PDFNum(0)
                                                                })),
                                            @"/W" : PDFArray(PDFNum(0), PDFArray(PDFNum(600.0977)))
                                        }))];
    [self subTestObjectNoStream:21 :0 :PDFDict((@{
                                            @"/Type" : PDFName(@"/FontDescriptor"),
                                            @"/FontFile2" : PDFRef(22, 0),
                                            @"/FontName" : PDFName(@"/CourierNewPSMT"),
                                            @"/Flags" : PDFNum(5),
                                            @"/Ascent" : PDFNum(832.5195),
                                            @"/Descent" : PDFNum(-300.293),
                                            @"/StemV" : PDFNum(120.6055),
                                            @"/CapHeight" : PDFNum(0),
                                            @"/ItalicAngle" : PDFNum(0),
                                            @"/FontBBox" : PDFArray(PDFNum(-21.4844), PDFNum(-679.6875), PDFNum(637.6953), PDFNum(1020.9961))
                                        }))];
    [self subTestObjectNoStream:22
                               :0
                               :PDFDict((@{
                                    @"/Length1" : PDFNum(62980),
                                    @"/Filter" : PDFName(@"/FlateDecode"),
                                    @"/Length" : PDFNum(34418)
                                }))];
    [self subTestObjectNoStream:18
                               :0
                               :PDFDict((@{
                                           @"/Filter" : PDFName(@"/FlateDecode"),
                                           @"/Length" : PDFNum(406)
                                }))];
    [self subTestObjectNoStream:2
                               :0
                               :PDFDict((@{
                                    @"/Type" : PDFName(@"/Page"),
                                    @"/Parent" : PDFRef(1, 0),
                                    @"/Resources" : PDFDict((@{
                                                        @"/ProcSets" : PDFArray(PDFName(@"/PDF"), PDFName(@"/Text"), PDFName(@"/ImageB"), PDFName(@"/ImageC"), PDFName(@"/ImageI")),
                                                        @"/ExtGState" : PDFDict((@{@"/G0" : PDFRef(11, 0)})),
                                                        @"/Font" : PDFDict((@{
                                                                        @"/F0" : PDFRef(13, 0),
                                                                        @"/F1" : PDFRef(12, 0),
                                                                        @"/F2" : PDFRef(3, 0)
                                                                    }))
                                                    })),
                                    @"/MediaBox" : PDFArray(PDFNum(0), PDFNum(0), PDFNum(612), PDFNum(792)),
                                    @"/Contents" : PDFRef(4, 0)
                                }))];
    [self subTestObjectNoStream:1
                               :0
                               :PDFDict((@{
                                    @"/Type" : PDFName(@"/Pages"),
                                    @"/Count" : PDFNum(2),
                                    @"/Kids" : PDFArray(PDFRef(10, 0), PDFRef(2, 0))
                                }))];
    [self subTestObjectNoStream:4
                               :0
                               :PDFDict((@{
                                    @"/Filter" : PDFName(@"/FlateDecode"),
                                    @"/Length" : PDFNum(9596)
                                    }))];
    [self subTestObjectNoStream:3
                               :0
                               :PDFDict((@{
                                           @"/Type" : PDFName(@"/Font"),
                                           @"/Subtype" : PDFName(@"/Type0"),
                                           @"/BaseFont" : PDFName(@"/Arial-BoldMT"),
                                           @"/Encoding" : PDFName(@"/Identity-H"),
                                           @"/DescendantFonts" : PDFArray(PDFRef(5, 0)),
                                           @"/ToUnicode" : PDFRef(6, 0)
                                }))];
    [self subTestObjectNoStream:5
                               :0
                               :PDFDict((@{
                                    @"/Type" : PDFName(@"/Font"),
                                    @"/FontDescriptor" : PDFRef(7, 0),
                                    @"/BaseFont" : PDFName(@"/Arial-BoldMT"),
                                    @"/Subtype" : PDFName(@"/CIDFontType2"),
                                    @"/CIDToGIDMap" : PDFName(@"/Identity"),
                                    @"/CIDSystemInfo" : PDFDict((@{
                                                                   @"/Registry" : PDFStr(@"(Adobe)"),
                                                                   @"/Ordering" : PDFStr(@"(Identity)"),
                                                                   @"/Supplement" : PDFNum(0)
                                                        })),
                                    @"/W" : PDFArray(PDFNum(0), PDFArray(PDFNum(750), PDFNum(0), PDFNum(0), PDFNum(277.832)))
                                }))];
    [self subTestObjectNoStream:7
                               :0
                               :PDFDict((@{
                                    @"/Type" : PDFName(@"/FontDescriptor"),
                                    @"/FontFile2" : PDFRef(8, 0),
                                    @"/FontName" : PDFName(@"/Arial-BoldMT"),
                                    @"/Flags" : PDFNum(6),
                                    @"/Ascent" : PDFNum(905.2734),
                                    @"/Descent" : PDFNum(-211.9141),
                                    @"/StemV" : PDFNum(137.207),
                                    @"/CapHeight" : PDFNum(715.8203),
                                    @"/ItalicAngle" : PDFNum(0),
                                    @"/FontBBox" : PDFArray(PDFNum(-627.9297), PDFNum(-376.4648), PDFNum(2033.6914), PDFNum(1047.8516))
                                }))];
    [self subTestObjectNoStream:8
                               :0
                               :PDFDict((@{
                                    @"/Length1" : PDFNum(30900),
                                    @"/Filter" : PDFName(@"/FlateDecode"),
                                    @"/Length" : PDFNum(12735)
                                }))];
    [self subTestObjectNoStream:6
                               :0
                               :PDFDict((@{
                                    @"/Filter" : PDFName(@"/FlateDecode"),
                                    @"/Length" : PDFNum(224)
                                }))];
}

@end
