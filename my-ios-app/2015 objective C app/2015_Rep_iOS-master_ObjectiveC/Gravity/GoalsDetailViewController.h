//
//  GoalsDetailViewController.h
//  Goals
//
//  Created by Ahad on 9/6/14.
//  Copyright (c) 2014 ahad. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VGProgressBar.h"
#import "VGBarChart.h"

@interface GoalsDetailViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate, BarChartDataSource> {
    
    IBOutlet VGProgressBar *progressBar;
    IBOutlet VGBarChart *barChart;
    
    IBOutlet UILabel *goalTypeLabel;
    IBOutlet UILabel *metricLabel;
    IBOutlet UILabel *overalGoalLabel;
    IBOutlet UILabel *endDateLabel;
    IBOutlet UILabel *progressLabel;
    
    IBOutlet UIButton *actionButton;
    IBOutlet UIButton *messagesButton;
    
    IBOutlet UISegmentedControl *segmentedControl;
    
    IBOutlet UITableViewCell *reportCell;
    
    IBOutlet UIView *headerView;
    
    NSArray *feed;
    NSArray *barItems;
    NSArray *team;
}

@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) Goal *goal;
@property (nonatomic, strong) NSNumber *goalId;

- (IBAction)OnChangeSegmentedController:(id)sender;
- (IBAction)backAction;
- (IBAction)messageAction;
- (IBAction)showActions;

@end
