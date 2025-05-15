//
//  GoalsDetailTeamTableViewCell.m
//  Goals
//
//  Created by Ahad on 9/9/14.
//  Copyright (c) 2014 ahad. All rights reserved.
//

#import "GoalsDetailTeamCell.h"

@implementation GoalsDetailTeamCell

- (void)awakeFromNib
{
    self.photoView.layer.cornerRadius = CGRectGetHeight(self.photoView.frame) / 2;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setUser:(User *)user {
    _user = user;
    self.nameLabel.text = user.fullName;
    
    UserType *type = [[DATA fetchData:@"UserType"
                       withDescriptor:nil
                        withPredicate:[NSPredicate predicateWithFormat:@"userTypeId == %@", user.userTypeId]
                       withAttributes:nil] firstObject];
    City *city = [[DATA fetchData:@"City"
                   withDescriptor:nil
                    withPredicate:[NSPredicate predicateWithFormat:@"cityId == %@", user.cityId]
                   withAttributes:nil] firstObject];
    
    NSMutableString *infoString = [[NSMutableString alloc] init];
    if (type) {
        [infoString appendFormat:@"Rep Type: %@   ", type.title];
    }
    if (city || user.manualCity.length > 0) {
        [infoString appendFormat:@"City: %@", user.manualCity.length > 0 ? user.manualCity : city.name];
    }
    
    self.infoLabel.text = infoString;
    
    [self.photoView setImageWithURL:[NSURL URLWithString:user.photo]
                   placeholderImage:nil
        usingActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
}

@end
