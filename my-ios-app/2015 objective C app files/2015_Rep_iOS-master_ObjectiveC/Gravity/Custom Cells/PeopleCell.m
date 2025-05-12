//
//  PeopleTableViewCell.m
//  Goals
//
//  Created by Ahad on 9/6/14.
//  Copyright (c) 2014 ahad. All rights reserved.
//

#import "PeopleCell.h"
#import "ChatViewController.h"
#import "AppDelegate.h"
#import "ProfileViewController.h"

@implementation PeopleCell

- (void)awakeFromNib
{
    self.photoView.layer.masksToBounds = YES;
    self.photoView.layer.cornerRadius = CGRectGetHeight(self.photoView.frame) / 2;
    [self.photoView addTarget:self action:@selector(profileAction)];
}

- (void)profileAction {
    
    if (!self.user)
        return;
    
    ProfileViewController *controller = [[ProfileViewController alloc] init];
    controller.userId = self.user.userId;
    controller.hidesBottomBarWhenPushed = self.user.userId.integerValue != APP.user.userId.integerValue;
    [APP.menuController pushController:controller animated:YES];
}

- (void)setUser:(User *)user {
    _user = user;
    
    self.nameLabel.text = user.fullName;
    
    self.messageLabel.text = user.broadcast;
    [self.photoView setImageWithURL:[NSURL URLWithString:user.photo]
                   placeholderImage:nil
        usingActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.dateLabel.text = nil;
    
    self.messageLabel.textColor = [UIColor blackColor];
    self.messageLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:12];
}

- (void)setMessage:(Message *)message {
    _message = message;
    
    NSNumber *userId;
    if (message.chatId.integerValue > 0) {
        userId = message.userId1;
    } else {
        userId = message.userId1 == APP.user.userId ? message.userId2 : message.userId1;
    }
    
    Chat *chat = [DataModel getItem:[Chat class]
                             withId:message.chatId];
    if (message.chatId.integerValue > 0 && chat && chat.title.length > 0) {
        self.nameLabel.text = [NSString stringWithFormat:@"[%@]", chat.title.stringByStrippingHTMLItems];
    } else {
        User *user = [DataModel getUserWithId:userId];
        if (user) {
            self.user = user;
            if (self.message && self.message.chatId.integerValue > 0) {
                self.nameLabel.text = [NSString stringWithFormat:@"Team Chat [%@]", user.fullName];
            }
        } else {
            self.nameLabel.text = nil;
        }
    }
    
    self.messageLabel.text = [message.text stringByStrippingHTMLItems];
    self.dateLabel.text = [message.timestamp timeAgo];
    
    self.messageLabel.textColor = message.read.boolValue ? [UIColor blackColor] : [UIColor appGreen];
    self.messageLabel.font = [UIFont fontWithName:message.read.boolValue ? @"HelveticaNeue" : @"HelveticaNeue-Medium" size:12];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
