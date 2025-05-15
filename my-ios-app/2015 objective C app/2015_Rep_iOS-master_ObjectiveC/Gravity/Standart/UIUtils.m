//
//  UIUtils.m
//  Textiny
//
//  created by halcyoni on 13/08/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "UIUtils.h"
#import <QuartzCore/QuartzCore.h>
#import <CoreText/CoreText.h>

@implementation UIUtils

+ (id)getClassFromNib:(Class)class nibNamed:(NSString *)nibName owner:(id)owner
{
	id		idClass		= nil;
	NSArray	*nibObjects	= nil;
	
	nibObjects = [[NSBundle mainBundle] loadNibNamed:nibName owner:owner options:nil];
	
	if( nibObjects == nil )
		return idClass;
	
	for( int n = 0; n < [nibObjects count]; n++ )
	{
		if( [[nibObjects objectAtIndex:n] isKindOfClass:class] == TRUE )
		{
			idClass = [nibObjects objectAtIndex:n];
			break;
		}
	}
	
	return idClass;
}

+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    UIGraphicsBeginImageContext(newSize);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

+ (UIImage *)image:(UIImage *)image scaledToSize:(CGSize)size
{
    //create drawing context
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0f);
    
    //draw
    [image drawInRect:CGRectMake(0.0f, 0.0f, size.width, size.height)];
    
    //capture resultant image
    UIImage *res = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    //return image
    return res;
}

+ (UIImage *)image:(UIImage *)image scaledToFitSize:(CGSize)size
{
    //calculate rect
    CGFloat aspect = image.size.width / image.size.height;
    if (size.width / aspect <= size.height)
    {
        return [self image:image scaledToSize:CGSizeMake(size.width, size.width / aspect)];
    }
    else
    {
        return [self image:image scaledToSize:CGSizeMake(size.height * aspect, size.height)];
    }
}

+ (UIImage*)captureView:(UIView *)view {
	if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)])
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, NO, [UIScreen mainScreen].scale);
    else
        UIGraphicsBeginImageContext(view.bounds.size);
    
    if (iOS7) {
        [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:NO];
    } else {
        [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    }
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
	return image;
}

+ (UIImage *)imageWithImage:(UIImage *)image zoom:(double)zoom {
    image = [[UIImage alloc] initWithCGImage:image.CGImage scale:1.0f orientation:image.imageOrientation];
    UIGraphicsBeginImageContext(image.size);
	CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
	CGRect newrect = CGRectApplyAffineTransform(rect, CGAffineTransformMakeScale(zoom, zoom));
    newrect.origin.x = (rect.size.width - newrect.size.width) / 2;
    newrect.origin.y = (rect.size.height - newrect.size.height) / 2;
	[image drawInRect:newrect];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return newImage;
}

+ (CGFloat)findHeightForText:(NSString *)text havingWidth:(CGFloat)widthValue andFont:(UIFont *)font
{
    CGFloat result = font.pointSize+4;
    
    if (text) {
        CGSize textSize = { widthValue, CGFLOAT_MAX };       //Width and height of text area
        CGSize size;
        CGRect frame = [text boundingRectWithSize:textSize
                                          options:NSStringDrawingUsesLineFragmentOrigin
                                       attributes:@{NSFontAttributeName:font}
                                          context:nil];
        size = CGSizeMake(frame.size.width, frame.size.height);
        
        result = MAX(size.height, result); //At least one row
    }
    return ceilf(result);
}

+ (CGFloat)findWidthForText:(NSString *)text havingHeight:(CGFloat)heightValue andFont:(UIFont *)font
{
    CGFloat result = 0;
    if (text) {
        CGSize textSize = { CGFLOAT_MAX, heightValue };       //Width and height of text area
        CGSize size;
        CGRect frame = [text boundingRectWithSize:textSize
                                          options:NSStringDrawingUsesLineFragmentOrigin
                                       attributes:@{NSFontAttributeName:font}
                                          context:nil];
        size = CGSizeMake(frame.size.width, frame.size.height);
        
        result = MAX(size.width, result); //At least one row
    }
    return ceilf(result);
}

+ (UIImage *)imageWithSize:(CGSize)size andColor:(UIColor *)color {
    
    if (size.width == 0 || size.height == 0) {
        return nil;
    }
    
    CGRect rect = CGRectMake(0.0f, 0.0f, size.width, size.height);
    UIGraphicsBeginImageContextWithOptions(size, NO, [[UIScreen mainScreen] scale]);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIImage *)roundedImageWithSize:(CGSize)size andColor:(UIColor *)color withBorder:(BOOL)withBorder {
    
    if (size.width == 0 || size.height == 0) {
        return nil;
    }
    
    UIGraphicsBeginImageContextWithOptions(size, NO, [[UIScreen mainScreen] scale]);
    
    CGSize greenSize = size;
    greenSize.height -= 3;
    greenSize.width -= 2;
    UIBezierPath *path = [UIUtils roundedBezierForSize:greenSize];
    [path applyTransform:CGAffineTransformMakeTranslation(1, withBorder ? 0 : 1.5)];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSaveGState(context);
    UIColor *shadowColor = [UIColor colorWithWhite:withBorder ? 0 : 0.57 alpha:withBorder ? 0.7 : 1];
    CGContextSetShadowWithColor(context, CGSizeMake(0, withBorder ? 1 : 0), withBorder ? 2 : 1, [shadowColor CGColor]);
    [color setFill];
    [path fill];
    CGContextRestoreGState(context);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (UIBezierPath *)roundedBezierForSize:(CGSize)size {
    
    UIBezierPath *path = UIBezierPath.bezierPath;
    
    /*[path moveToPoint: CGPointMake(0, size.height / 2)];
     [path addCurveToPoint: CGPointMake(size.width * 0.0189, size.height) controlPoint1: CGPointMake(0, size.height / 4 * 3) controlPoint2: CGPointMake(size.width * 0.0189, size.height)];
     [path addLineToPoint: CGPointMake(size.width - size.width * 0.0164, size.height)];
     [path addCurveToPoint: CGPointMake(size.width, size.height / 2) controlPoint1: CGPointMake(size.width - size.width * 0.0164, size.height) controlPoint2: CGPointMake(size.width, size.height / 4 * 3)];
     [path addCurveToPoint: CGPointMake(size.width - size.width * 0.0164, 0) controlPoint1: CGPointMake(size.width, size.height / 4) controlPoint2: CGPointMake(size.width - size.width * 0.0164, 0)];
     [path addLineToPoint: CGPointMake(size.width * 0.0189, 0)];
     [path addCurveToPoint: CGPointMake(0, size.height / 2) controlPoint1: CGPointMake(size.width * 0.0189, 0) controlPoint2: CGPointMake(0, size.height / 4)];*/
    
    
    /*[path moveToPoint: CGPointMake(size.width * 0.979, 0)];
     [path addCurveToPoint: CGPointMake(size.width, size.height * 0.13) controlPoint1: CGPointMake(size.width * 0.9902, 0) controlPoint2: CGPointMake(size.width * 0.9996, size.height * 0.578)];
     [path addCurveToPoint: CGPointMake(size.width, size.height * 0.135) controlPoint1: CGPointMake(size.width, size.height * 0.13) controlPoint2: CGPointMake(size.width, size.height * 0.1317)];
     [path addCurveToPoint: CGPointMake(size.width, size.height * 0.865) controlPoint1: CGPointMake(size.width, size.height * 0.1962) controlPoint2: CGPointMake(size.width, size.height * 0.8036)];
     [path addCurveToPoint: CGPointMake(size.width, size.height * 0.87) controlPoint1: CGPointMake(size.width, size.height * 0.8683) controlPoint2: CGPointMake(size.width, size.height * 0.87)];
     [path addCurveToPoint: CGPointMake(size.width * 0.9787, size.height) controlPoint1: CGPointMake(size.width * 0.9996, size.height * 0.9422) controlPoint2: CGPointMake(size.width * 0.9902, size.height)];
     [path addLineToPoint: CGPointMake(size.width * 0.213, size.height)];
     [path addCurveToPoint: CGPointMake(0, size.height * 0.87) controlPoint1: CGPointMake(size.width * 0.098, size.height) controlPoint2: CGPointMake(size.width * 0.004, size.height * 0.9422)];
     [path addCurveToPoint: CGPointMake(0, size.height * 0.865) controlPoint1: CGPointMake(-0, size.height * 0.87) controlPoint2: CGPointMake(0, size.height * 0.8683)];
     [path addCurveToPoint: CGPointMake(0, size.height * 0.135) controlPoint1: CGPointMake(0, size.height * 0.8036) controlPoint2: CGPointMake(0, size.height * 0.1964)];
     [path addCurveToPoint: CGPointMake(0, size.height * 0.13) controlPoint1: CGPointMake(0, size.height * 0.1317) controlPoint2: CGPointMake(0, size.height * 0.13)];
     [path addCurveToPoint: CGPointMake(size.width * 0.213, 0) controlPoint1: CGPointMake(size.width * 0.004, size.height * 0.578) controlPoint2: CGPointMake(size.width * 0.098, 0)];
     [path addLineToPoint: CGPointMake(size.width * 0.9787, 0)];
     [path addLineToPoint: CGPointMake(size.width * 0.979, 0)];*/
    
    [path moveToPoint: CGPointMake(size.width * 0.01, size.height)];
    [path addLineToPoint: CGPointMake(size.width * 0.99, size.height)];
    [path addLineToPoint: CGPointMake(size.width * 0.99, 0)];
    [path addLineToPoint: CGPointMake(size.width * 0.01, 0)];
    [path addLineToPoint: CGPointMake(size.width * 0.01, size.height)];
    [path closePath];
    [path moveToPoint: CGPointMake(size.width * 0.99, 0)];
    [path addCurveToPoint: CGPointMake(size.width, size.height * 0.38) controlPoint1: CGPointMake(size.width * 0.99, 0) controlPoint2: CGPointMake(size.width, size.height * 0.17)];
    [path addLineToPoint: CGPointMake(size.width * 0.99, size.height * 0.38)];
    [path addLineToPoint: CGPointMake(size.width * 0.99, 0)];
    [path closePath];
    [path moveToPoint: CGPointMake(size.width, size.height * 0.62)];
    [path addCurveToPoint: CGPointMake(size.width * 0.99, size.height) controlPoint1: CGPointMake(size.width, size.height * 0.83) controlPoint2: CGPointMake(size.width * 0.99, size.height)];
    [path addLineToPoint: CGPointMake(size.width * 0.99, size.height * 0.62)];
    [path addLineToPoint: CGPointMake(size.width, size.height * 0.62)];
    [path closePath];
    [path moveToPoint: CGPointMake(size.width * 0.99, size.height * 0.62)];
    [path addLineToPoint: CGPointMake(size.width, size.height * 0.62)];
    [path addLineToPoint: CGPointMake(size.width, size.height * 0.38)];
    [path addLineToPoint: CGPointMake(size.width * 0.99, size.height * 0.38)];
    [path addLineToPoint: CGPointMake(size.width * 0.99, size.height * 0.62)];
    [path closePath];
    [path moveToPoint: CGPointMake(0, size.height * 0.38)];
    [path addCurveToPoint: CGPointMake(size.width * 0.01, 0) controlPoint1: CGPointMake(0, size.height * 0.17) controlPoint2: CGPointMake(size.width * 0.01, 0)];
    [path addLineToPoint: CGPointMake(size.width * 0.01, size.height * 0.38)];
    [path addLineToPoint: CGPointMake(0, size.height * 0.38)];
    [path closePath];
    [path moveToPoint: CGPointMake(size.width * 0.01, size.height * 0.38)];
    [path addLineToPoint: CGPointMake(size.width * 0.01, size.height * 0.62)];
    [path addLineToPoint: CGPointMake(size.width * 0.01, size.height)];
    [path addCurveToPoint: CGPointMake(0, size.height * 0.62) controlPoint1: CGPointMake(size.width * 0.01, size.height) controlPoint2: CGPointMake(0, size.height * 0.83)];
    [path addLineToPoint: CGPointMake(0, size.height * 0.38)];
    [path addLineToPoint: CGPointMake(size.width * 0.01, size.height * 0.38)];
    [path addLineToPoint: CGPointMake(size.width * 0.01, size.height * 0.38)];
    
    [path closePath];
    return path;
}

+ (UIImage *)imageWithInnerShadowForFrame:(CGRect)frame andShadowOffset:(CGSize)shadowOffset andShadoBlurRadius:(CGFloat)shadowBlurRadius {
    //// General Declarations
    UIGraphicsBeginImageContextWithOptions(frame.size, NO, [[UIScreen mainScreen] scale]);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //// Shadow Declarations
    UIColor* shadow = [[UIColor blackColor] colorWithAlphaComponent: 0.63];
    
    //// Rectangle Drawing
    UIBezierPath* rectanglePath = [UIBezierPath bezierPathWithRect: frame];
    [[UIColor clearColor] setFill];
    [rectanglePath fill];
    
    ////// Rectangle Inner Shadow
    CGRect rectangleBorderRect = CGRectInset([rectanglePath bounds], -shadowBlurRadius, -shadowBlurRadius);
    rectangleBorderRect = CGRectOffset(rectangleBorderRect, -shadowOffset.width, -shadowOffset.height);
    rectangleBorderRect = CGRectInset(CGRectUnion(rectangleBorderRect, [rectanglePath bounds]), -1, -1);
    
    UIBezierPath* rectangleNegativePath = [UIBezierPath bezierPathWithRect: rectangleBorderRect];
    [rectangleNegativePath appendPath: rectanglePath];
    rectangleNegativePath.usesEvenOddFillRule = YES;
    
    CGContextSaveGState(context);
    {
        CGFloat xOffset = shadowOffset.width + round(rectangleBorderRect.size.width);
        CGFloat yOffset = shadowOffset.height;
        CGContextSetShadowWithColor(context,
                                    CGSizeMake(xOffset + copysign(0.1, xOffset), yOffset + copysign(0.1, yOffset)),
                                    shadowBlurRadius,
                                    shadow.CGColor);
        
        [rectanglePath addClip];
        CGAffineTransform transform = CGAffineTransformMakeTranslation(-round(rectangleBorderRect.size.width), 0);
        [rectangleNegativePath applyTransform: transform];
        [[UIColor grayColor] setFill];
        [rectangleNegativePath fill];
    }
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (void)closeKeyboardForView:(UIView *)view andSubviews:(BOOL)isSubViews {
    
    if (view.isFirstResponder) {
        [view resignFirstResponder];
    }
    
    if (isSubViews)
    {
        for (UIView *sview in view.subviews)
        {
            if ([sview respondsToSelector:@selector(isFirstResponder)]) {
                [self closeKeyboardForView:sview andSubviews:YES];
            }
        }
    }
}

+ (void)setLeftPaddingForTextFieldsForView:(UIView *)view andSubViews:(BOOL)isSubViews {
    if ([view isKindOfClass:[UITextField class]])
    {
        UITextField *textField = (UITextField *)view;
        textField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 1)];
        textField.leftViewMode = UITextFieldViewModeAlways;
    }
    if (isSubViews)
    {
        for (UIView *sview in view.subviews)
        {
            [self setLeftPaddingForTextFieldsForView:sview andSubViews:YES];
        }
    }
}

+ (void)setPlaceholderColor:(UIColor *)placeholderColor forView:(UIView *)view andSubViews:(BOOL)isSubViews {
    if ([view isKindOfClass:[UITextField class]])
    {
        UITextField *textField = (UITextField *)view;
        if (textField.placeholder.length > 0)
            textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:textField.placeholder attributes:@{NSForegroundColorAttributeName:placeholderColor}];
    }
    if (isSubViews)
    {
        for (UIView *sview in view.subviews)
        {
            [self setPlaceholderColor:placeholderColor forView:sview andSubViews:YES];
        }
    }
}

+ (void)selectTextForInput:(UITextView *)input atRange:(NSRange)range {
    UITextPosition *start = [input positionFromPosition:[input beginningOfDocument]
                                                 offset:range.location];
    UITextPosition *end = [input positionFromPosition:start
                                               offset:range.length];
    [input setSelectedTextRange:[input textRangeFromPosition:start toPosition:end]];
}
@end
