//
//  MTAsciiMathListBuilder.h
//  iosMath
//
//  Created by Jakub Dolecki on 7/19/16.
//
//

@import Foundation;

#import "MTMathList.h"

@interface MTAsciiMathListBuilder : NSObject

/** Contains any error that occurred during parsing. */
@property (nonatomic, readonly, nullable) NSError* error;

/** Create a `MTMathListBuilder` for the given string. After instantiating the
 `MTMathListBuilder, use `build` to build the mathlist. Create a new `MTMathListBuilder`
 for each string that needs to be parsed. Do not reuse the object.
 @param str The LaTeX string to be used to build the `MTMathList`
 */
- (nonnull instancetype) initWithString:(nonnull NSString*) str NS_DESIGNATED_INITIALIZER;
- (nonnull instancetype) init NS_UNAVAILABLE;

/// Builds a mathlist from the given string. Returns nil if there is an error.
- (nullable MTMathList*) build;

/// List of commands that are supported.
+ (nonnull NSDictionary<NSString*, MTMathAtom*>*) supportedCommands;

/** Construct a math list from a given string. If there is parse error, returns
 nil. To retrieve the error use the function `[MTMathListBuilder buildFromString:error:]`.
 */
+ (nullable MTMathList*) buildFromString:(nonnull NSString*) str;

/** Construct a math list from a given string. If there is an error while
 constructing the string, this returns nil. The error is returned in the
 `error` parameter.
 */
+ (nullable MTMathList*) buildFromString:(nonnull NSString*) str error:( NSError* _Nullable * _Nullable) error;

/// This converts the MTMathList to LaTeX.
+ (nonnull NSString*) mathListToString:(nonnull MTMathList*) ml;

@end
