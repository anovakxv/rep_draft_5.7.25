//
//  PatnersViewController.h
//  Goals
//
//  Created by Ahad on 9/6/14.
//  Copyright (c) 2014 ahad. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ImageButton.h"

@interface PortalsViewController : VGViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate> {
    IBOutlet UIView *menuView;
    NSArray *allPortals;
    NSArray *networkPortals;
    NSArray *openPortals;
    UIRefreshControl *refreshControl;
    
    ImageButton *profileBtn;
    
    IBOutlet UITextField *searchField;
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
