//
//  PatnersDetailViewController.h
//  Goals
//
//  Created by Ahad on 9/6/14.
//  Copyright (c) 2014 ahad. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Portal.h"

@interface PortalDetailViewController : VGViewController <UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate> {
    
    IBOutlet UISegmentedControl *segmentedControl;
    IBOutlet UILabel *descriptionLabel;
    
    IBOutlet UITableViewCell *controlCell;
    IBOutlet UITableViewCell *leadCell;
    IBOutlet UITableViewCell *descriptionCell;
    IBOutlet UITableViewCell *deleteCell;
    
    IBOutlet UIButton *actionButton;
    IBOutlet UIButton *messagesButton;
    IBOutlet UIButton *deleteButton;
    
    Portal *portal;
    NSArray *goals;
    NSArray *products;
    NSArray *leads;
    
    UIRefreshControl *refreshControl;
    
    NSMutableDictionary *values;
}

@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) NSNumber *portalId;

- (IBAction)showActions;
- (IBAction)OnChangeSegmentedController:(id)sender;
- (IBAction)backAction;
- (IBAction)messageAction;
- (IBAction)deleteAction;

@end
