//
//  NewGoalViewController.h
//  Gravity
//
//  Created by Vlad Getman on 15.10.14.
//  Copyright (c) 2014 HalcyonInnovation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SZTextView.h>
#import "Portal.h"

@interface NewGoalViewController : VGViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UITextViewDelegate> {
    
    NSArray *types;
    NSArray *reporting;
    
    NSMutableDictionary *params;
    NSArray *titles;
    NSArray *keys;
    
    IBOutlet UIView *bottomBar;
    IBOutlet UIButton *deleteBtn;
}

@property (nonatomic, strong) IBOutlet UITableView *tableView;

@property (nonatomic, strong) NSNumber *portalId;
@property (nonatomic, strong) Goal *goal;
@property (nonatomic, strong) void (^completionBlock)();

@end
