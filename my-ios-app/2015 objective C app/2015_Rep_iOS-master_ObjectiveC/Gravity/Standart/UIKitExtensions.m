//
//  UIKitExtensions.m
//  iPhoneTools
//
//  Created by Nick Profitt on 11/14/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "UIKitExtensions.h"
@import Accelerate;
#import <float.h>

@implementation UIViewController (UIKitExtensions)

- (void)presentTransparentController:(UIViewController *)controller animated:(BOOL)animated {
    if (iOSVersion >= 8.0) {
        controller.providesPresentationContextTransitionStyle = YES;
        controller.definesPresentationContext = YES;
        controller.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    } else {
        self.navigationController.modalPresentationStyle = UIModalPresentationCurrentContext;
    }
    UIViewController *vc = self.navigationController ? self.navigationController : self;
    [vc presentViewController:controller animated:animated completion:NULL];
}

@end

@implementation UIImage (UIKitExtensions)

#pragma mark Resize Image

- (UIImage *)convertImageToGrayScale
{
    // Create image rectangle with current image width/height
    CGRect imageRect = CGRectMake(0, 0, self.size.width, self.size.height);
    
    // Grayscale color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    
    // Create bitmap content with current image size and grayscale colorspace
    CGContextRef context = CGBitmapContextCreate(nil, self.size.width, self.size.height, 8, 0, colorSpace, kCGImageAlphaNone);
    
    // Draw image into current context, with specified rectangle
    // using previously defined context (with grayscale colorspace)
    CGContextDrawImage(context, imageRect, [self CGImage]);
    
    // Create bitmap image info from pixel data in current context
    CGImageRef imageRef = CGBitmapContextCreateImage(context);
    
    // Create a new UIImage object
    UIImage *newImage = [UIImage imageWithCGImage:imageRef];
    
    // Release colorspace, context and bitmap information
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    CFRelease(imageRef);
    
    // Return the new grayscale image
    return newImage;
}


- (UIImage *)applyTintWithColor:(UIColor *)tintColor {
    
    
    UIGraphicsBeginImageContextWithOptions (self.size, NO, [[UIScreen mainScreen] scale]); // for correct resolution on retina, thanks @MobileVet
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextTranslateCTM(context, 0, self.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    CGRect rect = CGRectMake(0, 0, self.size.width, self.size.height);
    
    // image drawing code here
    CGContextSetBlendMode(context, kCGBlendModeNormal);
    CGContextDrawImage(context, rect, self.CGImage);
    
    // draw tint color, preserving alpha values of original image
    CGContextSetBlendMode(context, kCGBlendModeSourceIn);
    [tintColor setFill];
    CGContextFillRect(context, rect);
    
    UIImage *coloredImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return coloredImage;
}



- (UIImage *)resizedImage:(CGSize)newSize
{
	UIGraphicsBeginImageContext(newSize);
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextTranslateCTM(context, 0.0, newSize.height);
	CGContextScaleCTM(context, 1.0, -1.0);
	
	CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, newSize.width, newSize.height), self.CGImage);
	
	UIImage * scaledImage = UIGraphicsGetImageFromCurrentImageContext();
	
	UIGraphicsEndImageContext();
	
	return scaledImage;
}

- (UIImage *)generateClearRect:(CGRect)frameRect inRect:(CGRect)frame {
    
    UIColor *color = [UIColor colorWithWhite:0 alpha:0.5];
    
    UIGraphicsBeginImageContextWithOptions(frame.size, NO, 0);
    [color setFill];
    UIRectFill(frame);   // Fill it with your color
    
    // Clip to the bezier path and clear that portion of the image.
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextClearRect(context,frameRect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

- (UIImage *)stretchableImageWithCapInsets:(UIEdgeInsets)capInsets
{
    return [self resizableImageWithCapInsets:capInsets
                                resizingMode:UIImageResizingModeStretch];
}

- (NSArray *)detectFaces {
    CIImage* image = [CIImage imageWithCGImage:self.CGImage];
    
    CIDetector* detector = [CIDetector detectorOfType:CIDetectorTypeFace
                                              context:nil options:[NSDictionary dictionaryWithObject:CIDetectorAccuracyLow forKey:CIDetectorAccuracy]];
    
    NSArray* faces = [detector featuresInImage:image];
    
    return faces;
}

- (UIImage *)applyLightEffect
{
    UIColor *tintColor = [UIColor colorWithWhite:1.0 alpha:0.3];
    return [self applyBlurWithRadius:30 tintColor:tintColor saturationDeltaFactor:1.8 maskImage:nil];
}


- (UIImage *)applyExtraLightEffect
{
    UIColor *tintColor = [UIColor colorWithWhite:0.97 alpha:0.82];
    return [self applyBlurWithRadius:20 tintColor:tintColor saturationDeltaFactor:1.8 maskImage:nil];
}


- (UIImage *)applyDarkEffect
{
    UIColor *tintColor = [UIColor colorWithWhite:0.11 alpha:0.73];
    return [self applyBlurWithRadius:20 tintColor:tintColor saturationDeltaFactor:1.8 maskImage:nil];
}


- (UIImage *)applyTintEffectWithColor:(UIColor *)tintColor
{
    const CGFloat EffectColorAlpha = 0.6;
    UIColor *effectColor = tintColor;
    NSInteger componentCount = CGColorGetNumberOfComponents(tintColor.CGColor);
    if (componentCount == 2) {
        CGFloat b;
        if ([tintColor getWhite:&b alpha:NULL]) {
            effectColor = [UIColor colorWithWhite:b alpha:EffectColorAlpha];
        }
    }
    else {
        CGFloat r, g, b;
        if ([tintColor getRed:&r green:&g blue:&b alpha:NULL]) {
            effectColor = [UIColor colorWithRed:r green:g blue:b alpha:EffectColorAlpha];
        }
    }
    return [self applyBlurWithRadius:10 tintColor:effectColor saturationDeltaFactor:-1.0 maskImage:nil];
}


- (UIImage *)applyBlurWithRadius:(CGFloat)blurRadius tintColor:(UIColor *)tintColor saturationDeltaFactor:(CGFloat)saturationDeltaFactor maskImage:(UIImage *)maskImage
{
    // Check pre-conditions.
    if (self.size.width < 1 || self.size.height < 1) {
        NSLog (@"*** error: invalid size: (%.2f x %.2f). Both dimensions must be >= 1: %@", self.size.width, self.size.height, self);
        return nil;
    }
    if (!self.CGImage) {
        NSLog (@"*** error: image must be backed by a CGImage: %@", self);
        return nil;
    }
    if (maskImage && !maskImage.CGImage) {
        NSLog (@"*** error: maskImage must be backed by a CGImage: %@", maskImage);
        return nil;
    }
    
    CGRect imageRect = { CGPointZero, self.size };
    UIImage *effectImage = self;
    
    BOOL hasBlur = blurRadius > __FLT_EPSILON__;
    BOOL hasSaturationChange = fabs(saturationDeltaFactor - 1.) > __FLT_EPSILON__;
    if (hasBlur || hasSaturationChange) {
        UIGraphicsBeginImageContextWithOptions(self.size, NO, [[UIScreen mainScreen] scale]);
        CGContextRef effectInContext = UIGraphicsGetCurrentContext();
        CGContextScaleCTM(effectInContext, 1.0, -1.0);
        CGContextTranslateCTM(effectInContext, 0, -self.size.height);
        CGContextDrawImage(effectInContext, imageRect, self.CGImage);
        
        vImage_Buffer effectInBuffer;
        effectInBuffer.data     = CGBitmapContextGetData(effectInContext);
        effectInBuffer.width    = CGBitmapContextGetWidth(effectInContext);
        effectInBuffer.height   = CGBitmapContextGetHeight(effectInContext);
        effectInBuffer.rowBytes = CGBitmapContextGetBytesPerRow(effectInContext);
        
        UIGraphicsBeginImageContextWithOptions(self.size, NO, [[UIScreen mainScreen] scale]);
        CGContextRef effectOutContext = UIGraphicsGetCurrentContext();
        vImage_Buffer effectOutBuffer;
        effectOutBuffer.data     = CGBitmapContextGetData(effectOutContext);
        effectOutBuffer.width    = CGBitmapContextGetWidth(effectOutContext);
        effectOutBuffer.height   = CGBitmapContextGetHeight(effectOutContext);
        effectOutBuffer.rowBytes = CGBitmapContextGetBytesPerRow(effectOutContext);
        
        if (hasBlur) {
            // A description of how to compute the box kernel width from the Gaussian
            // radius (aka standard deviation) appears in the SVG spec:
            // http://www.w3.org/TR/SVG/filters.html#feGaussianBlurElement
            //
            // For larger values of 's' (s >= 2.0), an approximation can be used: Three
            // successive box-blurs build a piece-wise quadratic convolution kernel, which
            // approximates the Gaussian kernel to within roughly 3%.
            //
            // let d = floor(s * 3*sqrt(2*pi)/4 + 0.5)
            //
            // ... if d is odd, use three box-blurs of size 'd', centered on the output pixel.
            //
            CGFloat inputRadius = blurRadius * [[UIScreen mainScreen] scale];
            uint32_t radius = floor(inputRadius * 3. * sqrt(2 * M_PI) / 4 + 0.5);
            if (radius % 2 != 1) {
                radius += 1; // force radius to be odd so that the three box-blur methodology works.
            }
            vImageBoxConvolve_ARGB8888(&effectInBuffer, &effectOutBuffer, NULL, 0, 0, radius, radius, 0, kvImageEdgeExtend);
            vImageBoxConvolve_ARGB8888(&effectOutBuffer, &effectInBuffer, NULL, 0, 0, radius, radius, 0, kvImageEdgeExtend);
            vImageBoxConvolve_ARGB8888(&effectInBuffer, &effectOutBuffer, NULL, 0, 0, radius, radius, 0, kvImageEdgeExtend);
        }
        BOOL effectImageBuffersAreSwapped = NO;
        if (hasSaturationChange) {
            CGFloat s = saturationDeltaFactor;
            CGFloat floatingPointSaturationMatrix[] = {
                0.0722 + 0.9278 * s,  0.0722 - 0.0722 * s,  0.0722 - 0.0722 * s,  0,
                0.7152 - 0.7152 * s,  0.7152 + 0.2848 * s,  0.7152 - 0.7152 * s,  0,
                0.2126 - 0.2126 * s,  0.2126 - 0.2126 * s,  0.2126 + 0.7873 * s,  0,
                0,                    0,                    0,  1,
            };
            const int32_t divisor = 256;
            NSUInteger matrixSize = sizeof(floatingPointSaturationMatrix)/sizeof(floatingPointSaturationMatrix[0]);
            int16_t saturationMatrix[matrixSize];
            for (NSUInteger i = 0; i < matrixSize; ++i) {
                saturationMatrix[i] = (int16_t)roundf(floatingPointSaturationMatrix[i] * divisor);
            }
            if (hasBlur) {
                vImageMatrixMultiply_ARGB8888(&effectOutBuffer, &effectInBuffer, saturationMatrix, divisor, NULL, NULL, kvImageNoFlags);
                effectImageBuffersAreSwapped = YES;
            }
            else {
                vImageMatrixMultiply_ARGB8888(&effectInBuffer, &effectOutBuffer, saturationMatrix, divisor, NULL, NULL, kvImageNoFlags);
            }
        }
        if (!effectImageBuffersAreSwapped)
            effectImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        if (effectImageBuffersAreSwapped)
            effectImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    
    // Set up output context.
    UIGraphicsBeginImageContextWithOptions(self.size, NO, [[UIScreen mainScreen] scale]);
    CGContextRef outputContext = UIGraphicsGetCurrentContext();
    CGContextScaleCTM(outputContext, 1.0, -1.0);
    CGContextTranslateCTM(outputContext, 0, -self.size.height);
    
    // Draw base image.
    CGContextDrawImage(outputContext, imageRect, self.CGImage);
    
    // Draw effect image.
    if (hasBlur) {
        CGContextSaveGState(outputContext);
        if (maskImage) {
            CGContextClipToMask(outputContext, imageRect, maskImage.CGImage);
        }
        CGContextDrawImage(outputContext, imageRect, effectImage.CGImage);
        CGContextRestoreGState(outputContext);
    }
    
    // Add in color tint.
    if (tintColor) {
        CGContextSaveGState(outputContext);
        CGContextSetFillColorWithColor(outputContext, tintColor.CGColor);
        CGContextFillRect(outputContext, imageRect);
        CGContextRestoreGState(outputContext);
    }
    
    // Output image is ready.
    UIImage *outputImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return outputImage;
}

- (UIImage *)imageByApplyingAlpha:(CGFloat) alpha {
    UIGraphicsBeginImageContextWithOptions(self.size, NO, 0.0f);
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGRect area = CGRectMake(0, 0, self.size.width, self.size.height);
    
    CGContextScaleCTM(ctx, 1, -1);
    CGContextTranslateCTM(ctx, 0, -area.size.height);
    
    CGContextSetBlendMode(ctx, kCGBlendModeMultiply);
    
    CGContextSetAlpha(ctx, alpha);
    
    CGContextDrawImage(ctx, area, self.CGImage);
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return newImage;
}

@end

@implementation NSMutableAttributedString (UIKitExtensions)

- (void)addColor:(UIColor *)color substring:(NSString *)substring{
    
    if (!substring || !color) return;
    
    NSRange searchRange = NSMakeRange(0,self.string.length);
    NSRange foundRange;
    while (searchRange.location < self.string.length) {
        searchRange.length = self.string.length-searchRange.location;
        foundRange = [self.string rangeOfString:substring options:NSCaseInsensitiveSearch range:searchRange];
        if (foundRange.location != NSNotFound) {
            [self addAttribute:NSForegroundColorAttributeName
                         value:color
                         range:foundRange];
            
            searchRange.location = foundRange.location+1;
            
        } else {
            // no more substring to find
            break;
        }
    }
}

- (void)addBackgroundColor:(UIColor *)color substring:(NSString *)substring{
    NSRange range = [self.string rangeOfString:substring];
    if (range.location != NSNotFound) {
        [self addAttribute:NSBackgroundColorAttributeName
                     value:color
                     range:range];
    }
}
- (void)addUnderlineForSubstring:(NSString *)substring{
    NSRange range = [self.string rangeOfString:substring];
    if (range.location != NSNotFound) {
        [self addAttribute: NSUnderlineStyleAttributeName
                     value:@(NSUnderlineStyleSingle)
                     range:range];
    }
}
- (void)addStrikeThrough:(int)thickness substring:(NSString *)substring{
    NSRange range = [self.string rangeOfString:substring];
    if (range.location != NSNotFound) {
        [self addAttribute: NSStrikethroughStyleAttributeName
                     value:@(thickness)
                     range:range];
    }
}
- (void)addShadowColor:(UIColor *)color width:(int)width height:(int)height radius:(int)radius substring:(NSString *)substring{
    NSRange range = [self.string rangeOfString:substring];
    if (range.location != NSNotFound && color != nil) {
        NSShadow *shadow = [[NSShadow alloc] init];
        [shadow setShadowColor:color];
        [shadow setShadowOffset:CGSizeMake (width, height)];
        [shadow setShadowBlurRadius:radius];
        
        [self addAttribute: NSShadowAttributeName
                     value:shadow
                     range:range];
    }
}
- (void)addFontWithName:(NSString *)fontName size:(int)fontSize substring:(NSString *)substring{
    
    if (!substring) return;
    
    NSRange range = [self.string rangeOfString:substring];
    if (range.location != NSNotFound && fontName != nil) {
        UIFont * font = [UIFont fontWithName:fontName size:fontSize];
        [self addAttributes:@{NSFontAttributeName:font} range:range];
    }
}

- (void)addFont:(UIFont *)font substring:(NSString *)substring {
    
    if (!substring) return;
    
    NSRange range = [self.string rangeOfString:substring];
    if (range.location != NSNotFound && font != nil) {
        [self addAttributes:@{NSFontAttributeName:font} range:range];
    }
}

- (void)addAlignment:(NSTextAlignment)alignment substring:(NSString *)substring{
    NSRange range = [self.string rangeOfString:substring];
    if (range.location != NSNotFound) {
        NSMutableParagraphStyle* style=[[NSMutableParagraphStyle alloc]init];
        style.alignment = alignment;
        [self addAttribute: NSParagraphStyleAttributeName
                     value:style
                     range:range];
    }
}
- (void)addColorToRussianText:(UIColor *)color{
    
    if(color == nil) return;
    
    NSCharacterSet * set = [NSCharacterSet characterSetWithCharactersInString:@"абвгдеёжзийклмнопрстуфхцчшщъыьэюяАБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ"];
    
    NSRange searchRange = NSMakeRange(0,self.string.length);
    NSRange foundRange;
    while (searchRange.location < self.string.length) {
        searchRange.length = self.string.length-searchRange.location;
        foundRange = [self.string rangeOfCharacterFromSet:set options:NSCaseInsensitiveSearch range:searchRange];
        if (foundRange.location != NSNotFound) {
            [self addAttribute:NSForegroundColorAttributeName
                         value:color
                         range:foundRange];
            
            searchRange.location = foundRange.location+1;
            
        } else {
            // no more substring to find
            break;
        }
    }
}
- (void)addStrokeColor:(UIColor *)color thickness:(int)thickness substring:(NSString *)substring{
    NSRange range = [self.string rangeOfString:substring];
    if (range.location != NSNotFound && color != nil) {
        [self addAttribute:NSStrokeColorAttributeName
                     value:color
                     range:range];
        [self addAttribute:NSStrokeWidthAttributeName
                     value:@(thickness)
                     range:range];
    }
}
- (void)addVerticalGlyph:(BOOL)glyph substring:(NSString *)substring{
    NSRange range = [self.string rangeOfString:substring];
    if (range.location != NSNotFound) {
        [self addAttribute:NSForegroundColorAttributeName
                     value:@(glyph)
                     range:range];
    }
}

@end

@implementation NSString (UIKitExtensions)

- (BOOL)hasRussianCharacters{
    NSCharacterSet * set = [NSCharacterSet characterSetWithCharactersInString:@"абвгдеёжзийклмнопрстуфхцчшщъыьэюяАБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ"];
    return [self rangeOfCharacterFromSet:set].location != NSNotFound;
}
- (BOOL)hasEnglishCharacters{
    NSCharacterSet * set = [NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"];
    return [self rangeOfCharacterFromSet:set].location != NSNotFound;
}

- (NSString*)stringBetweenString:(NSString*)start
                       andString:(NSString*)end
{
    NSScanner* scanner = [NSScanner scannerWithString:self];
    [scanner setCharactersToBeSkipped:nil];
    [scanner scanUpToString:start intoString:NULL];
    if ([scanner scanString:start intoString:NULL]) {
        NSString* result = nil;
        if ([scanner scanUpToString:end intoString:&result]) {
            return result;
        }
    }
    return nil;
}

- (NSString *)cropTimeDuration {
    
    if (self.length == 0) {
        return self;
    }
    
    NSMutableString *string = [[NSMutableString alloc] initWithString:self];
    
    do {
        [string deleteCharactersInRange:NSMakeRange(0, 1)];
    } while (([[string substringToIndex:1] isEqual:@" "] ||
             [[string substringToIndex:1] isEqual:@"0"] ||
             [[string substringToIndex:1] isEqual:@":"]) &&
             string.length > 4);
    
    [string replaceOccurrencesOfString:@":" withString:@"." options:NSLiteralSearch range:NSMakeRange(0, string.length)];
    
    return string;
}

#pragma mark String Manipulation

- (NSString *)stringByStrippingHTMLTags
{
	NSRange tagRange = [self rangeOfString:@"<"];
	
	if(tagRange.length == 0)
	{
		return [NSString stringWithString:self];
	}
	
	NSMutableString * resultString = [NSMutableString stringWithString:self];
	NSScanner * htmlScanner = [NSScanner scannerWithString:self];
	
	while(tagRange.length > 0)
	{
		NSString * htmlTag = @"";
		
		[htmlScanner setScanLocation:tagRange.location];
		[htmlScanner scanUpToString:@">" intoString:&htmlTag];
		
		if([htmlScanner isAtEnd])
		{
			return resultString;
		}
		
		htmlTag = [htmlTag stringByAppendingString:@">"];
        
        if([htmlTag rangeOfString:@"<br"].length > 0)
        {
            [resultString replaceOccurrencesOfString:htmlTag withString:@"\n" options:NSCaseInsensitiveSearch range:NSMakeRange(0, resultString.length)];
        }
        else if([htmlTag rangeOfString:@"<li"].length > 0)
        {
            [resultString replaceOccurrencesOfString:htmlTag withString:@"\n\t" options:NSCaseInsensitiveSearch range:NSMakeRange(0, resultString.length)];
        }
		else
        {
            [resultString replaceOccurrencesOfString:htmlTag withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, resultString.length)];
        }
		
		NSRange searchRange = NSMakeRange(tagRange.location + htmlTag.length, self.length - (tagRange.location + htmlTag.length));
		tagRange = [self rangeOfString:@"<" options:NSCaseInsensitiveSearch range:searchRange];
	}
    
    tagRange = [self rangeOfString:@"&"];
	
	if(tagRange.length == 0)
	{
		return resultString;
	}
    
    while(tagRange.length > 0)
	{
		NSString * htmlTag = @"";
		
		[htmlScanner setScanLocation:tagRange.location];
		[htmlScanner scanUpToString:@";" intoString:&htmlTag];
		
		if([htmlScanner isAtEnd])
		{
			return resultString;
		}
		
		htmlTag = [htmlTag stringByAppendingString:@";"];
        
        if(htmlTag.length > 10)
        {
            continue;
        }
        
        [resultString replaceOccurrencesOfString:htmlTag withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, resultString.length)];
		
		NSRange searchRange = NSMakeRange(tagRange.location + htmlTag.length, self.length - (tagRange.location + htmlTag.length));
		tagRange = [self rangeOfString:@"&" options:NSCaseInsensitiveSearch range:searchRange];
	}
	
	return resultString;
}

- (NSString *)stringByStrippingHTMLItems {
    
    NSString *string = self;
    string = [string stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
    string = [string stringByReplacingOccurrencesOfString:@"&#039;" withString:@"'"];
    string = [string stringByReplacingOccurrencesOfString:@"&quot;" withString:@"\""];
    string = [string stringByReplacingOccurrencesOfString:@"&lt;" withString:@"<"];
    string = [string stringByReplacingOccurrencesOfString:@"&gt;" withString:@">"];
    
    return string;
}

- (NSString *)fileName
{
    NSRange lastSlash = [self rangeOfString:@"/" options:NSBackwardsSearch];
    
    if(lastSlash.length == 0)
    {
        return nil;
    }
    
    return [self substringFromIndex:lastSlash.location + lastSlash.length];
}

- (NSString *)onlyNumbers {
    NSString *strippedNumber = [self stringByReplacingOccurrencesOfString:@"[^0-9]" withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, [self length])];
    return strippedNumber;
}

@end


@implementation NSArray (UIKitExtensions)

- (NSString *)toString {
    
    NSMutableString *ids = [NSMutableString new];
    for (NSString *string in self) {
        [ids appendFormat:@"%@,", string];
    }
    [ids deleteCharactersInRange:NSMakeRange(ids.length - 1, 1)];
    
    return ids;
}

@end

@implementation NSMutableArray (UIKitExtensions)

- (void)moveObjectAtIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex
{
    id object = [self objectAtIndex:fromIndex];
    [self removeObjectAtIndex:fromIndex];
    [self insertObject:object atIndex:toIndex];
}

@end


@implementation NSDate (UIKitExtensions)


#pragma mark Date Conversion

- (NSString *)stringWithFormat:(NSString *)dateFormat
{
	NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:dateFormat];
    dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US"];
	NSString * dateString = [dateFormatter stringFromDate:self];
	
	//[dateFormatter release];
	
	return dateString;
}

+ (NSDate *)dateFromString:(NSString *)dateString dateFormat:(NSString *)dateFormat
{
	NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:dateFormat];
	
	NSDate * date = [dateFormatter dateFromString:dateString];
	
	return date;
}

- (NSDate *)currentTimezone {
    NSTimeZone* sourceTimeZone = [[NSTimeZone alloc] initWithName:@"GMT-03:00"];
    NSTimeZone* destinationTimeZone = [NSTimeZone systemTimeZone];
    
    NSInteger sourceGMTOffset = [sourceTimeZone secondsFromGMTForDate:self];
    NSInteger destinationGMTOffset = [destinationTimeZone secondsFromGMTForDate:self];
    NSTimeInterval interval = destinationGMTOffset - sourceGMTOffset;
    long timestamp = [self timeIntervalSince1970] + interval;
    NSDate *unixTime = [[NSDate alloc] initWithTimeIntervalSince1970:timestamp];
    
    return unixTime;
}

#pragma mark Comparing

- (BOOL)isBetweenInclusive:(NSDate *)startDate endDate:(NSDate *)endDate
{
	return [self compare:startDate] != NSOrderedAscending && [self compare:endDate] != NSOrderedDescending;
}

- (BOOL)isToday {
    NSDateComponents *otherDay = [[NSCalendar currentCalendar] components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:self];
    NSDateComponents *today = [[NSCalendar currentCalendar] components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:[NSDate date]];
    if([today day] == [otherDay day] &&
       [today month] == [otherDay month] &&
       [today year] == [otherDay year] &&
       [today era] == [otherDay era]) {
        return YES;
    } else {
        return NO;
    }
}

@end

@implementation UIColor (UIKitExtensions)

#pragma mark Universal Colors

+ (UIColor *) colorFromHexString:(NSString *)hexString alpha: (CGFloat)alpha{
    NSString *cleanString = [hexString stringByReplacingOccurrencesOfString:@"#" withString:@""];
    if([cleanString length] == 3) {
        cleanString = [NSString stringWithFormat:@"%@%@%@%@%@%@",
                       [cleanString substringWithRange:NSMakeRange(0, 1)],[cleanString substringWithRange:NSMakeRange(0, 1)],
                       [cleanString substringWithRange:NSMakeRange(1, 1)],[cleanString substringWithRange:NSMakeRange(1, 1)],
                       [cleanString substringWithRange:NSMakeRange(2, 1)],[cleanString substringWithRange:NSMakeRange(2, 1)]];
    }
    if([cleanString length] == 6) {
        cleanString = [cleanString stringByAppendingString:@"ff"];
    }
    
    unsigned int baseValue;
    [[NSScanner scannerWithString:cleanString] scanHexInt:&baseValue];
    
    float red = ((baseValue >> 24) & 0xFF)/255.0f;
    float green = ((baseValue >> 16) & 0xFF)/255.0f;
    float blue = ((baseValue >> 8) & 0xFF)/255.0f;
    
    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

+ (UIColor *)appGreen {
    return [UIColor colorFromHexString:@"#8CC75D" alpha:1.0];
}

@end

@implementation NSNumber (UIKitExtensions)

- (NSString *)scaleNumber {
    NSInteger number = self.integerValue;
    CGFloat scaled = 0;
    NSString *letter = @"";
    NSString *scaledString;
    
    if (number >= 1000000000) {
        scaled = (CGFloat)number / 1000000000.0f;
        scaledString = [NSString stringWithFormat:@"%0.1f", scaled];
        letter = @"G";
    } else if (number >= 1000000) {
        scaled = (CGFloat)number / 1000000.0f;
        scaledString = [NSString stringWithFormat:@"%0.1f", scaled];
        letter = @"M";
    } else if (number >= 1000) {
        scaled = (CGFloat)number / 1000.0f;
        scaledString = [NSString stringWithFormat:@"%0.1f", scaled];
        letter = @"K";
    } else {
        scaledString = self.stringValue;
    }
    if ([scaledString hasSuffix:@".0"]) {
        scaledString = [scaledString substringToIndex:scaledString.length - 2];
    }
    
    scaledString = [NSString stringWithFormat:@"%@%@", scaledString, letter];
    
    return scaledString;
}

- (NSString *)priceValue {
    NSNumberFormatter *price = [[NSNumberFormatter alloc] init];
    [price setNumberStyle:NSNumberFormatterCurrencyStyle];
    [price setCurrencyCode:@"USD"];
    [price setMaximumFractionDigits:2];
    
    BOOL isInteger = !fmod(self.floatValue, 1.0);
    
    if (isInteger)
        [price setMinimumFractionDigits:0];
    
    return [price stringFromNumber:self];
}

- (NSString *)formattedString {
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    return [formatter stringFromNumber:self];
}

@end

@implementation UIButton (UIKitExtensions)

- (void)backgroundToImage {
    [self setBackgroundImage:[UIUtils imageWithSize:self.frame.size
                                           andColor:self.backgroundColor]
                    forState:UIControlStateNormal];
    self.backgroundColor = nil;
    self.layer.masksToBounds = YES;
}

- (void)centerContent {
    // the space between the image and text
    CGFloat spacing = 6.0;
    
    // lower the text and push it left so it appears centered
    //  below the image
    CGSize imageSize = self.imageView.frame.size;
    self.titleEdgeInsets = UIEdgeInsetsMake(0.0, - imageSize.width, - (imageSize.height + spacing), 0.0);
    
    // raise the image and push it right so it appears centered
    //  above the text
    CGSize titleSize = self.titleLabel.frame.size;
    self.imageEdgeInsets = UIEdgeInsetsMake(- (titleSize.height + spacing), 0.0, 0.0, 0- titleSize.width);
}

@end

@implementation UITableView (UIKitExtensions)

- (void) scrollTableViewToBottomAnimated:(BOOL)animated
{
    NSInteger lastRowIdx = [self numberOfRowsInSection:0] - 1;
    
    if (lastRowIdx >= 0)
    {
        [self scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:lastRowIdx inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:animated];
    }
}

- (void)registerCellClass:(id)cell {
    
    [self registerCellClass:cell withIdentifier:@"cellIdentifier"];
}

- (void)registerCellClass:(id)cell withIdentifier:(NSString *)identifier {
    [self registerClass:cell forCellReuseIdentifier:identifier];
    [self registerNib:[UINib nibWithNibName:NSStringFromClass(cell) bundle:nil] forCellReuseIdentifier:identifier];
}

@end

@implementation UICollectionView (UIKitExtensions)

- (void)registerCellClass:(id)cell {
    
    [self registerClass:cell forCellWithReuseIdentifier:@"cellIdentifier"];
    [self registerNib:[UINib nibWithNibName:NSStringFromClass(cell) bundle:nil] forCellWithReuseIdentifier:@"cellIdentifier"];
}

@end

