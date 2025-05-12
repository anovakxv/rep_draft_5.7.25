//
//  ProfileCell.m
//  Gravity
//
//  Created by Vlad Getman on 04.02.15.
//  Copyright (c) 2015 HalcyonInnovation. All rights reserved.
//

#import "ProfileCell.h"

@implementation ProfileCell

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
    [self.photoView setImageWithURL:[NSURL URLWithString:user.photo]
                   placeholderImage:[UIImage imageNamed:@"PhotoPlaceholder"]
        usingActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
}

@end
