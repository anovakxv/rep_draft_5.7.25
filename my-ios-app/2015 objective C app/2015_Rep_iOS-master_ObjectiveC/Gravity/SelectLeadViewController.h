//
//  SelectLeadViewController.h
//  Gravity
//
//  Created by Vlad Getman on 04.02.15.
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

#import "VGViewController.h"

@interface SelectLeadViewController : VGViewController <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate> {
    NSArray *users;
    
    NSMutableSet *ids;
}

@property (nonatomic, strong) IBOutlet UISearchBar *searchBar;
@property (nonatomic, strong) IBOutlet UITableView *tableView;

@property (nonatomic) BOOL multiselect;

@property (nonatomic, strong) NSString *leadId;
@property (nonatomic, strong) void (^pickBlock)(NSString *leadId);

@property (nonatomic, strong) NSArray *leadIds;
@property (nonatomic, strong) void (^multiPickBlock)(NSArray *leadIds);

@end
