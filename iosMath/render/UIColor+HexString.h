//
//  UIColor+HexString.h
//  iosMath
//
//  Created by Jakub Dolecki on 12/5/16.
//
//

//#import <UIKit/UIKit.h>

@interface UIColor (HexString)

/**
 Create a UIColor object from a hex string. He

 @param hexString Hex string in the form "#XXXXXX" or "XXXXXX"
 @return UIColor object if we can parse the provided hex.
 */
+ (UIColor *)colorFromHexString:(NSString *)hexString;

@end
