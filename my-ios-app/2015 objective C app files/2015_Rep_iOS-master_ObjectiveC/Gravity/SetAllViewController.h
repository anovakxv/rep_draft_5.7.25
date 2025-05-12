//
//  SetAllViewController.h
//  Gravity
//
//  Created by Vlad Getman on 24.02.15.
//  Copyright (c) 2015 HalcyonInnovation. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SetAllViewController : UIViewController <UITableViewDataSource, UITableViewDelegate> {
    NSArray *ecosystems;
    NSMutableSet *selectedEcosystems;
    
    IBOutlet UIButton *addBtn;
}

@property (nonatomic, strong) IBOutlet UITableView *tableView;

- (IBAction)addAll;

@end
