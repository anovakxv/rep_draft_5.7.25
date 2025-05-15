//
//  SkillsViewController.h
//  Gravity
//
//  Created by Vlad Getman on 03.02.15.
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SkillsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate> {
    NSArray *skills;
}

@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) void (^selectionBlock)(NSNumber *skillId);

@end
