//
//  MTMathConversionTest.m
//  iosMath
//
//  Created by Serdar Karatekin on 7/25/16.
//
//

#import <XCTest/XCTest.h>

#import "MTMathListBuilder.h"
#import "MTAsciiMathListBuilder.h"


@interface MTMathConversionTest : XCTestCase

@end

@implementation MTMathConversionTest

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

- (void) testSymbolsTwo
{
    NSString *str = @"42.0x\\times5.0-((54+22.2)/2)";
    MTMathList* list = [MTMathListBuilder buildFromString:str];
    NSString* desc = [NSString stringWithFormat:@"Error for string:%@", str];
    
    // convert it back to latex
    NSString* latex = [MTAsciiMathListBuilder mathListToString:list];
    XCTAssertEqualObjects(latex, @"42.0x*5.0-((54+22.2)/2)", @"%@", desc);
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

- (void) testProduct
{
    NSString *str = @"\\prod_a^b";
    MTMathList* list = [MTMathListBuilder buildFromString:str];
    NSString* desc = [NSString stringWithFormat:@"Error for string:%@", str];
    
    // convert it back to latex
    NSString* latex = [MTAsciiMathListBuilder mathListToString:list];
    // \prod ^{b}_{a}
    
    // ∏^(b)_(a)
    XCTAssertEqualObjects(latex, @"prod_(a)^(b)", @"%@", desc);
    
    
}



@end