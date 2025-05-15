//
//  VGBarChart.h
//  Gravity
//
//  Created by Vlad Getman on 19.01.15.
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class VGBarChart;

@protocol BarChartDataSource <NSObject>

@required

- (NSUInteger)numberOfBarsInBarChart:(VGBarChart *)barChart;
- (CGFloat)barChart:(VGBarChart *)barChart percentForBarAtIndex:(NSUInteger)index;

@optional

- (CGFloat)barChart:(VGBarChart *)barChart predictablePercentForBarAtIndex:(NSUInteger)index;
- (UIColor *)barChart:(VGBarChart *)barChart colorForBarAtIndex:(NSUInteger)index;
- (NSString *)barChart:(VGBarChart *)barChart textForBarAtIndex:(NSUInteger)index;
- (NSString *)barChart:(VGBarChart *)barChart bottomTextForBarAtIndex:(NSUInteger)index;

@end

@interface VGBarChart : UIView {
    NSMutableArray *views;
    NSMutableArray *labels;
    NSMutableArray *bottomLabels;
    NSMutableArray *dashes;
    
    UIButton *leftArrow;
    UIButton *rightArrow;
    UIScrollView *scrollView;
}

@property (weak, nonatomic) IBOutlet id <BarChartDataSource> dataSource;
@property (nonatomic, strong) UIColor *barColor;

- (void)reloadData;

@end
