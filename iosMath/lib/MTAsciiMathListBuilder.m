//
//  MTAsciiMathListBuilder.m
//  iosMath
//
//  Created by Jakub Dolecki on 7/19/16.
//
//
// https://github.com/mathjax/MathJax/blob/master/unpacked/jax/input/AsciiMath/jax.js

#import "MTAsciiMathListBuilder.h"
#import "MTMathAtomFactory.h"

//NSString *const MTParseError = @"ParseError";

@implementation MTAsciiMathListBuilder {
    unichar* _chars;
    int _currentChar;
    NSUInteger _length;
    MTInner* _currentInnerAtom;
}

- (instancetype)initWithString:(NSString *)str
{
    self = [super init];
    if (self) {
        _error = nil;
        _chars = malloc(sizeof(unichar)*str.length);
        _length = str.length;
        [str getCharacters:_chars range:NSMakeRange(0, str.length)];
        _currentChar = 0;
    }
    return self;
}

- (void)dealloc
{
    free(_chars);
}

- (BOOL) hasCharacters
{
    return _currentChar < _length;
}

// gets the next character and moves the pointer ahead
- (unichar) getNextCharacter
{
    NSAssert([self hasCharacters], @"Retrieving character at index %d beyond length %lu", _currentChar, (unsigned long)_length);
    return _chars[_currentChar++];
}

- (void) unlookCharacter
{
    NSAssert(_currentChar > 0, @"Unlooking when at the first character.");
    _currentChar--;
}

- (MTMathList *)build
{
    MTMathList* list = [self buildInternal:false];
    if ([self hasCharacters] && !_error) {
        // something went wrong most likely braces mismatched
        NSString* errorMessage = [NSString stringWithFormat:@"Mismatched braces: %@", [NSString stringWithCharacters:_chars length:_length]];
//        [self setError:MTParseErrorMismatchBraces message:errorMessage];
    }
    if (_error) {
        return nil;
    }
    return list;
}

- (MTMathList*) buildInternal:(BOOL) oneCharOnly
{
    return [self buildInternal:oneCharOnly stopChar:0];
}

- (MTMathList*)buildInternal:(BOOL) oneCharOnly stopChar:(unichar) stop
{
    MTMathList* list = [MTMathList new];
    NSAssert(!(oneCharOnly && (stop > 0)), @"Cannot set both oneCharOnly and stopChar.");
    MTMathAtom* prevAtom = nil;
    
    while([self hasCharacters]) {
        if (_error) {
            // If there is an error thus far then bail out.
            return nil;
        }
        MTMathAtom* atom = nil;
        unichar ch = [self getNextCharacter];
        
        // If there is a stop character, keep scanning till we find it
        if (stop > 0 && ch == stop) {
            return list;
        }
        
        if (ch == '\\' || ch <= 32) {
            continue;
        }
        
        // If not a number
        if (ch == '.' || (ch >= 48 && ch <= 57)) {
            atom = [MTMathAtomFactory atomForCharacter:ch];
            if (!atom) {
                // Not a recognized character
                continue;
            }
        }
        else {
            [self unlookCharacter];
            atom = [self scanForConstant];
        }
        
        NSAssert(atom != nil, @"Atom shouldn't be nil");
        [list addAtom:atom];
        prevAtom = atom;
        
        if (oneCharOnly) {
            // we consumed our onechar
            return list;
        }
    }
    return list;
}

- (MTMathAtom*) scanForConstant
{
    NSMutableString* symbol = [NSMutableString string];
    NSUInteger j = 0;
    NSUInteger k = 0;
    
    NSArray* sortedCommands = [self sortedCommands];
    BOOL more = YES;
    while([self hasCharacters] && more == YES) {
        unichar ch = [self getNextCharacter];
        [symbol appendString:[NSString stringWithCharacters:&ch length:1]];
        
        j = k;
        k = [self positionOfString:symbol inSortedArray:sortedCommands postIndex:j];
        if (k >= sortedCommands.count) {
            continue;
        }
        
        NSString* foundCommand = sortedCommands[k];
        NSString* peeked = [self peekN:foundCommand.length - symbol.length];
        NSString* full = [NSString stringWithFormat:@"%@%@",symbol,peeked];
        BOOL areEqual = [foundCommand isEqualToString:full];
        if (k < sortedCommands.count && areEqual == YES) {
            return [[MTAsciiMathListBuilder supportedCommands] objectForKey:foundCommand];
        }
    }
    
    return nil;
}

- (NSString*) peekN:(NSUInteger)n {
    NSMutableString* accumulated = [NSMutableString string];
    
    for (int i = _currentChar; i < _length && i < _currentChar + n; i++) {
        unichar ch = _chars[i];
        [accumulated appendString:[NSString stringWithCharacters:&ch length:1]];
    }
    
    return accumulated;
}

/**
    Return position >=index where str appears or would be inserted assumes array is sorted
 */
- (NSUInteger) positionOfString:(NSString*) str inSortedArray:(NSArray*) array postIndex:(NSUInteger) index
{
    
    if (index == 0) {
        // binary search
        index = -1;
        NSUInteger h = array.count;
        NSUInteger m;
        
        while (index + 1 < h) {
            m = (index + h) >> 1;
            
            if (array[m] > str) {
                index = m;
            } else {
                h = m;
            }
        }
        
        return h;
    } else {
        NSUInteger i;
        for (i = index; i < array.count && array[i] < str; i++) {};
        return i;
    }
}

- (NSArray*) sortedCommands
{
    NSDictionary* supportedCommands = [MTAsciiMathListBuilder supportedCommands];
    NSArray *keys = [supportedCommands allKeys];
    return [keys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
}

//- (NSString*) readCommand
//{
//    // a command is a string of all upper and lower case characters.
//    NSMutableString* mutable = [NSMutableString string];
//    while([self hasCharacters]) {
//        unichar ch = [self getNextCharacter];
//        // Single char commands
//        if (mutable.length == 0 && (ch == '{' || ch == '}' || ch == '$' || ch == '&' || ch == '#' || ch == '%' || ch == '_' || ch == '|')) {
//            // These are single char commands.
//            [mutable appendString:[NSString stringWithCharacters:&ch length:1]];
//            break;
//        } else if ((ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z')) {
//            [mutable appendString:[NSString stringWithCharacters:&ch length:1]];
//        } else {
//            // we went too far
//            [self unlookCharacter];
//            break;
//        }
//    }
//    return mutable;
//}
//
//- (NSString*) readDelimiter
//{
//    while([self hasCharacters]) {
//        unichar ch = [self getNextCharacter];
//        // Ignore spaces and nonascii.
//        if (ch < 0x21 || ch > 0x7E) {
//            // skip non ascii characters and spaces
//            continue;
//        } else if (ch == '\\') {
//            // \ means a command
//            NSString* command = [self readCommand];
//            if ([command isEqualToString:@"|"]) {
//                // | is a command and also a regular delimiter. We use the || command to
//                // distinguish between the 2 cases for the caller.
//                return @"||";
//            }
//            return command;
//        } else {
//            return [NSString stringWithCharacters:&ch length:1];
//        }
//    }
//    // We ran out of characters for delimiter
//    return nil;
//}
//
////- (NSString*) getDelimiterValue:(NSString*) delimiterType
////{
////    NSString* delim = [self readDelimiter];
////    if (!delim) {
////        NSString* errorMessage = [NSString stringWithFormat:@"Missing delimiter for \\%@", delimiterType];
////        [self setError:MTParseErrorMissingDelimiter message:errorMessage];
////        return nil;
////    }
////    NSDictionary<NSString*, NSString*>* delims = [MTMathListBuilder delimiters];
////    NSString* delimValue = delims[delim];
////    if (!delimValue) {
////        NSString* errorMessage = [NSString stringWithFormat:@"Invalid delimiter for \\%@: %@", delimiterType, delim];
////        [self setError:MTParseErrorInvalidDelimiter message:errorMessage];
////        return nil;
////    }
////    return delimValue;
////}
//
//- (MTMathAtom*) atomForCommand:(NSString*) command
//{
//    NSDictionary* aliases = [MTMathListBuilder aliases];
//    // First check if this is an alias
//    NSString* canonicalCommand = aliases[command];
//    if (canonicalCommand) {
//        // Switch to the canonical command
//        command = canonicalCommand;
//    }
//    MTMathAtom* atom = [MTMathAtomFactory atomForLatexSymbol:command];
//    if (atom) {
//        return atom;
//    } else if ([command isEqualToString:@"frac"]) {
//        // A fraction command has 2 arguments
//        MTFraction* frac = [MTFraction new];
//        frac.numerator = [self buildInternal:true];
//        frac.denominator = [self buildInternal:true];
//        return frac;
//    } else if ([command isEqualToString:@"binom"]) {
//        // A binom command has 2 arguments
//        MTFraction* frac = [[MTFraction alloc] initWithRule:NO];
//        frac.numerator = [self buildInternal:true];
//        frac.denominator = [self buildInternal:true];
//        frac.leftDelimiter = @"(";
//        frac.rightDelimiter = @")";
//        return frac;
//    } else if ([command isEqualToString:@"sqrt"]) {
//        // A sqrt command with one argument
//        MTRadical* rad = [MTRadical new];
//        unichar ch = [self getNextCharacter];
//        if (ch == '[') {
//            // special handling for sqrt[degree]{radicand}
//            rad.degree = [self buildInternal:false stopChar:']'];
//            rad.radicand = [self buildInternal:true];
//        } else {
//            [self unlookCharacter];
//            rad.radicand = [self buildInternal:true];
//        }
//        return rad;
//    } else if ([command isEqualToString:@"left"]) {
//        NSString* delim = [self getDelimiterValue:@"left"];
//        if (!delim) {
//            return nil;
//        }
//        // Save the current inner while a new one gets built.
//        MTInner* oldInner = _currentInnerAtom;
//        _currentInnerAtom = [MTInner new];
//        _currentInnerAtom.leftBoundary = [MTMathAtom atomWithType:kMTMathAtomBoundary value:delim];
//        _currentInnerAtom.innerList = [self buildInternal:false];
//        if (!_currentInnerAtom.rightBoundary) {
//            // A right node would have set the right boundary so we must be missing the right node.
//            NSString* errorMessage = @"Missing \\right";
//            [self setError:MTParseErrorMissingRight message:errorMessage];
//            return nil;
//        }
//        // reinstate the old inner atom.
//        MTInner* newInner = _currentInnerAtom;
//        _currentInnerAtom = oldInner;
//        return newInner;
//    } else {
//        NSString* errorMessage = [NSString stringWithFormat:@"Invalid command \\%@", command];
//        [self setError:MTParseErrorInvalidCommand message:errorMessage];
//        return nil;
//    }
//}
//
//- (MTMathList*) stopCommand:(NSString*) command list:(MTMathList*) list stopChar:(unichar) stopChar
//{
//    static NSDictionary<NSString*, NSArray*>* fractionCommands = nil;
//    if (!fractionCommands) {
//        fractionCommands = @{ @"over" : @[],
//                              @"atop" : @[],
//                              @"choose" : @[ @"(", @")"],
//                              @"brack" : @[ @"[", @"]"],
//                              @"brace" : @[ @"{", @"}"]};
//    }
//    if ([command isEqualToString:@"right"]) {
//        NSString* delim = [self getDelimiterValue:@"right"];
//        if (!delim) {
//            return nil;
//        }
//        if (!_currentInnerAtom) {
//            NSString* errorMessage = @"Missing \\left";
//            [self setError:MTParseErrorMissingLeft message:errorMessage];
//            return nil;
//        }
//        _currentInnerAtom.rightBoundary = [MTMathAtom atomWithType:kMTMathAtomBoundary value:delim];
//        // return the list read so far.
//        return list;
//    } else if ([fractionCommands objectForKey:command]) {
//        MTFraction* frac = nil;
//        if ([command isEqualToString:@"over"]) {
//            frac = [[MTFraction alloc] init];
//        } else {
//            frac = [[MTFraction alloc] initWithRule:NO];
//        }
//        NSArray* delims = [fractionCommands objectForKey:command];
//        if (delims.count == 2) {
//            frac.leftDelimiter = delims[0];
//            frac.rightDelimiter = delims[1];
//        }
//        frac.numerator = list;
//        frac.denominator = [self buildInternal:NO stopChar:stopChar];
//        if (_error) {
//            return nil;
//        }
//        MTMathList* fracList = [MTMathList new];
//        [fracList addAtom:frac];
//        return fracList;
//    }
//    return nil;
//}
//
//- (void) setError:(MTParseErrors) code message:(NSString*) message
//{
//    // Only record the first error.
//    if (!_error) {
//        _error = [NSError errorWithDomain:MTParseError code:code userInfo:@{ NSLocalizedDescriptionKey : message }];
//    }
//}
//
+ (NSDictionary*) supportedCommands
{
    static NSDictionary* commands = nil;
    if (!commands) {
        commands = @{
                     @"square" : [MTMathAtomFactory placeholder],
                     
                     // Greek characters
                     @"alpha" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03B1"],
                     @"beta" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03B2"],
                     @"gamma" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03B3"],
                     @"delta" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03B4"],
                     @"varepsilon" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03B5"],
                     @"zeta" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03B6"],
                     @"eta" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03B7"],
                     @"theta" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03B8"],
                     @"iota" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03B9"],
                     @"kappa" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03BA"],
                     @"lambda" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03BB"],
                     @"mu" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03BC"],
                     @"nu" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03BD"],
                     @"xi" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03BE"],
                     @"omicron" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03BF"],
                     @"pi" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03C0"],
                     @"rho" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03C1"],
                     @"varsigma" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03C1"],
                     @"sigma" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03C3"],
                     @"tau" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03C4"],
                     @"upsilon" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03C5"],
                     @"varphi" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03C6"],
                     @"chi" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03C7"],
                     @"psi" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03C8"],
                     @"omega" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03C9"],
                     // We mark the following greek chars as ordinary so that we don't try
                     // to automatically italicize them as we do with variables.
                     // These characters fall outside the rules of italicization that we have defined.
                     @"epsilon" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\U0001D716"],
                     @"vartheta" : [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@"\U0001D717"],
                     @"phi" : [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@"\U0001D719"],
                     @"varrho" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\U0001D71A"],
                     @"varpi" : [MTMathAtom atomWithType:kMTMathAtomOrdinary value:@"\U0001D71B"],
                     
                     // Capital greek characters
                     @"Gamma" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u0393"],
                     @"Delta" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u0394"],
                     @"Theta" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u0398"],
                     @"Lambda" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u039B"],
                     @"Xi" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u039E"],
                     @"Pi" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03A0"],
                     @"Sigma" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03A3"],
                     @"Upsilon" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03A5"],
                     @"Phi" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03A6"],
                     @"Psi" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03A8"],
                     @"Omega" : [MTMathAtom atomWithType:kMTMathAtomVariable value:@"\u03A9"],
                     
                     @"*" : [MTMathAtom atomWithType:kMTMathAtomBinaryOperator value:@"\u22C5"],
                     @"**" : [MTMathAtom atomWithType:kMTMathAtomBinaryOperator value:@"\u2217"],
                     };
        
    }
    return commands;
}


//
//+ (NSDictionary*) aliases
//{
//    static NSDictionary* aliases = nil;
//    if (!aliases) {
//        aliases = @{
//                    @"lnot" : @"neg",
//                    @"land" : @"wedge",
//                    @"lor" : @"vee",
//                    @"ne" : @"neq",
//                    @"le" : @"leq",
//                    @"ge" : @"geq",
//                    @"lbrace" : @"{",
//                    @"rbrace" : @"}",
//                    @"Vert" : @"|",
//                    @"gets" : @"leftarrow",
//                    @"to" : @"rightarrow",
//                    @"iff" : @"Longleftrightarrow",
//                    };
//    }
//    return aliases;
//}
//
//+(NSDictionary<NSString*, NSString*> *) delimiters
//{
//    static NSDictionary* delims = nil;
//    if (!delims) {
//        delims = @{
//                   @"." : @"", // . means no delimiter
//                   @"(" : @"(",
//                   @")" : @")",
//                   @"[" : @"[",
//                   @"]" : @"]",
//                   @"<" : @"\u2329",
//                   @">" : @"\u232A",
//                   @"/" : @"/",
//                   @"\\" : @"\\",
//                   @"|" : @"|",
//                   @"lgroup" : @"\u27EE",
//                   @"rgroup" : @"\u27EF",
//                   @"||" : @"\u2016",
//                   @"Vert" : @"\u2016",
//                   @"vert" : @"|",
//                   @"uparrow" : @"\u2191",
//                   @"downarrow" : @"\u2193",
//                   @"updownarrow" : @"\u2195",
//                   @"Uparrow" : @"21D1",
//                   @"Downarrow" : @"21D3",
//                   @"Updownarrow" : @"21D5",
//                   @"backslash" : @"\\",
//                   @"rangle" : @"\u232A",
//                   @"langle" : @"\u2329",
//                   @"rbrace" : @"}",
//                   @"}" : @"}",
//                   @"{" : @"{",
//                   @"lbrace" : @"{",
//                   @"lceil" : @"\u2308",
//                   @"rceil" : @"\u2309",
//                   @"lfloor" : @"\u230A",
//                   @"rfloor" : @"\u230B",
//                   };
//    }
//    return delims;
//}
//
//+ (NSDictionary*) textToCommands
//{
//    static NSDictionary* textToCommands = nil;
//    if (!textToCommands) {
//        NSDictionary* commands = [self supportedCommands];
//        NSMutableDictionary* mutableDict = [NSMutableDictionary dictionaryWithCapacity:commands.count];
//        for (NSString* command in commands) {
//            MTMathAtom* atom = commands[command];
//            mutableDict[atom.nucleus] = command;
//        }
//        textToCommands = [mutableDict copy];
//    }
//    return textToCommands;
//}
//
//+ (NSDictionary*) delimToCommand
//{
//    static NSDictionary* delimToCommands = nil;
//    if (!delimToCommands) {
//        NSDictionary* delims = [self delimiters];
//        NSMutableDictionary* mutableDict = [NSMutableDictionary dictionaryWithCapacity:delims.count];
//        for (NSString* command in delims) {
//            NSString* delim = delims[command];
//            NSString* existingCommand = mutableDict[delim];
//            if (existingCommand) {
//                if (command.length > existingCommand.length) {
//                    // Keep the shorter command
//                    continue;
//                } else if (command.length == existingCommand.length) {
//                    // If the length is the same, keep the alphabetically first
//                    if ([command compare:existingCommand] == NSOrderedDescending) {
//                        continue;
//                    }
//                }
//            }
//            // In other cases replace the command.
//            mutableDict[delim] = command;
//        }
//        delimToCommands = [mutableDict copy];
//    }
//    return delimToCommands;
//}
//
+ (MTMathList *)buildFromString:(NSString *)str
{
    MTAsciiMathListBuilder* builder = [[MTAsciiMathListBuilder alloc] initWithString:str];
    return builder.build;
}
//
//+ (MTMathList *)buildFromString:(NSString *)str error:(NSError *__autoreleasing *)error
//{
//    MTMathListBuilder* builder = [[MTMathListBuilder alloc] initWithString:str];
//    MTMathList* output = [builder build];
//    if (builder.error) {
//        if (error) {
//            *error = builder.error;
//        }
//        return nil;
//    }
//    return output;
//}
//
//+ (NSString*) delimToString:(NSString*) delim
//{
//    NSString* command = self.delimToCommand[delim];
//    if (command) {
//        NSArray<NSString*>* singleChars = @[ @"(", @")", @"[", @"]", @"<", @">", @"|", @".", @"/"];
//        if ([singleChars containsObject:command]) {
//            return command;
//        } else if ([command isEqualToString:@"||"]) {
//            return @"\\|"; // special case for ||
//        } else {
//            return [NSString stringWithFormat:@"\\%@", command];
//        }
//    }
//    return @"";
//}
//

// MARK - MathList (created from Latex) to AsciiMath String

+ (NSString *)mathListToString:(MTMathList *)ml
{
    NSDictionary* textToCommands = [self textToCommands];    
    NSMutableString* str = [NSMutableString string];
    
    for (MTMathAtom* atom in ml.atoms) {
        
        NSString* command = textToCommands[atom.nucleus];
        
        if (command) {
            [str appendFormat:@"%@ ", command];
        } else if (atom.type == kMTMathAtomFraction) {
            MTFraction* frac = (MTFraction*) atom;
            if (frac.hasRule) {
                [str appendFormat:@"%@/%@", [self mathListToString:frac.numerator], [self mathListToString:frac.denominator]];
            } else {
                NSString* command = nil;
                if (!frac.leftDelimiter && !frac.rightDelimiter) {
                    command = @"atop";
                } else if ([frac.leftDelimiter isEqualToString:@"("] && [frac.rightDelimiter isEqualToString:@")"]) {
                    command = @"choose";
                } else if ([frac.leftDelimiter isEqualToString:@"{"] && [frac.rightDelimiter isEqualToString:@"}"]) {
                    command = @"brace";
                } else if ([frac.leftDelimiter isEqualToString:@"["] && [frac.rightDelimiter isEqualToString:@"]"]) {
                    command = @"brack";
                } else {
                    command = [NSString stringWithFormat:@"atopwithdelims%@%@", frac.leftDelimiter, frac.rightDelimiter];
                }
                [str appendFormat:@"{%@ \\%@ %@}", [self mathListToString:frac.numerator], command, [self mathListToString:frac.denominator]];
            }
        } else if (atom.type == kMTMathAtomRadical) {
            
            MTRadical* rad = (MTRadical*) atom;
            if (rad.degree) {
                [str appendString:@"root"];
                [str appendFormat:@"(%@)", [self mathListToString:rad.degree]];
            } else {
                [str appendString:@"sqrt"];
            }
            [str appendFormat:@"(%@)", [self mathListToString:rad.radicand]];
        } else if (atom.type == kMTMathAtomInner) {
            MTInner* inner = (MTInner*) atom;
            if (inner.leftBoundary || inner.rightBoundary) {
                if (inner.leftBoundary) {
                    [str appendFormat:@"\\left%@ ", [self delimToString:inner.leftBoundary.nucleus]];
                } else {
                    [str appendString:@"\\left. "];
                }
                [str appendString:[self mathListToString:inner.innerList]];
                if (inner.rightBoundary) {
                    [str appendFormat:@"\\right%@ ", [self delimToString:inner.rightBoundary.nucleus]];
                } else {
                    [str appendString:@"\\right. "];
                }
            } else {
                [str appendFormat:@"{%@}", [self mathListToString:inner.innerList]];
            }
        } else if (atom.nucleus.length == 0) {
            [str appendString:@"{}"];
        } else if ([atom.nucleus isEqualToString:@"\u2236"]) {
            // math colon
            [str appendString:@":"];
        } else if ([atom.nucleus isEqualToString:@"\u2212"]) {
            // math minus
            [str appendString:@"-"];
        } else if ([atom.nucleus isEqualToString:@"\u00d7"]) {
            // math multiplier
            [str appendString:@"*"];
        } else if ([atom.nucleus isEqualToString:@"\u00F7"]) {
            // math divider
            [str appendString:@":"];
        } else {
            [str appendString:atom.nucleus];
        }
        
        if (atom.superScript) {
            [str appendFormat:@"^(%@)", [self mathListToString:atom.superScript]];
        }
        
        if (atom.subScript) {
            [str appendFormat:@"_(%@)", [self mathListToString:atom.subScript]];
        }
    }
    return [str copy];
}

+ (NSDictionary*) textToCommands
{
    static NSDictionary* textToCommands = nil;
    if (!textToCommands) {
        NSDictionary* commands = [self supportedCommands];
        NSMutableDictionary* mutableDict = [NSMutableDictionary dictionaryWithCapacity:commands.count];
        for (NSString* command in commands) {
            MTMathAtom* atom = commands[command];
            mutableDict[atom.nucleus] = command;
        }
        textToCommands = [mutableDict copy];
    }
    return textToCommands;
}

+ (NSString*) delimToString:(NSString*) delim
{
    NSString* command = self.delimToCommand[delim];
    if (command) {
        NSArray<NSString*>* singleChars = @[ @"(", @")", @"[", @"]", @"<", @">", @"|", @".", @"/"];
        if ([singleChars containsObject:command]) {
            return command;
        } else if ([command isEqualToString:@"||"]) {
            return @"\\|"; // special case for ||
        } else {
            return [NSString stringWithFormat:@"\\%@", command];
        }
    }
    return @"";
}

+ (NSDictionary*) delimToCommand
{
    static NSDictionary* delimToCommands = nil;
    if (!delimToCommands) {
        NSDictionary* delims = [self delimiters];
        NSMutableDictionary* mutableDict = [NSMutableDictionary dictionaryWithCapacity:delims.count];
        for (NSString* command in delims) {
            NSString* delim = delims[command];
            NSString* existingCommand = mutableDict[delim];
            if (existingCommand) {
                if (command.length > existingCommand.length) {
                    // Keep the shorter command
                    continue;
                } else if (command.length == existingCommand.length) {
                    // If the length is the same, keep the alphabetically first
                    if ([command compare:existingCommand] == NSOrderedDescending) {
                        continue;
                    }
                }
            }
            // In other cases replace the command.
            mutableDict[delim] = command;
        }
        delimToCommands = [mutableDict copy];
    }
    return delimToCommands;
}

+(NSDictionary<NSString*, NSString*> *) delimiters
{
    static NSDictionary* delims = nil;
    if (!delims) {
        delims = @{
                   @"." : @"", // . means no delimiter
                   @"(" : @"(",
                   @")" : @")",
                   @"[" : @"[",
                   @"]" : @"]",
                   @"<" : @"\u2329",
                   @">" : @"\u232A",
                   @"/" : @"/",
                   @"\\" : @"\\",
                   @"|" : @"|",
                   @"lgroup" : @"\u27EE",
                   @"rgroup" : @"\u27EF",
                   @"||" : @"\u2016",
                   @"Vert" : @"\u2016",
                   @"vert" : @"|",
                   @"uparrow" : @"\u2191",
                   @"downarrow" : @"\u2193",
                   @"updownarrow" : @"\u2195",
                   @"Uparrow" : @"21D1",
                   @"Downarrow" : @"21D3",
                   @"Updownarrow" : @"21D5",
                   @"backslash" : @"\\",
                   @"rangle" : @"\u232A",
                   @"langle" : @"\u2329",
                   @"rbrace" : @"}",
                   @"}" : @"}",
                   @"{" : @"{",
                   @"lbrace" : @"{",
                   @"lceil" : @"\u2308",
                   @"rceil" : @"\u2309",
                   @"lfloor" : @"\u230A",
                   @"rfloor" : @"\u230B",
                   };
    }
    return delims;
}

@end
