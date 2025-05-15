//
//  UIKitExtensions.h
//  iPhoneTools
//
//  Created by Nick Profitt on 11/14/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

//RGB color macro
#define UIColorFromRGB(rgbValue) [UIColor \
colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0xFF00) >> 8))/255.0 \
blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

//RGB color macro with alpha
#define UIColorFromRGBWithAlpha(rgbValue,a) [UIColor \
colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0xFF00) >> 8))/255.0 \
blue:((float)(rgbValue & 0xFF))/255.0 alpha:a]

@interface UIViewController (UIKitExtensions)

- (void)presentTransparentController:(UIViewController *)controller animated:(BOOL)animated;

@end

@interface UIImage (UIKitExtensions)

- (UIImage *)convertImageToGrayScale;
- (UIImage *)applyTintWithColor:(UIColor *)tintColor;
- (UIImage *)resizedImage:(CGSize)newSize;
- (UIImage *)generateClearRect:(CGRect)frameRect inRect:(CGRect)frame;
- (UIImage *)stretchableImageWithCapInsets:(UIEdgeInsets)capInsets;
- (NSArray *)detectFaces;

- (UIImage *)applyLightEffect;
- (UIImage *)applyExtraLightEffect;
- (UIImage *)applyDarkEffect;
- (UIImage *)applyTintEffectWithColor:(UIColor *)tintColor;

- (UIImage *)applyBlurWithRadius:(CGFloat)blurRadius tintColor:(UIColor *)tintColor saturationDeltaFactor:(CGFloat)saturationDeltaFactor maskImage:(UIImage *)maskImage;
- (UIImage *)imageByApplyingAlpha:(CGFloat) alpha;
@end

@interface NSString (UIKitExtensions)

- (NSString *)stringBetweenString:(NSString*)start andString:(NSString*)end;
- (NSString *)stringByStrippingHTMLTags;
- (NSString *)stringByStrippingHTMLItems;
- (NSString *)fileName;
- (BOOL)hasRussianCharacters;
- (BOOL)hasEnglishCharacters;
- (NSString *)cropTimeDuration;
- (NSString *)onlyNumbers;

@end

@interface NSMutableAttributedString (UIKitExtensions)
- (void)addColor:(UIColor *)color substring:(NSString *)substring;
- (void)addBackgroundColor:(UIColor *)color substring:(NSString *)substring;
- (void)addUnderlineForSubstring:(NSString *)substring;
- (void)addStrikeThrough:(int)thickness substring:(NSString *)substring;
- (void)addShadowColor:(UIColor *)color width:(int)width height:(int)height radius:(int)radius substring:(NSString *)substring;
- (void)addFontWithName:(NSString *)fontName size:(int)fontSize substring:(NSString *)substring;
- (void)addFont:(UIFont *)font substring:(NSString *)substring;
- (void)addAlignment:(NSTextAlignment)alignment substring:(NSString *)substring;
- (void)addColorToRussianText:(UIColor *)color;
- (void)addStrokeColor:(UIColor *)color thickness:(int)thickness substring:(NSString *)substring;
- (void)addVerticalGlyph:(BOOL)glyph substring:(NSString *)substring;
@end

@interface NSArray (UIKitExtensions)

- (NSString *)toString;

@end

@interface NSMutableArray (UIKitExtensions)

- (void)moveObjectAtIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex;

@end

@interface NSDate (UIKitExtensions)

- (NSString *)stringWithFormat:(NSString *)dateFormat;
+ (NSDate *)dateFromString:(NSString *)dateString dateFormat:(NSString *)dateFormat;
- (NSDate *)currentTimezone;
- (BOOL)isBetweenInclusive:(NSDate *)startDate endDate:(NSDate *)endDate;
- (BOOL)isToday;

@end

@interface UIColor (UIKitExtensions)

+ (UIColor *)colorFromHexString:(NSString *)hexString alpha: (CGFloat)alpha;
+ (UIColor *)appGreen;

@end

@interface NSNumber (UIKitExtensions)

- (NSString *)scaleNumber;
- (NSString *)priceValue;
- (NSString *)formattedString;

@end

@interface UIButton (UIKitExtensions)

- (void)backgroundToImage;
- (void)centerContent;

@end

@interface UITableView (UIKitExtensions)

- (void)scrollTableViewToBottomAnimated:(BOOL)animated;
- (void)registerCellClass:(id)cell;
- (void)registerCellClass:(id)cell withIdentifier:(NSString *)identifier;

@end

@interface UICollectionView (UIKitExtensions)

- (void)registerCellClass:(id)cell;

@end

