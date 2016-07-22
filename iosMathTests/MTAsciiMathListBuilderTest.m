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
    XCTAssertEqualObjects(atom.stringValue, @"∑^{\\inner[(]{5+x}[)]}_{0}", "Atom string value");
    
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

@end