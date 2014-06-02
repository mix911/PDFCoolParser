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

@interface Parser_Tests : XCTestCase
{
    PDFLexicalAnalyzer *_pdfLexicalAnalyzer;
    NSData *_lexicalAnalyzerData;
    
    PDFSyntaxAnalyzer *_syntaxAnalyzer;
    NSData *_syntaxAnalyzerData;
}

@end

@implementation Parser_Tests

- (void)setUp
{
    [super setUp];
    
    _lexicalAnalyzerData = [[NSData alloc] initWithBytes:text length:sizeof(text)];
    _pdfLexicalAnalyzer = [[PDFLexicalAnalyzer alloc] initWithData:_lexicalAnalyzerData];
    
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
    
    NSUInteger len = 0;
    enum PDFLexemeTypes type = PDF_UNKNOWN_LEXEME;
    const char* lexeme = [_pdfLexicalAnalyzer nextLexeme:&len type:&type];
    
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
    [_pdfLexicalAnalyzer skipBytesByCount:5];
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
    PDFObject* tmpObj = [PDFObject pdfObjectWithValue:value objectNumber:objectNumber generatedNumber:generatedNumber];
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
    self subTestObject:326 :0 :[PDFValue dictionaryValue:
                                []]
    
    [self subTestObject:326
                       :0
                       :[PDFValue dictionaryValue:
                         [NSMutableDictionary dictionaryWithDictionary:@{
                                                                         @"/key1" : [PDFValue numberValue:@0],
                                                                         @"/key2" : [PDFValue hexStringValue:@"<aBc3>"],
                                                                         @"/key3" : [PDFValue stringValue:@"(Simple string)"],
                                                                         @"/key4" : [PDFValue nameValue:@"/Name"],
                                                                         @"/key5" : [PDFValue trueValue],
                                                                         @"/key6" : [PDFValue falseValue],
                                                                         @"/key7" : [PDFValue pdfRefValueWithObjectNumber:9 generatedNumber:3],
                                                                         @"/key8" : [PDFValue nullValue],
                                                                         @"/key9" : [PDFValue pdfRefValueWithObjectNumber:1 generatedNumber:2]
                                                                         }]]];
}

@end
