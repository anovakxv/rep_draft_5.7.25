//
//  InviteViewController.h
//  Gravity
//
//  Created by Vlad Getman on 17.12.14.
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Invite.h"

@protocol InviteDelegate <NSObject>

- (void)inviteControllerClosed;

@end

@interface InviteViewController : UIViewController {
    IBOutlet UIView *actionsView;
    IBOutlet UIButton *acceptBtn;
    IBOutlet UIButton *declineBtn;
    IBOutlet UIButton *okBtn;
    
    IBOutlet UIView *contentView;
}

@property (nonatomic, weak) id <InviteDelegate> delegate;
@property (nonatomic, strong) Invite *invite;

@end
