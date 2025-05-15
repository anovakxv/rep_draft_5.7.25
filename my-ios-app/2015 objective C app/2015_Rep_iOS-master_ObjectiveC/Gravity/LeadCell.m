//
//  LeadCell.m
//  Gravity
//
//  Created by Vlad Getman on 09.02.15.
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

#import "LeadCell.h"

@implementation LeadCell

- (void)awakeFromNib {
    self.photoView.layer.cornerRadius = CGRectGetHeight(self.photoView.frame) / 2.0;
}

- (void)setUserId:(NSString *)userId {
    _userId = userId;
    NSNumber *uId = @([userId integerValue]);
    self.user = [DataModel getUserWithId:uId];
}

- (void)setUser:(User *)user {
    _user = user;
    
    __weak typeof(self) weakSelf = self;
    [self.photoView setImageWithURL:[NSURL URLWithString:user.photoSmall]
                   placeholderImage:[UIImage imageNamed:@"PhotoPlaceholder"]
                          completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                              weakSelf.photoView.image = [UIUtils image:image scaledToFitSize:CGSizeMake(50, 50)];
                          }
        usingActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    NSString *name = @"";
    for (NSString *word in [user.fullName componentsSeparatedByString:@" "]) {
        name = [name stringByAppendingString:[word substringToIndex:1]];
    }
    self.nameLabel.text = [name uppercaseString];
}

@end
