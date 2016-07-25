//
//  MTAsciiMathListBuilderTest.m
//  iosMath
//
//  Created by Jakub Dolecki on 7/19/16.
//
//

@import XCTest;

#import "MTFontManager.h"
#import "MTTypesetter.h"
#import "MTMathListBuilder.h"
#import "MTAsciiMathListBuilder.h"

@interface MTAsciiMathListBuilderTest : XCTestCase

@property (nonatomic) MTFont* font;

@end

@implementation MTAsciiMathListBuilderTest

- (void)setUp {
    [super setUp];
    self.font = MTFontManager.fontManager.defaultFont;
}

/**
    Test parsing of numbers.
 */
- (void) testNumberParse
{
    NSString *str = @"42.0";
    MTMathList* list = [MTAsciiMathListBuilder buildFromString:str];
    MTMathList* finalized = list.finalized;
    XCTAssertEqualObjects(@(list.atoms.count), @1, @"Num atoms");
    XCTAssertEqualObjects(@(finalized.atoms.count), @1, @"Num atoms in finalized");
}

/**
    Test parsing of a very simple command.
 */
- (void) testSimpleCommand
{
    NSString *str = @"*";
    MTMathList* list = [MTAsciiMathListBuilder buildFromString:str];
    MTMathList* finalized = list.finalized;
    XCTAssertEqualObjects(@(list.atoms.count), @1, @"Num atoms");
    XCTAssertEqualObjects(@(finalized.atoms.count), @1, @"Num atoms in finalized");
    
    MTMathAtom* atom = list.atoms[0];
    XCTAssertEqualObjects(atom.stringValue, @"\u22C5", "Atom string value");
}

/**
    Test that we correctly get a command that includes another command as a substring. In this case, another command under "*" exists.
 */
- (void) testCommandThatIsSupersetOfAnotherCommand
{
    NSString *str = @"**";
    MTMathList* list = [MTAsciiMathListBuilder buildFromString:str];
    MTMathList* finalized = list.finalized;
    XCTAssertEqualObjects(@(list.atoms.count), @1, @"Num atoms");
    XCTAssertEqualObjects(@(finalized.atoms.count), @1, @"Num atoms in finalized");
    
    MTMathAtom* atom = list.atoms[0];
    XCTAssertEqualObjects(atom.stringValue, @"\u2217", "Atom string value");
}

- (void) testParsingOfACombinationOfNumbersAndCommand
{
    NSString *toParse = @"42.0x * 5.0";
    MTMathList* list = [MTAsciiMathListBuilder buildFromString:toParse];
    XCTAssertEqualObjects(@(list.atoms.count), @4, @"Num atoms");
    
    MTMathList* finalized = list.finalized;
    XCTAssertEqualObjects(@(finalized.atoms.count), @4, @"Num atoms in finalized");
}

- (void) testSumCommand
{
    NSString *toParse = @"sum_0^oo";
    MTMathList* list = [MTAsciiMathListBuilder buildFromString:toParse];
    XCTAssertEqualObjects(@(list.atoms.count), @1, @"Num atoms");
    
    MTMathList* finalized = list.finalized;
    XCTAssertEqualObjects(@(finalized.atoms.count), @1, @"Num atoms in finalized");
    
    MTMathAtom* atom = list.atoms[0];
    XCTAssertEqualObjects(atom.stringValue, @"∑^{∞}_{0}", "Atom string value");
}

- (void) testBrackets
{
    NSString *toParse = @"sum_0^(5+x)";
    MTMathList* list = [MTAsciiMathListBuilder buildFromString:toParse];
    XCTAssertEqualObjects(@(list.atoms.count), @1, @"Num atoms");
    
    MTMathList* finalized = list.finalized;
    XCTAssertEqualObjects(@(finalized.atoms.count), @1, @"Num atoms in finalized");
    
    MTMathAtom* atom = list.atoms[0];
    XCTAssertEqualObjects(atom.stringValue, @"∑^{5+x}_{0}", "Atom string value");
    
    MTMathListDisplay* display = [MTTypesetter createLineForMathList:list.finalized font:self.font style:kMTLineStyleDisplay textColor:[UIColor blackColor]];
    XCTAssertNotNil(display);
}

- (void) testRadical
{
    NSString *toParse = @"sqrt5+x";
    MTMathList* list = [MTAsciiMathListBuilder buildFromString:toParse];
    XCTAssertEqualObjects(@(list.atoms.count), @3, @"Num atoms");
    
    MTMathList* finalized = list.finalized;
    XCTAssertEqualObjects(@(finalized.atoms.count), @3, @"Num atoms in finalized");
    
    XCTAssertEqualObjects(list.stringValue, @"\\sqrt{5}+x", "Atom string value");
    
    MTMathListDisplay* display = [MTTypesetter createLineForMathList:list.finalized font:self.font style:kMTLineStyleDisplay textColor:[UIColor blackColor]];
    XCTAssertNotNil(display);
}

- (void) testRadicalWithDecimalAndVariables
{
    NSString *toParse = @"sqrt5.0x+x";
    MTMathList* list = [MTAsciiMathListBuilder buildFromString:toParse];
    XCTAssertEqualObjects(@(list.atoms.count), @4, @"Num atoms");
    
    MTMathList* finalized = list.finalized;
    XCTAssertEqualObjects(@(finalized.atoms.count), @4, @"Num atoms in finalized");
    
    XCTAssertEqualObjects(list.stringValue, @"\\sqrt{5.0}x+x", "Atom string value");
    
    MTMathListDisplay* display = [MTTypesetter createLineForMathList:list.finalized font:self.font style:kMTLineStyleDisplay textColor:[UIColor blackColor]];
    XCTAssertNotNil(display);
}

- (void) testRadicalWithRootcommand
{
    NSString *toParse = @"root5.0x+x";
    MTMathList* list = [MTAsciiMathListBuilder buildFromString:toParse];
    XCTAssertEqualObjects(@(list.atoms.count), @3, @"Num atoms");
    
    MTMathList* finalized = list.finalized;
    XCTAssertEqualObjects(@(finalized.atoms.count), @3, @"Num atoms in finalized");
    
    XCTAssertEqualObjects(list.stringValue, @"\\sqrt[5.0]{x}+x", "Atom string value");
    
    MTMathListDisplay* display = [MTTypesetter createLineForMathList:list.finalized font:self.font style:kMTLineStyleDisplay textColor:[UIColor blackColor]];
    XCTAssertNotNil(display);
}

- (void) testNestedParens
{
    NSString *toParse = @"(2-4) * {:5x - <<2+sqrt2x>>:}";
    MTMathList* list = [MTAsciiMathListBuilder buildFromString:toParse];
    XCTAssertEqualObjects(@(list.atoms.count), @3, @"Num atoms");
    
    MTMathList* finalized = list.finalized;
    XCTAssertEqualObjects(@(finalized.atoms.count), @3, @"Num atoms in finalized");
    
    MTMathListDisplay* display = [MTTypesetter createLineForMathList:list.finalized font:self.font style:kMTLineStyleDisplay textColor:[UIColor blackColor]];
    XCTAssertNotNil(display);
}

- (void) testFraction
{
    NSString *toParse = @"21*rootx10/(2x)";
    MTMathList* list = [MTAsciiMathListBuilder buildFromString:toParse];
    XCTAssertEqualObjects(@(list.atoms.count), @3, @"Num atoms");
    
    MTMathList* finalized = list.finalized;
    XCTAssertEqualObjects(@(finalized.atoms.count), @3, @"Num atoms in finalized");
    
    MTMathListDisplay* display = [MTTypesetter createLineForMathList:list.finalized font:self.font style:kMTLineStyleDisplay textColor:[UIColor blackColor]];
    XCTAssertNotNil(display);
}

- (void) testComplicated
{
    NSString *toParse = @"sum_(i=1)^n i^3=((n(n+1))/2)^2";
    MTMathList* list = [MTAsciiMathListBuilder buildFromString:toParse];
    XCTAssertEqualObjects(@(list.atoms.count), @4, @"Num atoms");
    
    MTMathList* finalized = list.finalized;
    XCTAssertEqualObjects(@(finalized.atoms.count), @4, @"Num atoms in finalized");
    
    MTMathListDisplay* display = [MTTypesetter createLineForMathList:list.finalized font:self.font style:kMTLineStyleDisplay textColor:[UIColor blackColor]];
    XCTAssertNotNil(display);
}

- (void) testIntegral
{
//    \\int_{-\\infty}^\\infty e^{-x^2} dx = \\sqrt{\\pi}
    NSString *toParse = @"int_0^ooe^(-x^2)dx = sqrtpi";
    MTMathList* list = [MTAsciiMathListBuilder buildFromString:toParse];
    XCTAssertEqualObjects(@(list.atoms.count), @6, @"Num atoms");
    
    MTMathList* finalized = list.finalized;
    XCTAssertEqualObjects(@(finalized.atoms.count), @6, @"Num atoms in finalized");
    
    MTMathListDisplay* display = [MTTypesetter createLineForMathList:list.finalized font:self.font style:kMTLineStyleDisplay textColor:[UIColor blackColor]];
    XCTAssertNotNil(display);
}

- (void) testFracCommand
{
    NSString *toParse = @"frac1x";
    MTMathList* list = [MTAsciiMathListBuilder buildFromString:toParse];
    XCTAssertEqualObjects(@(list.atoms.count), @1, @"Num atoms");
    
    MTMathList* finalized = list.finalized;
    XCTAssertEqualObjects(@(finalized.atoms.count), @1, @"Num atoms in finalized");
    
    MTMathListDisplay* display = [MTTypesetter createLineForMathList:list.finalized font:self.font style:kMTLineStyleDisplay textColor:[UIColor blackColor]];
    XCTAssertNotNil(display);
}

- (void) testLimitCommand {
    NSString *toParse = @"lim_(1->oo)";
    MTMathList* list = [MTAsciiMathListBuilder buildFromString:toParse];
    XCTAssertEqualObjects(@(list.atoms.count), @1, @"Num atoms");
    
    MTMathList* finalized = list.finalized;
    XCTAssertEqualObjects(@(finalized.atoms.count), @1, @"Num atoms in finalized");
    
    NSString *latexToParse = @"\\lim_{x\\to\\infty}";
    MTMathList* latexList = [MTMathListBuilder buildFromString:latexToParse];
    
    MTMathListDisplay* display = [MTTypesetter createLineForMathList:list.finalized font:self.font style:kMTLineStyleDisplay textColor:[UIColor blackColor]];
    XCTAssertNotNil(display);
}

- (void) testSinCommand {
    NSString *toParse = @"sin(30) + 10";
    MTMathList* list = [MTAsciiMathListBuilder buildFromString:toParse];
    XCTAssertEqualObjects(@(list.atoms.count), @4, @"Num atoms");
    
    NSString *latexToParse = @"\\sin(30) + 10";
    MTMathList* latexList = [MTMathListBuilder buildFromString:latexToParse];
    
    MTMathList* finalized = list.finalized;
    XCTAssertEqualObjects(@(finalized.atoms.count), @4, @"Num atoms in finalized");
    
    MTMathListDisplay* display = [MTTypesetter createLineForMathList:list.finalized font:self.font style:kMTLineStyleDisplay textColor:[UIColor blackColor]];
    XCTAssertNotNil(display);
    
    MTMathListDisplay* latexDisplay = [MTTypesetter createLineForMathList:latexList.finalized font:self.font style:kMTLineStyleDisplay textColor:[UIColor blackColor]];
    XCTAssertNotNil(latexDisplay);
}

- (void) testComplicatedParens {
//    (1/(2x*(2x/2)))(2x)
    NSString *toParse = @"(1/(2x*(2x/2)))(2x)";
    MTMathList* list = [MTAsciiMathListBuilder buildFromString:toParse];
    XCTAssertEqualObjects(@(list.atoms.count), @2, @"Num atoms");
    
    NSString *latexToParse = @"\\sin(30) + 10";
    MTMathList* latexList = [MTMathListBuilder buildFromString:latexToParse];
    
    MTMathList* finalized = list.finalized;
    XCTAssertEqualObjects(@(finalized.atoms.count), @2, @"Num atoms in finalized");
    
    MTMathListDisplay* display = [MTTypesetter createLineForMathList:list.finalized font:self.font style:kMTLineStyleDisplay textColor:[UIColor blackColor]];
    XCTAssertNotNil(display);
    
    MTMathListDisplay* latexDisplay = [MTTypesetter createLineForMathList:latexList.finalized font:self.font style:kMTLineStyleDisplay textColor:[UIColor blackColor]];
    XCTAssertNotNil(latexDisplay);
}

@end