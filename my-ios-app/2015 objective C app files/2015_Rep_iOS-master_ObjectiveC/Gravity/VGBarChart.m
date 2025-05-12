//
//  VGBarChart.m
//  Gravity
//
//  Created by Vlad Getman on 19.01.15.
//  Copyright (c) 2015 HalcyonInnovation. All rights reserved.
//

#import "VGBarChart.h"

@implementation VGBarChart

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self initialize];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)initialize {
    self.barColor = [UIColor appGreen];
    self.clipsToBounds = YES;
    
    scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    scrollView.pagingEnabled = YES;
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.showsVerticalScrollIndicator = NO;
    [self addSubview:scrollView];
    
    views = [[NSMutableArray alloc] init];
    labels = [[NSMutableArray alloc] init];
    bottomLabels = [[NSMutableArray alloc] init];
    dashes = [[NSMutableArray alloc] init];
    
    leftArrow = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 20, 40)];
    [leftArrow setImage:[UIImage imageNamed:@"arrow_left"]
               forState:UIControlStateNormal];
    [leftArrow addTarget:self
                  action:@selector(scrollPageToLeft)
        forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:leftArrow];
    rightArrow = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 20, 40)];
    [rightArrow setImage:[UIImage imageNamed:@"arrow_right"]
               forState:UIControlStateNormal];
    [rightArrow addTarget:self
                  action:@selector(scrollPageToRight)
        forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:rightArrow];
}

- (void)scrollPageToLeft {
    CGPoint contentOffset = scrollView.contentOffset;
    if (contentOffset.x <= 0)
        return;
    
    contentOffset.x -= CGRectGetWidth(scrollView.frame);
    if (contentOffset.x < 0)
        contentOffset.x = 0;
    [scrollView setContentOffset:contentOffset animated:YES];
}

- (void)scrollPageToRight {
    CGFloat maxOffset = scrollView.contentSize.width - CGRectGetWidth(scrollView.frame);
    CGPoint contentOffset = scrollView.contentOffset;
    if (contentOffset.x >= maxOffset)
        return;
    
    contentOffset.x += CGRectGetWidth(scrollView.frame);
    if (contentOffset.x > maxOffset)
        contentOffset.x = maxOffset;
    [scrollView setContentOffset:contentOffset animated:YES];
}

- (void)drawRect:(CGRect)rect {
    [self reloadData];
}

- (void)reloadData {
    if (!self.dataSource)
        return;
    
    [self hideAllView];
    NSInteger numberOfBars = [self.dataSource numberOfBarsInBarChart:self];
    BOOL showArrows = numberOfBars > 4 || ![self isSmallView];
    CGFloat arrowsMargin = showArrows ? 10 : 0;
    
    CGFloat barWidth = CGRectGetWidth(self.frame) - arrowsMargin * 2;
    CGFloat borderPadding = barWidth / 30;
    CGFloat padding = barWidth / 6.5;
    CGFloat width = (barWidth - (borderPadding * 2) - (3 * padding)) / 4;
    CGFloat maxBarHeight = CGRectGetHeight(self.frame);
    
    leftArrow.center = CGPointMake(8, maxBarHeight / 2);
    rightArrow.center = CGPointMake(CGRectGetWidth(self.frame) - 8, maxBarHeight / 2);
    for (UIButton *btn in @[leftArrow, rightArrow]) {
        btn.hidden = !showArrows;
    }
    
    CGSize contentSize;
    contentSize.height = maxBarHeight;
    contentSize.width = numberOfBars * (width + padding) + borderPadding * 2 - padding + arrowsMargin * 2;
    
    scrollView.contentSize = contentSize;
    CGPoint contentOffset = CGPointMake(contentSize.width - barWidth - arrowsMargin * 2, 0);
    if (contentOffset.x < 0)
        contentOffset.x = 0;
    scrollView.contentOffset = contentOffset;
    
    BOOL showTexts = [self.dataSource respondsToSelector:@selector(barChart:textForBarAtIndex:)];
    BOOL showBottomsTexts = [self.dataSource respondsToSelector:@selector(barChart:bottomTextForBarAtIndex:)];
    
    if (showTexts)
        maxBarHeight -= 20;
    if (showBottomsTexts)
        maxBarHeight -= 20;
    
    if ([self.dataSource respondsToSelector:@selector(barChart:predictablePercentForBarAtIndex:)]) {
        maxBarHeight -= [self isSmallView] ? 3 : 6;
    }
    
    for (NSInteger i = 0; i < numberOfBars; i++) {
        UIView *barView = [self viewForIndex:i];
        barView.hidden = NO;
        if ([self.dataSource respondsToSelector:@selector(barChart:colorForBarAtIndex:)]) {
            barView.backgroundColor = [self.dataSource barChart:self colorForBarAtIndex:i];
        }
        CGFloat percent = [self.dataSource barChart:self
                               percentForBarAtIndex:i];
        if (percent > 1.0)
            percent = 1.0;
        
        CGRect frame;
        frame.origin.x = borderPadding + i * (padding + width);
        if (i == 0)
            frame.origin.x += arrowsMargin;
        frame.size.width = width;
        frame.size.height = maxBarHeight * percent;
        frame.origin.y = CGRectGetHeight(self.frame) - CGRectGetHeight(frame) - (showBottomsTexts ? 20 : 0);
        barView.frame = frame;
        
        CAShapeLayer *dash = [self dashForIndex:i];
        if ([self.dataSource respondsToSelector:@selector(barChart:predictablePercentForBarAtIndex:)]) {
            CGFloat predictablePercent = [self.dataSource barChart:self
                                   predictablePercentForBarAtIndex:i];
            CGFloat percent = [self.dataSource barChart:self
                                   percentForBarAtIndex:i];
            if (predictablePercent <= percent)
                predictablePercent = 0.0;
            else if (predictablePercent > 1.0)
                predictablePercent = 1.0;
            
            dash.hidden = predictablePercent == 0.0;
            
            CGFloat offset = [self isSmallView] ? 1 : 3;
            
            if (predictablePercent > 0.0) {
                CGRect frame;
                frame.origin.x = (borderPadding + i * (padding + width)) - offset;
                frame.size.width = width + offset * 2;
                frame.size.height = maxBarHeight * predictablePercent + offset * 2;
                frame.origin.y = CGRectGetHeight(self.frame) - CGRectGetHeight(frame) + offset;
                
                CGRect bounds = frame;
                bounds.origin = CGPointZero;
                CGFloat corner = [self isSmallView] ? 2 : 5;
                dash.path = [UIBezierPath bezierPathWithRoundedRect:bounds
                                                       cornerRadius:corner].CGPath;
                dash.frame = frame;
            }
        }
        if (showTexts) {
            UILabel *label = [self labelForIndex:i];
            label.hidden = NO;
            label.text = [self.dataSource barChart:self
                                 textForBarAtIndex:i];
            [label sizeToFit];
            CGPoint center;
            center.x = CGRectGetMidX(barView.frame);
            center.y = (dash.hidden ? CGRectGetMinY(barView.frame) : CGRectGetMinY(dash.frame)) - 7;
            label.center = center;
        }
        if (showBottomsTexts) {
            UILabel *label = [self bottomLabelForIndex:i];
            label.hidden = NO;
            label.text = [self.dataSource barChart:self
                           bottomTextForBarAtIndex:i];
            [label sizeToFit];
            CGPoint center;
            center.x = CGRectGetMidX(barView.frame);
            center.y = CGRectGetMaxY(barView.frame) + 10;
            label.center = center;
        }
    }
}

- (BOOL)isSmallView {
    return CGRectGetWidth(self.frame) < 150;
}

- (void)hideAllView {
    for (UIView *view in views) {
        view.hidden = YES;
    }
    for (UILabel *label in labels) {
        label.hidden = YES;
    }
    for (UILabel *label in bottomLabels) {
        label.hidden = YES;
    }
    for (CAShapeLayer *dash in dashes) {
        dash.hidden = YES;
    }
}

- (UIView *)viewForIndex:(NSInteger)index {
    if (index >= views.count) {
        UIView *view = [[UIView alloc] init];
        view.backgroundColor = self.barColor;
        view.hidden = YES;
        [scrollView addSubview:view];
        [views addObject:view];
        return view;
    }
    return views[index];
}

- (UILabel *)labelForIndex:(NSInteger)index {
    
    if (index >= labels.count) {
        UILabel *label = [[UILabel alloc] init];
        label.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:8];
        label.textColor = [UIColor blackColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.backgroundColor = [UIColor clearColor];
        label.hidden = YES;
        [scrollView addSubview:label];
        [labels addObject:label];
        return label;
    }
    return labels[index];
}

- (UILabel *)bottomLabelForIndex:(NSInteger)index {
    
    if (index >= bottomLabels.count) {
        UILabel *label = [[UILabel alloc] init];
        label.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:8];
        label.textColor = [UIColor blackColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.backgroundColor = [UIColor clearColor];
        label.hidden = YES;
        [scrollView addSubview:label];
        [bottomLabels addObject:label];
        return label;
    }
    return bottomLabels[index];
}

- (CAShapeLayer *)dashForIndex:(NSInteger)index {
    
    if (index >= dashes.count) {
        CAShapeLayer *dash = [CAShapeLayer layer];
        dash.strokeColor = UIColorFromRGB(0xe4e4e4).CGColor;
        dash.fillColor = nil;
        dash.lineDashPattern = @[@2, @2];
        dash.lineWidth = [self isSmallView] ? 1 : 3;
        dash.hidden = YES;
        [scrollView.layer addSublayer:dash];
        [dashes addObject:dash];
        return dash;
    }
    
    return dashes[index];
}

@end
