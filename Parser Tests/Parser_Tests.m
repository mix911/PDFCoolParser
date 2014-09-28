//
//  Parser_Tests.m
//  Parser Tests
//
//  Created by demo on 16.05.14.
//  Copyright (c) 2014 Ptenster. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "PDFLexicalAnalyzer.h"
#import "PDFSyntaxAnalyzer.h"
#import "PDFObject.h"
#import "PDFRef.h"
#import "PDFXRefTable.h"
#import "PDFXRefSubSection.h"

static char text[] =    "(Hello world) ( This string has an end-of-line at the end of it .\r"
                        ")\r"
                        "( So does this one .\\n\\\\\\t\\(() )\r"
                        " ( \\0053 )\r \t\n"
                        "( \\053 )\r"
                        "( \\53 )\r"
                        "( \\0053)\r"
                        "( \\053)\r"
                        "( \\53)\r"
                        "(\\00531)\r"
                        "(\\0533)\r"
                        "(\\531)\r"
                        "(\\005313)\r"
                        "(\\05334)\r"
                        "(\\5315)\r"
                        "< 901FA3 >\r"
                        "< 901FA >\r"
                        "/Name1\r"
                        "/ASomewhatLongerName\r"
                        "/A;Name_With-Various***Characters?\r"
                        "/1.2\r"
                        "/$$\r"
                        "/@pattern\r"
                        "/The_Key_of_F#23_Minor\r"
                        "3<<obj 123 -1 -131 +2 +1000 1.2 .2 1. -1.2 -.2 -1. +1.2 +.2 +1. endobj>>[xref startxref]/end stream ???? endstream true false trailer R null";

static char sectionData[] = "0000000016 00000 n\r"
                            "0000001071 00000 n\r"
                            "0000001166 00000 n\r"
                            "0000003444 00000 n\r"
                            "0000003602 00000 n\r"
                            "0000003816 00000 n\r"
                            "0000004048 00000 n\r"
                            "0000004221 00000 n\r"
                            "0000004289 00000 n\r"
                            "0000004625 00000 n\r"
                            "0000007262 00000 n\r"
                            "0000008158 00000 n\r"
                            "0000008810 00000 n\r"
                            "0000009635 00000 n\r"
                            "0000010282 00000 n\r"
                            "0000010620 00000 n\r"
                            "0000011525 00000 n\r"
                            "0000012090 00000 n\r"
                            "0000012512 00000 n\r"
                            "0000013434 00000 n\r"
                            "0000018691 00000 n\r"
                            "0000019588 00000 n\r"
                            "0000020056 00000 n\r"
                            "0000020442 00000 n\r"
                            "0000020868 00000 n\r"
                            "0000021274 00000 n\r"
                            "0000030972 00000 n\r"
                            "0000031469 00000 n\r"
                            "0000031609 00000 n\r"
                            "0000031748 00000 n\r"
                            "0000040006 00000 n\r"
                            "0000045381 00000 n\r"
                            "0000053354 00000 n\r"
                            "0000053800 00000 n\r"
                            "0000001317 00000 n\r"
                            "0000003421 00000 n\r";

@interface Parser_Tests : XCTestCase
{
    PDFLexicalAnalyzer *_pdfLexicalAnalyzer;
    NSData *_lexicalAnalyzerData;
    struct pdf_lexical_analyzer_state _pdf_state;
    
    PDFSyntaxAnalyzer *_syntaxAnalyzer;
    NSData *_syntaxAnalyzerData;
}

@end

@implementation Parser_Tests

- (void)setUp
{
    [super setUp];
    
    _lexicalAnalyzerData = [[NSData alloc] initWithBytes:text length:sizeof(text)];
    _pdf_state.current = (char*)_lexicalAnalyzerData.bytes;
    _pdf_state.end = (char*)(_lexicalAnalyzerData.bytes + _lexicalAnalyzerData.length);
    _pdfLexicalAnalyzer = [[PDFLexicalAnalyzer alloc] init];
    
    _syntaxAnalyzerData = [NSData dataWithContentsOfFile:@"/Users/demo/Documents/Projects/PDFCoolParser/test_in.pdf"];
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

- (NSString*)pdfLexemeType2NSString:(enum PDFLexemeTypes)type
{
    switch (type) {
        case PDF_COMMENT_LEXEME_TYPE:
            return @"Comment";
        case PDF_NUMBER_LEXEME_TYPE:
            return @"Number";
        case PDF_INT_NUMBER_TYPE:
            return @"Integer";
        case PDF_UINT_NUMBER_TYPE:
            return @"Unsignet integer";
        case PDF_STRING_LEXEME_TYPE:
            return @"String";
        case PDF_HEX_STRING_LEXEME_TYPE:
            return @"HexString";
        case PDF_OPEN_ARRAY_LEXEME_TYPE:
            return @"Open array";
        case PDF_CLOSE_ARRAY_LEXEME_TYPE:
            return @"Close array";
        case PDF_OPEN_DICTIONARY_LEXEME_TYPE:
            return @"Open dictionary";
        case PDF_CLOSE_DICTIONARY_LEXEME_TYPE:
            return @"Close dictionary";
        case PDF_NAME_LEXEME_TYPE:
            return @"Name";
        case PDF_OBJ_KEYWORD_LEXEME_TYPE:
            return @"obj";
        case PDF_ENDOBJ_KEYWORD_LEXEME_TYPE:
            return @"endobj";
        case PDF_XREF_KEYWORD_LEXEME_TYPE:
            return @"xref";
        case PDF_STARTXREF_KEYWORD_LEXEME_TYPE:
            return @"startxref";
        case PDF_STREAM_KEYWORD_LEXEME_TYPE:
            return @"stream";
        case PDF_ENDSTREAM_KEYWORD_LEXEME_TYPE:
            return @"endstream";
        case PDF_TRUE_KEYWORD_LEXEME_TYPE:
            return @"true";
        case PDF_FALSE_KEYWORD_LEXEME_TYPE:
            return @"false";
        case PDF_TRAILER_KEYWORD_LEXEME_TYPE:
            return @"trailer";
        case PDF_R_KEYWORD_LEXEME:
            return @"R";
        case PDF_NULL_KEYWORD_LEXEME:
            return @"null";
        default:
            return @"Unknown";
    }
}

- (void)subTestLexicalAnalyzerLexeme:(const char*)checkedLexeme type:(enum PDFLexemeTypes)checkedType
{
    size_t checkedLen = strlen(checkedLexeme);
    
    const char* lexeme = [_pdfLexicalAnalyzer nextLexemeByState:&_pdf_state];
    NSUInteger len = _pdf_state.len;
    enum PDFLexemeTypes type = _pdf_state.current_type;
    
    if (checkedLen != len || strncmp(lexeme, checkedLexeme, len)) {
        char* buffer = malloc(len + 1);
        memcpy(buffer, lexeme, len);
        buffer[len] = 0;
        XCTAssert(NO, "Failed to parse '%s' vs '%s'", buffer, checkedLexeme);
    }
    XCTAssertEqual(type, checkedType, "Type error: %@ vs %@", [self pdfLexemeType2NSString:type], [self pdfLexemeType2NSString:checkedType]);
}

- (void)testLexicalAnalyzer
{
    [self subTestLexicalAnalyzerLexeme:"(Hello world)" type:PDF_STRING_LEXEME_TYPE];
    [self subTestLexicalAnalyzerLexeme:"( This string has an end-of-line at the end of it .\r)" type:PDF_STRING_LEXEME_TYPE];
    [self subTestLexicalAnalyzerLexeme:"( So does this one .\\n\\\\\\t\\(() )" type:PDF_STRING_LEXEME_TYPE];
    [self subTestLexicalAnalyzerLexeme:"( \\0053 )" type:PDF_STRING_LEXEME_TYPE];
    [self subTestLexicalAnalyzerLexeme:"( \\053 )" type:PDF_STRING_LEXEME_TYPE];
    [self subTestLexicalAnalyzerLexeme:"( \\53 )" type:PDF_STRING_LEXEME_TYPE];
    [self subTestLexicalAnalyzerLexeme:"( \\0053)" type:PDF_STRING_LEXEME_TYPE];
    [self subTestLexicalAnalyzerLexeme:"( \\053)" type:PDF_STRING_LEXEME_TYPE];
    [self subTestLexicalAnalyzerLexeme:"( \\53)" type:PDF_STRING_LEXEME_TYPE];
    [self subTestLexicalAnalyzerLexeme:"(\\00531)" type:PDF_STRING_LEXEME_TYPE];
    [self subTestLexicalAnalyzerLexeme:"(\\0533)" type:PDF_STRING_LEXEME_TYPE];
    [self subTestLexicalAnalyzerLexeme:"(\\531)" type:PDF_STRING_LEXEME_TYPE];
    [self subTestLexicalAnalyzerLexeme:"(\\005313)" type:PDF_STRING_LEXEME_TYPE];
    [self subTestLexicalAnalyzerLexeme:"(\\05334)" type:PDF_STRING_LEXEME_TYPE];
    [self subTestLexicalAnalyzerLexeme:"(\\5315)" type:PDF_STRING_LEXEME_TYPE];
    [self subTestLexicalAnalyzerLexeme:"< 901FA3 >" type:PDF_HEX_STRING_LEXEME_TYPE];
    [self subTestLexicalAnalyzerLexeme:"< 901FA >" type:PDF_HEX_STRING_LEXEME_TYPE];
    [self subTestLexicalAnalyzerLexeme:"/Name1" type:PDF_NAME_LEXEME_TYPE];
    [self subTestLexicalAnalyzerLexeme:"/ASomewhatLongerName" type:PDF_NAME_LEXEME_TYPE];
    [self subTestLexicalAnalyzerLexeme:"/A;Name_With-Various***Characters?" type:PDF_NAME_LEXEME_TYPE];
    [self subTestLexicalAnalyzerLexeme:"/1.2" type:PDF_NAME_LEXEME_TYPE];
    [self subTestLexicalAnalyzerLexeme:"/$$" type:PDF_NAME_LEXEME_TYPE];
    [self subTestLexicalAnalyzerLexeme:"/@pattern" type:PDF_NAME_LEXEME_TYPE];
    [self subTestLexicalAnalyzerLexeme:"/The_Key_of_F#23_Minor" type:PDF_NAME_LEXEME_TYPE];
    [self subTestLexicalAnalyzerLexeme:"3" type:PDF_UINT_NUMBER_TYPE];
    [self subTestLexicalAnalyzerLexeme:"<<" type:PDF_OPEN_DICTIONARY_LEXEME_TYPE];
    [self subTestLexicalAnalyzerLexeme:"obj" type:PDF_OBJ_KEYWORD_LEXEME_TYPE];
    [self subTestLexicalAnalyzerLexeme:"123" type:PDF_UINT_NUMBER_TYPE];
    [self subTestLexicalAnalyzerLexeme:"-1" type:PDF_INT_NUMBER_TYPE];
    [self subTestLexicalAnalyzerLexeme:"-131" type:PDF_INT_NUMBER_TYPE];
    [self subTestLexicalAnalyzerLexeme:"+2" type:PDF_UINT_NUMBER_TYPE];
    [self subTestLexicalAnalyzerLexeme:"+1000" type:PDF_UINT_NUMBER_TYPE];
    [self subTestLexicalAnalyzerLexeme:"1.2" type:PDF_NUMBER_LEXEME_TYPE];
    [self subTestLexicalAnalyzerLexeme:".2" type:PDF_NUMBER_LEXEME_TYPE];
    [self subTestLexicalAnalyzerLexeme:"1." type:PDF_NUMBER_LEXEME_TYPE];
    [self subTestLexicalAnalyzerLexeme:"-1.2" type:PDF_NUMBER_LEXEME_TYPE];
    [self subTestLexicalAnalyzerLexeme:"-.2" type:PDF_NUMBER_LEXEME_TYPE];
    [self subTestLexicalAnalyzerLexeme:"-1." type:PDF_NUMBER_LEXEME_TYPE];
    [self subTestLexicalAnalyzerLexeme:"+1.2" type:PDF_NUMBER_LEXEME_TYPE];
    [self subTestLexicalAnalyzerLexeme:"+.2" type:PDF_NUMBER_LEXEME_TYPE];
    [self subTestLexicalAnalyzerLexeme:"+1." type:PDF_NUMBER_LEXEME_TYPE];
    [self subTestLexicalAnalyzerLexeme:"endobj" type:PDF_ENDOBJ_KEYWORD_LEXEME_TYPE];
    [self subTestLexicalAnalyzerLexeme:">>" type:PDF_CLOSE_DICTIONARY_LEXEME_TYPE];
    [self subTestLexicalAnalyzerLexeme:"[" type:PDF_OPEN_ARRAY_LEXEME_TYPE];
    [self subTestLexicalAnalyzerLexeme:"xref" type:PDF_XREF_KEYWORD_LEXEME_TYPE];
    [self subTestLexicalAnalyzerLexeme:"startxref" type:PDF_STARTXREF_KEYWORD_LEXEME_TYPE];
    [self subTestLexicalAnalyzerLexeme:"]" type:PDF_CLOSE_ARRAY_LEXEME_TYPE];
    [self subTestLexicalAnalyzerLexeme:"/end" type:PDF_NAME_LEXEME_TYPE];
    [self subTestLexicalAnalyzerLexeme:"stream" type:PDF_STREAM_KEYWORD_LEXEME_TYPE];
    [_pdfLexicalAnalyzer skipBytesByCount:5 state:&_pdf_state];
    [self subTestLexicalAnalyzerLexeme:"endstream" type:PDF_ENDSTREAM_KEYWORD_LEXEME_TYPE];
    [self subTestLexicalAnalyzerLexeme:"true" type:PDF_TRUE_KEYWORD_LEXEME_TYPE];
    [self subTestLexicalAnalyzerLexeme:"false" type:PDF_FALSE_KEYWORD_LEXEME_TYPE];
    [self subTestLexicalAnalyzerLexeme:"trailer" type:PDF_TRAILER_KEYWORD_LEXEME_TYPE];
    [self subTestLexicalAnalyzerLexeme:"R" type:PDF_R_KEYWORD_LEXEME];
    [self subTestLexicalAnalyzerLexeme:"null" type:PDF_NULL_KEYWORD_LEXEME];
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

- (void)testSyntaxAnalyzer
{
    [self subTestComment:@"%PDF-1.4"];
    [self subTestComment:@"%Ã¢Ã£ÃÃ"];
    [self subTestObject:326 :0 :nil];
    [self subTestObject:326 :0 :[PDFValue numberValue:@123]];
    [self subTestObject:326 :0 :[PDFValue hexStringValue:@"<12aB>"]];
    [self subTestObject:326 :0 :[PDFValue stringValue:@"(333 () \\( )"]];
    [self subTestObject:326 :0 :[PDFValue pdfRefValueWithObjectNumber:2 generatedNumber:3]];
    [self subTestObject:326 :0 :[PDFValue falseValue]];
    [self subTestObject:326 :0 :[PDFValue trueValue]];
    [self subTestObject:326 :0 :[PDFValue nullValue]];
    [self subTestObject:326 :0 :[PDFValue arrayValue:[NSMutableArray arrayWithObjects:
                                                        [PDFValue numberValue:@1],
                                                        [PDFValue numberValue:@2],
                                                        [PDFValue numberValue:@3],
                                                        [PDFValue stringValue:@"(ololo)"],
                                                        [PDFValue numberValue:@(-4)],
                                                        [PDFValue trueValue],
                                                        [PDFValue falseValue],
                                                        nil]]];
    [self subTestObject:326 :0 :[PDFValue arrayValue:[NSMutableArray arrayWithObjects:
                                                      [PDFValue arrayValue:
                                                       [NSMutableArray arrayWithObjects:
                                                        [PDFValue nullValue],
                                                        [PDFValue numberValue:@3],
                                                        [PDFValue arrayValue:[NSMutableArray array]],
                                                        nil]],
                                                      [PDFValue numberValue:@1],
                                                      [PDFValue arrayValue:[NSMutableArray array]],
                                                      nil]]];
    [self subTestObject:326
                       :0
                       :[PDFValue dictionaryValue:
                         [NSMutableDictionary dictionaryWithDictionary:
                          @{
                            @"/key1" : [PDFValue pdfRefValueWithObjectNumber:1 generatedNumber:2],
                            @"/key3" : [PDFValue stringValue:@"(ololo)"],
                            @"/key2" : [PDFValue pdfRefValueWithObjectNumber:3 generatedNumber:4],
                            @"/key4" : [PDFValue hexStringValue:@"<abc3>"]
                            }]]];
    [self subTestObject:326
                       :0
                       :[PDFValue dictionaryValue:
                         [NSMutableDictionary dictionaryWithDictionary:
                          @{
                            @"/key1" : [PDFValue numberValue:@0]
                            }]]];
    [self subTestObject:326
                       :0
                       :[PDFValue dictionaryValue:
                         [NSMutableDictionary dictionaryWithDictionary:
                          @{
                            @"/key1" : [PDFValue numberValue:@1],
                            @"/key2" : [PDFValue numberValue:@2],
                            @"/key3" : [PDFValue pdfRefValueWithObjectNumber:3 generatedNumber:4],
                            @"/key4" : [PDFValue numberValue:@5]
                            }]]];
    [self subTestObject:326
                       :0
                       :[PDFValue dictionaryValue:
                         [NSMutableDictionary dictionaryWithDictionary:
                          @{
                            @"/key1" : [PDFValue dictionaryValue:
                                         [NSMutableDictionary dictionaryWithDictionary:
                                          @{
                                            @"/key1" : [PDFValue stringValue:@"(ololo)"],
                                            @"/key2" : [PDFValue arrayValue:[NSMutableArray arrayWithObjects:
                                                                             [PDFValue dictionaryValue:[NSMutableDictionary dictionary]],
                                                                             nil]]
                                            }]]
                            }]]];
    [self subTestObject:326
                       :0
                       :[PDFValue dictionaryValue:
                         [NSMutableDictionary dictionaryWithDictionary:
                          @{
                            @"/Length" : [PDFValue numberValue:@10]
                            }]]
                       :[NSData dataWithBytes:"1234567890" length:10]];
    [self subTestObject:325
                       :0
                       :[PDFValue dictionaryValue:
                         [NSMutableDictionary dictionaryWithDictionary:
                          @{
                            @"/Linearized" : [PDFValue numberValue:@1],
                            @"/O" : [PDFValue numberValue:@328],
                            @"/H" : [PDFValue arrayValue:
                                     [NSMutableArray arrayWithObjects:
                                      [PDFValue numberValue:@1317],
                                      [PDFValue numberValue:@2127],
                                      nil]],
                            @"/L" : [PDFValue numberValue:@1119433],
                            @"/E" : [PDFValue numberValue:@54084],
                            @"/N" : [PDFValue numberValue:@38],
                            @"/T" : [PDFValue numberValue:@1112814]
                            }]]];
    [self subTestXRefTable:[PDFXRefTable pdfXRefTableWithSubSections:
                            @[
                              [PDFXRefSubSection pdfXRefSectionWithFirstObjectNumber:325
                                                                 lastObjectNumber:36
                                                                             data:[NSData dataWithBytes:sectionData length:sizeof(sectionData)-1]]
                              ]]
                   trailer:@{
                             @"/Size" : [PDFValue numberValue:@361],
                             @"/Info" : [PDFValue pdfRefValueWithObjectNumber:316 generatedNumber:0],
                             @"/Root" : [PDFValue pdfRefValueWithObjectNumber:326 generatedNumber:0],
                             @"/Prev" : [PDFValue numberValue:@1112803],
                             @"/ID" : [PDFValue arrayValue:
                                       [NSMutableArray arrayWithObjects:
                                        [PDFValue hexStringValue:@"<7a6636ff523a802804b8359a7bb65124>"],
                                        [PDFValue hexStringValue:@"<3bc21a09cd84580eea4371ce34ffa70b>"],
                                        nil]]
                             }
                    offset:0];
    [self subTestObject:326
                       :0
                       :[PDFValue dictionaryValue:
                         [NSMutableDictionary dictionaryWithDictionary:
                          @{
                            @"/Type" : [PDFValue nameValue:@"/Catalog"],
                            @"/Pages" : [PDFValue pdfRefValueWithObjectNumber:315 generatedNumber:0],
                            @"/Metadata" : [PDFValue pdfRefValueWithObjectNumber:317 generatedNumber:0],
                            @"/AcroForm" : [PDFValue pdfRefValueWithObjectNumber:327 generatedNumber:0],
                            }]]];
    [self subTestObject:327
                       :0
                       :[PDFValue dictionaryValue:
                         [NSMutableDictionary dictionaryWithDictionary:
                          @{
                            @"/Fields" : [PDFValue arrayValue:[NSMutableArray array]],
                            @"/DR" : [PDFValue dictionaryValue:
                                      [NSMutableDictionary dictionaryWithDictionary:
                                       @{
                                         @"/Font" : [PDFValue dictionaryValue:
                                                     [NSMutableDictionary dictionaryWithDictionary:
                                                      @{
                                                        @"/ZaDb" : [PDFValue pdfRefValueWithObjectNumber:312 generatedNumber:0],
                                                        @"/Helv" : [PDFValue pdfRefValueWithObjectNumber:313 generatedNumber:0]
                                                        }]],
                                         @"/Encoding" : [PDFValue dictionaryValue:
                                                         [NSMutableDictionary dictionaryWithDictionary:
                                                          @{
                                                            @"/PDFDocEncoding" : [PDFValue pdfRefValueWithObjectNumber:314 generatedNumber:0]
                                                            }]]
                                         }]],
                            @"/DA" : [PDFValue stringValue:@"(/Helv 0 Tf 0 g )"]
                            }]]];
}

@end
