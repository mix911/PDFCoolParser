//
//  PDFLexicalAnalyzer.h
//  Parser
//
//  Created by demo on 13.05.14.
//  Copyright (c) 2014 Ptenster. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Типы лексем
 */
enum PDFLexemeTypes
{
    PDF_COMMENT_LEXEME_TYPE,            // Комментарий
    PDF_NUMBER_LEXEME_TYPE,             // Десятичное целое неотрицательное число
    PDF_STRING_LEXEME_TYPE,             // Строка
    PDF_HEX_STRING_LEXEME_TYPE,         // HEX строка
    PDF_OPEN_ARRAY_LEXEME_TYPE,         // Открывающая скобочка массива
    PDF_CLOSE_ARRAY_LEXEME_TYPE,        // Закрывающая скобочка массива
    PDF_OPEN_DICTIONARY_LEXEME_TYPE,    // Открывающая скобочка словаря
    PDF_CLOSE_DICTIONARY_LEXEME_TYPE,   // Закрывающая скобочка словаря
    PDF_NAME_LEXEME_TYPE,               // Имя
    PDF_OBJ_KEYWORD_LEXEME_TYPE,        // Ключевое слово obj
    PDF_ENDOBJ_KEYWORD_LEXEME_TYPE,     // Ключевое слово endobj
    PDF_XREF_KEYWORD_LEXEME_TYPE,       // Ключевое слово xref
    PDF_STARTXREF_KEYWORD_LEXEME_TYPE,  // Ключевое слово startxref
    PDF_STREAM_KEYWORD_LEXEME_TYPE,     // Ключевое слово stream
    PDF_ENDSTREAM_KEYWORD_LEXEME_TYPE,  // Ключевое слово endstream
    PDF_TRUE_KEYWORD_LEXEME_TYPE,       // Ключевое слово true
    PDF_FALSE_KEYWORD_LEXEME_TYPE,      // Ключевое слово false
    PDF_TRAILER_KEYWORD_LEXEME_TYPE,    // Ключевое слово trailer
    
    PDF_UNKNOWN_LEXEME,                 // Лексема неопределенного типа
};

/**
 * Лексический анализатор. Ожидаемые данные должны быть закодированны в ascii, каждый символ принимает значения в диапозоне 1..127. 
 * Данные должны оканчиваться байтом со значением 0.
 */
@interface PDFLexicalAnalyzer : NSObject

/**
 * Инициализация лексического анализатора.
 * @param data Ожидаемые данные должны быть закодированны в ascii, каждый символ принимает значения в диапозоне 1..127.
 * Данные должны оканчиваться байтом со значением 0.
 */
- (id)initWithData:(NSData*)data;

/**
 * Получение следующей лексемы. Должно вызыватся только после установки данных.
 * @param len параметр для получения длины лексемы. В случае лексической ошибки значение len будет 0.
 * @param type параметр для получения типа лексемы. Типы лексем определены в enum PDFLexemeTypes. В случае лексической ошибки значение type будет PDF_UNKNOWN_LEXEME.
 * @return const char* Лексема, длинны len и типа type.
 */
- (const char*)nextLexeme:(NSUInteger*)len type:(enum PDFLexemeTypes*)type;

/**
 * В сообщение о лексической ошибке.
 */
@property (readonly) NSString *errorMessage;

/**
 * Пропустить count байт. Метод нужен для того, чтобы пропускать содержимое stream'ов.
 * @param count Количество байт, которое нужно пропустить
 * @return BOOL YES - если удалось переместить количество на заданное количество байт, в противном случае NO.
 */
- (BOOL)skipBytesByCount:(NSUInteger)count;

@end
