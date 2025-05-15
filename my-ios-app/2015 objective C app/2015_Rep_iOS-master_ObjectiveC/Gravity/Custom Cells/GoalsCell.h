//
//  GoalsTableViewCell.h
//  Goals
//
//  Created by Ahad on 9/6/14.
//  Copyright (c) 2014 ahad. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Goal.h"
#import "VGProgressBar.h"
#import "VGBarChart.h"

@interface GoalsCell : UITableViewCell <BarChartDataSource> {
    NSArray *barItems;
}

@property (nonatomic, strong) Goal *goal;

@property (nonatomic, strong) IBOutlet UITextView *nameView;
@property (nonatomic, strong) IBOutlet UILabel *metricLabel;
@property (nonatomic, strong) IBOutlet UIButton *inviteBtn;
@property (nonatomic, strong) IBOutlet VGProgressBar *progressBar;
@property (nonatomic, strong) IBOutlet VGBarChart *barChart;

@property (nonatomic) BOOL preventSelection;

@end
