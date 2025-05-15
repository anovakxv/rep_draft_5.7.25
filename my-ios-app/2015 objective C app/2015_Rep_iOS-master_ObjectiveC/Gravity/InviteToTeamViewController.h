//
//  InviteNetworksViewController.h
//  Gravity
//
//  Created by Vlad Getman on 12.12.14.
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AddressBook/AddressBook.h>

@interface InviteToTeamViewController : UIViewController {
    IBOutlet UIButton *actionButton;
    IBOutlet UIButton *contactsBtn;
    IBOutlet UIView *headerView;
    IBOutlet UILabel *titleLabel;
    
    NSMutableSet *ids;
    NSArray *items;
    NSArray *contacts;
}

@property (nonatomic, strong) NSNumber *portalId;
@property (nonatomic, strong) NSNumber *goalId;
@property (nonatomic, strong) NSNumber *userId;
@property (nonatomic) BOOL sharing;

@end
