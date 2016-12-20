//
//  MathUILabel.m
//  iosMath
//
//  Created by Kostub Deshmukh on 8/26/13.
//  Copyright (C) 2013 MathChat
//   
//  This software may be modified and distributed under the terms of the
//  MIT license. See the LICENSE file for details.
//

#import "MTMathUILabel.h"
#import "MTMathListDisplay.h"
#import "MTFontManager.h"
#import "MTMathListBuilder.h"
#import "MTTypesetter.h"

@implementation MTMathUILabel {
    UILabel* _errorLabel;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initCommon];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initCommon];
    }
    return self;
}

- (void) initCommon
{
    self.layer.geometryFlipped = YES;  // For ease of interaction with the CoreText coordinate system.
    // default font size
    _fontSize = 20;
    _contentInsets = UIEdgeInsetsZero;
    _labelMode = kMTMathUILabelModeDisplay;
    MTFont* font = [MTFontManager fontManager].defaultFont;
    self.font = font;
    UIFont* textFont = [UIFont systemFontOfSize:_fontSize];
    self.textFont = textFont;
    _textAlignment = kMTTextAlignmentLeft;
    _displayList = nil;
    _displayErrorInline = true;
    self.backgroundColor = [UIColor clearColor];
    _textColor = [UIColor blackColor];
    _placeholderColor = [UIColor blackColor];
    _errorLabel = [[UILabel alloc] init];
    _errorLabel.hidden = YES;
    _errorLabel.layer.geometryFlipped = YES;
    _errorLabel.textColor = [UIColor redColor];
    [self addSubview:_errorLabel];
}

- (void)setFont:(MTFont*)font
{
    NSParameterAssert(font);
    _font = font;
    if (_mathList) {
        _displayList = [MTTypesetter createLineForMathList:_mathList font:_font textFont:_textFont style:self.currentStyle];
    }
    [self invalidateIntrinsicContentSize];
    [self setNeedsLayout];
}

- (void)setTextFont:(UIFont *)textFont
{
    NSParameterAssert(textFont);
    _textFont = textFont;
    if (_mathList) {
        _displayList = [MTTypesetter createLineForMathList:_mathList font:_font textFont:_textFont style:self.currentStyle];
    }
    [self invalidateIntrinsicContentSize];
    [self setNeedsLayout];
}

- (void)setFontSize:(CGFloat)fontSize
{
    _fontSize = fontSize;
    MTFont* font = [_font copyFontWithSize:_fontSize];
    self.font = font;
}

- (void)setContentInsets:(UIEdgeInsets)contentInsets
{
    _contentInsets = contentInsets;
    [self invalidateIntrinsicContentSize];
    [self setNeedsLayout];
}

- (void) setMathList:(MTMathList *)mathList
{
    _mathList = mathList;
    _error = nil;
    _exception = nil;
    _latex = [MTMathListBuilder mathListToString:mathList];
    _displayList = [MTTypesetter createLineForMathList:_mathList font:_font textFont:_textFont style:self.currentStyle];
    [self invalidateIntrinsicContentSize];
    [self setNeedsLayout];
}

- (void) setDisplayList:(MTMathListDisplay *)displayList
{
    _displayList = displayList;
    _mathList = nil;
    _latex = nil;
    _error = nil;
    _exception = nil;
    [self invalidateIntrinsicContentSize];
    [self setNeedsLayout];
}

- (void)setLatex:(NSString *)latex
{
    _latex = latex;
    _error = nil;
    _exception = nil;
    NSError* error = nil;
    _mathList = [MTMathListBuilder buildFromString:latex error:&error];
    if (error) {
        _mathList = nil;
        _error = error;
        NSLog(@"Error parsing latex: %@", error.localizedDescription);
        _errorLabel.text = error.localizedDescription;
        _errorLabel.frame = self.bounds;
        _errorLabel.hidden = !self.displayErrorInline;
    } else {
        _errorLabel.hidden = YES;
        _displayList = [MTTypesetter createLineForMathList:_mathList font:_font textFont:_textFont style:self.currentStyle];
    }
    [self invalidateIntrinsicContentSize];
    [self setNeedsLayout];
}

- (void)trySetLatex:(NSString *)string
{
    @try {
        self.latex = string;
    } @catch (NSException *exception) {
        _exception = exception;
        _errorLabel.text = @"Error parsing latex.";
        _errorLabel.frame = self.bounds;
        _errorLabel.hidden = !self.displayErrorInline;
    } @finally {
        //
    }
}

- (void)setLabelMode:(MTMathUILabelMode)labelMode
{
    _labelMode = labelMode;
    [self invalidateIntrinsicContentSize];
    [self setNeedsLayout];
}

- (void)setTextColor:(UIColor *)textColor
{
    NSParameterAssert(textColor);
    _textColor = textColor;
    _displayList.textColor = textColor;
    [self setNeedsDisplay];
}

- (void)setPlaceholderColor:(UIColor *)placeholderColor
{
    NSParameterAssert(placeholderColor);
    _placeholderColor = placeholderColor;
     _displayList.placeholderColor = placeholderColor;
    [self setNeedsDisplay];
}

- (void)setTextAlignment:(MTTextAlignment)textAlignment
{
    _textAlignment = textAlignment;
    [self invalidateIntrinsicContentSize];
    [self setNeedsLayout];
}

- (MTLineStyle) currentStyle
{
    switch (_labelMode) {
        case kMTMathUILabelModeDisplay:
            return kMTLineStyleDisplay;
        case kMTMathUILabelModeText:
            return kMTLineStyleText;
    }
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];

    if (!_displayList) {
        return;
    }
    
    // Drawing code
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    
    [_displayList draw:context];
    
    CGContextRestoreGState(context);
}

- (void) layoutSubviews
{
    if (_displayList == nil && _mathList) {
        _displayList = [MTTypesetter createLineForMathList:_mathList font:_font textFont:_textFont style:self.currentStyle];
    }
    
    if (_displayList) {
        if (![_displayList.textColor isEqual:_textColor]) {
            _displayList.textColor = _textColor;
        }
        if (![_displayList.placeholderColor isEqual:_placeholderColor]) {
            _displayList.placeholderColor = _placeholderColor;
        }
        
        // Determine x position based on alignment
        CGFloat textX = 0;
        switch (self.textAlignment) {
            case kMTTextAlignmentLeft:
                textX = self.contentInsets.left;
                break;
            case kMTTextAlignmentCenter:
                textX = (self.bounds.size.width - self.contentInsets.left - self.contentInsets.right - _displayList.width) / 2 + self.contentInsets.left;
                break;
            case kMTTextAlignmentRight:
                textX = (self.bounds.size.width - _displayList.width - self.contentInsets.right);
                break;
        }
        
        CGFloat availableHeight = self.bounds.size.height - self.contentInsets.bottom - self.contentInsets.top;
        // center things vertically
        CGFloat height = _displayList.ascent + _displayList.descent;
        if (height < _fontSize/2) {
            // Set the height to the half the size of the font
            height = _fontSize/2;
        }        
        CGFloat textY = (availableHeight - height) / 2 + _displayList.descent + self.contentInsets.bottom;
        _displayList.position = CGPointMake(textX, textY);
    } else {
        _displayList = nil;
    }
    _errorLabel.frame = self.bounds;
    [self setNeedsDisplay];
}

- (CGSize) sizeThatFits:(CGSize)size
{
    MTMathListDisplay* displayList = _displayList;
    if (_mathList && displayList == nil) {
        displayList = [MTTypesetter createLineForMathList:_mathList font:_font textFont:_textFont style:self.currentStyle];
    }

    size.width = displayList.width + self.contentInsets.left + self.contentInsets.right;
    size.height = displayList.ascent + displayList.descent + self.contentInsets.top + self.contentInsets.bottom;
    return size;
}

- (CGSize) intrinsicContentSize
{
    return [self sizeThatFits:CGSizeZero];
}

@end
