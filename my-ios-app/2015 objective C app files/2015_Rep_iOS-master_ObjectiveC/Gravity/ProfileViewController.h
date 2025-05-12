//
//  PeopleDetailViewController.h
//  Goals
//
//  Created by Ahad on 9/6/14.
//  Copyright (c) 2014 ahad. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ChatViewController.h"
#import "Portal.h"

@interface ProfileViewController : VGViewController <UITableViewDataSource, UITableViewDelegate> {
    
    IBOutlet UIImageView *photoView;
    IBOutlet UILabel *infoLabel;
    IBOutlet UIView *headerView;
    IBOutlet UISegmentedControl *segmentedControl;
    
    IBOutlet UITableViewCell *aboutCell;
    IBOutlet UITableViewCell *broadcastCell;
    
    IBOutlet UILabel *broadcastLabel;
    IBOutlet UILabel *aboutLabel;
    IBOutlet UILabel *skillsLabel;
    
    IBOutlet UIButton *actionButton;
    IBOutlet UIButton *messagesButton;
    IBOutlet UIView *bottomBar;
    
    User *user;
    NSArray *goals;
    NSArray *portals;
    NSArray *shared;
}

@property (nonatomic, strong) IBOutlet UITableView *tableView;

@property (nonatomic, strong) NSNumber *userId;
@property (nonatomic) BOOL showMenu;

- (IBAction)backAction;
- (IBAction)messageAction;
- (IBAction)OnChangeSegmentedController:(id)sender;

@end
