//
//  MTAsciiMathListBuilderText.m
//  iosMath
//
//  Created by Jakub Dolecki on 7/19/16.
//
//

@import XCTest;

#import "MTAsciiMathListBuilder.h"

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

@end