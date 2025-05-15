//
//  InviteNetworksCell.h
//  Gravity
//
//  Created by Vlad Getman on 12.12.14.
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface InviteNetworksCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UIImageView *photoView;
@property (nonatomic, strong) IBOutlet UILabel *nameLabel;
@property (nonatomic, strong) IBOutlet UILabel *dateLabel;
@property (nonatomic, strong) IBOutlet UIButton *inviteBtn;

@property (nonatomic, strong) User *user;
@property (nonatomic, strong) NSDictionary *contact;

@end
