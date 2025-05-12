//
//  UIUtils.h
//  Textiny
//
//  created by halcyoni on 13/08/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UIUtils : NSObject {

}

+ (id)getClassFromNib:(Class)class nibNamed:(NSString *)nibName owner:(id)owner;
+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize;
+ (UIImage *)image:(UIImage *)image scaledToSize:(CGSize)size;
+ (UIImage *)image:(UIImage *)image scaledToFitSize:(CGSize)size;
+ (UIImage *)imageWithImage:(UIImage *)image zoom:(double)zoom;
+ (UIImage*)captureView:(UIView *)view;
+ (CGFloat)findHeightForText:(NSString *)text havingWidth:(CGFloat)widthValue andFont:(UIFont *)font;
+ (CGFloat)findWidthForText:(NSString *)text havingHeight:(CGFloat)heightValue andFont:(UIFont *)font;
+ (UIImage *)imageWithSize:(CGSize)size andColor:(UIColor *)color;
+ (UIImage *)roundedImageWithSize:(CGSize)size andColor:(UIColor *)color withBorder:(BOOL)withBorder;
+ (UIBezierPath *)roundedBezierForSize:(CGSize)size;
+ (UIImage *)imageWithInnerShadowForFrame:(CGRect)frame andShadowOffset:(CGSize)shadowOffset andShadoBlurRadius:(CGFloat)shadowBlurRadius;

+ (void)setLeftPaddingForTextFieldsForView:(UIView *)view andSubViews:(BOOL)isSubViews;
+ (void)setPlaceholderColor:(UIColor *)color forView:(UIView *)view andSubViews:(BOOL)isSubViews;
+ (void)closeKeyboardForView:(UIView *)view andSubviews:(BOOL)isSubViews;
+ (void)selectTextForInput:(UITextView *)input atRange:(NSRange)range;

@end
