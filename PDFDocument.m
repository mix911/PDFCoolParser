//
//  PDFDocument.m
//  Parser
//
//  Created by Aliona on 10.05.14.
//  Copyright (c) 2014 Ptenster. All rights reserved.
//

#import "PDFDocument.h"

#import "PDFLexicalAnalyzer.h"
#import "PDFComment.h"
#import "PDFObject.h"
#import "PDFXRex.h"

#define ReturnError(state, message)\
    {\
        _errorMessage = message;\
        return state;\
    }

#define ErrorState(message)\
    {\
        _errorMessage = message;\
        state = ERROR_STATE;\
    }

enum ParserStates {
    ERROR_STATE = -1,
    IN_PDF_HEADER_STATE = 0,
    IN_PDF_BODY_STATE,
    IN_XREF_HEADER_STATE,
    IN_OBJECT_HEADER_WAIT_SECOND_NUMBER_STATE,
    IN_OBJECT_HEADER_WAIT_WORD_OBJ_STATE,
    IN_OBJECT_BODY_STATE,
    IN_DICTIONARY_WAIT_KEY_STATE,
    IN_DICTIONARY_WAIT_VALUE_STATE,
    IN_OBJECT_WAIT_END_STATE,
};

static int isLexemeComment(const char* lexeme)
{
    return lexeme && lexeme[0]=='%';
}

static int isLexemeNumber(const char* lexeme, NSUInteger len)
{
    NSUInteger i = 0;
    for (; i < len; ++i) {
        if (isnumber(lexeme[i])) {
            break;
        }
    }
    return i == len;
}

static int isLexemeName(const char* lexeme)
{
    return lexeme && lexeme[0] == '\\';
}

const char* strblock(const char* p, int(^func)(char ch))
{
    for (; *p && func(*p); ++p) {
    }
    return p;
}

@interface PDFDocument()
{
    NSMutableArray *_pdfNodes;
}
@end

@implementation PDFDocument

- (id)initWithData:(NSData*)data
{
    if (self = [super init]) {
        _version = @"";
        _pdfNodes = [[NSMutableArray alloc] init];
        
        [self parseData:data];
        
        return self;
    }
    return nil;
}

- (NSString*)version
{
    return _version;
}

- (NSString*)errorMessage
{
    return _errorMessage;
}

- (void)parseData:(NSData*)data
{
    enum ParserStates state = IN_PDF_HEADER_STATE;
    enum PDFLexemeTypes type = PDF_UNKNOWN_LEXEME;
    
    PDFLexicalAnalyzer *pdfLexicalAnalyzer = [[PDFLexicalAnalyzer alloc] initWithData:data];
    NSUInteger len = 0;
    
    PDFObject *pdfObject = [PDFObject new];
    NSString *key = @"";
    
    for (const char *lexeme = [pdfLexicalAnalyzer nextLexeme:&len type:&type]; lexeme && state != ERROR_STATE; lexeme = [pdfLexicalAnalyzer nextLexeme:&len type:&type]) {
        
        switch (state) {
            case IN_PDF_HEADER_STATE:
                // Это коментарий
                if (isLexemeComment(lexeme)) {
                    state = [self parseVersionInLexeme:lexeme len:len];
                } else {
                    ErrorState(@"PDF version not found");
                }
                break;
                
            case IN_PDF_BODY_STATE:
                if (isLexemeComment(lexeme)) {
                    [_pdfNodes addObject:[[PDFComment alloc] initWithString:[NSData dataWithBytes:lexeme length:len]]];
                } else if (len == 4 && strncmp(lexeme, "xref", len) == 0) {
                    state = IN_XREF_HEADER_STATE;
                } else if (isLexemeNumber(lexeme, len)) {
                    state = IN_OBJECT_HEADER_WAIT_SECOND_NUMBER_STATE;
                    pdfObject.firstNumber = [self lexemeToNSNumber:lexeme len:len];
                } else {
                    ErrorState(@"Brocken pdf body");
                }
                break;
                
            case IN_XREF_HEADER_STATE:
                break;
                
            case IN_OBJECT_HEADER_WAIT_SECOND_NUMBER_STATE:
                if (isLexemeNumber(lexeme, len)) {
                    pdfObject.secondNumber = [self lexemeToNSNumber:lexeme len:len];
                    state = IN_OBJECT_HEADER_WAIT_WORD_OBJ_STATE;
                } else {
                    ErrorState(@"Failed to read second number in object's header");
                }
                break;
                
            case IN_OBJECT_HEADER_WAIT_WORD_OBJ_STATE:
                if (len == 3 && strncmp(lexeme, "obj", len) == 0) {
                    state = IN_OBJECT_BODY_STATE;
                } else {
                    ErrorState(@"World 'obj' not founded");
                }
                break;
                
            case IN_OBJECT_BODY_STATE:
                if (len == 2 && strncmp(lexeme, "<<", len) == 0) {
                    pdfObject.value = [NSMutableDictionary dictionary];
                    state = IN_DICTIONARY_WAIT_KEY_STATE;
                } else if (isLexemeNumber(lexeme, len)) {
                    pdfObject.value = [NSNumber numberWithInteger:[self lexemeToNSNumber:lexeme len:len]];
                    state = IN_OBJECT_WAIT_END_STATE;
                } 
                else {
                    ErrorState(@"Unknown object type");
                }
                break;
                
            case IN_OBJECT_WAIT_END_STATE:
                if (len == 6 && strncmp(lexeme, "endobj", len) == 0) {
                    NSLog(@"%@", pdfObject);
                    state = IN_PDF_BODY_STATE;
                    [pdfObject release];
                    pdfObject = [PDFObject new];
                } else {
                    ErrorState(@"Word endobj not found");
                }
                break;
                
            case IN_DICTIONARY_WAIT_KEY_STATE:
                if (isLexemeName(lexeme)) {
                    key = [[NSString alloc] initWithData:[NSData dataWithBytes:lexeme length:len] encoding:NSASCIIStringEncoding];
                    state = IN_DICTIONARY_WAIT_VALUE_STATE;
                } else {
                    ErrorState(@"Bad key type");
                }
                break;
                
            case IN_DICTIONARY_WAIT_VALUE_STATE:
                if (isLexemeNumber(lexeme, len)) {
                    ((NSMutableDictionary*)pdfObject.value)[key] = [NSNumber numberWithInteger:[self lexemeToNSNumber:lexeme len:len]];
                    state = IN_DICTIONARY_WAIT_KEY_STATE;
                }
                break;
                
            default:
                break;
        }
    }
}

- (NSUInteger)lexemeToNSNumber:(const char*)lexeme len:(NSUInteger)len
{
    return [[[NSString alloc] initWithData:[NSData dataWithBytes:lexeme length:len] encoding:NSASCIIStringEncoding] integerValue];
}

- (enum ParserStates)parseVersionInLexeme:(const char *)lexeme len:(NSUInteger)len
{
    if (len < 5) {
        ReturnError(ERROR_STATE, @"Failed to parse pdf header");
    }
    
    if (strncmp("%PDF-", lexeme, 5)) {
        ReturnError(ERROR_STATE, @"Failed to parse pdf header");
    }
    
    lexeme += 5;
    len -= 5;
    
    _version = [[NSString alloc] initWithData:[NSData dataWithBytes:lexeme length:len] encoding:NSASCIIStringEncoding];
    
    return IN_PDF_BODY_STATE;
}

@end

#undef ReturnError
#undef ErrorState