//
//  ViewController.h
//  Goals
//
//  Created by Ahad on 9/5/14.
//  Copyright (c) 2014 ahad. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ImageButton.h"

@interface PeopleViewController : VGViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate> {
    IBOutlet UIView *menuView;
    NSArray *chats;
    NSArray *users;
    NSArray *network;
    
    UIRefreshControl *refreshControl;
    
    IBOutlet UITextField *searchField;
    
    ImageButton *profileBtn;
    BOOL animationInProgress;
}

@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet UISegmentedControl *segmentedControl;

- (IBAction)typeChanged:(UISegmentedControl *)sender;
- (IBAction)newChat;
- (IBAction)newTeam;
- (IBAction)switchView;
- (IBAction)textFieldDidChange:(UITextField *)textField;

@end
