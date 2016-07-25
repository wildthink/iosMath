//
//  MTAsciiMathListBuilderText.m
//  iosMath
//
//  Created by Jakub Dolecki on 7/19/16.
//
//

@import XCTest;

#import "MTMathListBuilder.h"
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

- (void) testSqrtInSqrt
{
    NSString *str = @"\\sqrt\\sqrt2";
    MTMathList* list = [MTMathListBuilder buildFromString:str];
    NSString* desc = [NSString stringWithFormat:@"Error for string:%@", str];
    
    // convert it back to latex
    NSString* latex = [MTAsciiMathListBuilder mathListToString:list];
    XCTAssertEqualObjects(latex, @"sqrt(sqrt(2))", @"%@", desc);
}

- (void) testRad
{
    NSString *str = @"\\sqrt[3]2";
    MTMathList* list = [MTMathListBuilder buildFromString:str];
    
    // convert it back to latex
    NSString* latex = [MTAsciiMathListBuilder mathListToString:list];
    XCTAssertEqualObjects(latex, @"root(3)(2)");
}

- (void) testFrac
{
    NSString *str = @"\\frac1c";
    MTMathList* list = [MTMathListBuilder buildFromString:str];
    NSString* desc = [NSString stringWithFormat:@"Error for string:%@", str];
    
    // convert it back to latex
    NSString* latex = [MTAsciiMathListBuilder mathListToString:list];
    XCTAssertEqualObjects(latex, @"1/c", @"%@", desc);
}

- (void) testSymbols
{
    NSString *str = @"5\\times3^{2\\div2}";
    MTMathList* list = [MTMathListBuilder buildFromString:str];
    NSString* desc = [NSString stringWithFormat:@"Error for string:%@", str];
    
    // convert it back to latex
    NSString* latex = [MTAsciiMathListBuilder mathListToString:list];
    XCTAssertEqualObjects(latex, @"5*3^(2:2)", @"%@", desc);
}

- (void) testSuperScript
{
    NSString *str = @"a^{(b+4)^{2}}";
    MTMathList* list = [MTMathListBuilder buildFromString:str];
    NSString* desc = [NSString stringWithFormat:@"Error for string:%@", str];
    
    // convert it back to latex
    NSString* latex = [MTAsciiMathListBuilder mathListToString:list];
    XCTAssertEqualObjects(latex, @"a^((b+4)^(2))", @"%@", desc);
}

- (void) testSubScript
{
    NSString *str = @"2_{x^4}";
    MTMathList* list = [MTMathListBuilder buildFromString:str];
    NSString* desc = [NSString stringWithFormat:@"Error for string:%@", str];
    
    // convert it back to latex
    NSString* latex = [MTAsciiMathListBuilder mathListToString:list];
    XCTAssertEqualObjects(latex, @"2_(x^(4))", @"%@", desc);
}



@end