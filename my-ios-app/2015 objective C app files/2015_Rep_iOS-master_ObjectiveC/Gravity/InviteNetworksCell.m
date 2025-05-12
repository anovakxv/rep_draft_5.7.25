//
//  InviteNetworksCell.m
//  Gravity
//
//  Created by Vlad Getman on 12.12.14.
//  Copyright (c) 2014 HalcyonInnovation. All rights reserved.
//

#import "InviteNetworksCell.h"

@implementation InviteNetworksCell

- (void)awakeFromNib {
    self.photoView.layer.cornerRadius = CGRectGetHeight(self.photoView.frame) / 2;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setUser:(User *)user {
    _user = user;
    self.nameLabel.text = user.fullName;
    self.dateLabel.text = [[user.timestamp currentTimezone] timeAgo];
    [self.photoView setImageWithURL:[NSURL URLWithString:user.photo]
                   placeholderImage:nil
        usingActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
}

- (void)setContact:(NSDictionary *)contact {
    _contact = contact;
    
    self.nameLabel.text = contact[@"flname"];
    self.dateLabel.text = nil;
    self.photoView.image = nil;
}

@end
