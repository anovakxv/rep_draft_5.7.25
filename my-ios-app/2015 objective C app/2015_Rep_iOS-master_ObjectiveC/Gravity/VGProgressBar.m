//
//  VGProgressBar.m
//  Gravity
//
//  Created by Vlad Getman on 09.10.14.
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

#import "VGProgressBar.h"

@implementation VGProgressBar

- (instancetype)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    
    if (self) {
        [self setup];
    }
    return self;
}

-(void)setup{
    self.layer.borderColor = self.graphColor.CGColor;
    self.layer.borderWidth = 1;
}

- (void)drawRect:(CGRect)rect{
    
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGRect fillRect = rect;
    
    fillRect.size.width *= self.progress > 1.0 ? 1.0 : self.progress;
    CGContextSetFillColorWithColor(context, [self.graphColor CGColor]);
    CGContextFillRect(context, fillRect);
    
    if (self.showProgress) {
        UIFont *font = [UIFont fontWithName:@"Helvetica" size:11];
        
        CGContextSetFillColorWithColor(context, [[UIColor blackColor] CGColor]);
        CGContextSetFont(context, CGFontCreateWithFontName((__bridge CFStringRef)font.fontName));
        CGContextSetFontSize(context, 11);
        CGContextSetTextDrawingMode(context, kCGTextFill);
        
        NSString *progress = [NSString stringWithFormat:@"%.0f%%", self.progress * 100];
        CGFloat width = [UIUtils findWidthForText:progress
                                     havingHeight:30
                                          andFont:font];
        
        CGRect textRect = self.bounds;
        textRect.size.width = width + 5;
        textRect.size.height = font.pointSize + 4;
        textRect.origin.y = (rect.size.height - textRect.size.height) / 2;
        if (rect.size.width - fillRect.size.width < textRect.size.width) {
            textRect.origin.x = fillRect.size.width - textRect.size.width;
        } else {
            textRect.origin.x = fillRect.size.width + 5;
        }
        
        [progress drawInRect:textRect withAttributes:nil];
    }
}

- (void)setGraphColor:(UIColor *)graphColor {
    _graphColor = graphColor;
    self.layer.borderColor = self.graphColor.CGColor;
    [self setNeedsDisplay];
}

- (void)setProgress:(CGFloat)progress {
    _progress = progress;
    [self setNeedsDisplay];
}


@end
