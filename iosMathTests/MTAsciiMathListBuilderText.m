//
//  MTAsciiMathListBuilderText.m
//  iosMath
//
//  Created by Jakub Dolecki on 7/19/16.
//
//

@import XCTest;

#import "MTAsciiMathListBuilder.h"
#import "MTMathListBuilder.h"

@interface MTAsciiMathListBuilderTest : XCTestCase

@end

@implementation MTAsciiMathListBuilderTest

- (void) testNumberParse
{
    NSString *str = @"42.0";
    MTMathList* list = [MTAsciiMathListBuilder buildFromString:str];
    MTMathList* finalized = list.finalized;
    XCTAssertEqualObjects(@(list.atoms.count), @4, @"Num atoms");
    XCTAssertEqualObjects(@(finalized.atoms.count), @1, @"Num atoms in finalized");
}

- (void) testNumberParse2
{
    NSString *str = @"53203";
    MTMathList* list = [MTAsciiMathListBuilder buildFromString:str];
    MTMathList* finalized = list.finalized;
    XCTAssertEqualObjects(@(list.atoms.count), @5, @"Num atoms");
    XCTAssertEqualObjects(@(finalized.atoms.count), @1, @"Num atoms in finalized");
}

- (void) testSimpleCommand
{
    NSString *str = @"*";
    MTMathList* list = [MTAsciiMathListBuilder buildFromString:str];
    MTMathList* finalized = list.finalized;
    XCTAssertEqualObjects(@(list.atoms.count), @1, @"Num atoms");
    XCTAssertEqualObjects(@(finalized.atoms.count), @1, @"Num atoms in finalized");
}

- (void) testMoreComplicatedCommand
{
    NSString *str = @"**";
    MTMathList* list = [MTAsciiMathListBuilder buildFromString:str];
    MTMathList* finalized = list.finalized;
    XCTAssertEqualObjects(@(list.atoms.count), @1, @"Num atoms");
    XCTAssertEqualObjects(@(finalized.atoms.count), @1, @"Num atoms in finalized");
}

// MARK - MathList to AsciiMath conversion

- (void) testSqrt
{
    // Build a math list from latex
    NSString *str = @"\\sqrt2";
    MTMathList *list = [MTMathListBuilder buildFromString:str];
    NSString* desc = [NSString stringWithFormat:@"Error for string:%@", str];
    
    // Convert it back to Ascii Math and check
    NSString *asciiMath = [MTAsciiMathListBuilder mathListToString:list];
    XCTAssertEqualObjects(asciiMath, @"sqrt(2)", @"%@", desc);
}


@end