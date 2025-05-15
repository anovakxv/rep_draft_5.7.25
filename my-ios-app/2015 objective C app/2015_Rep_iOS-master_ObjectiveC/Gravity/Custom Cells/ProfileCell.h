//
//  ProfileCell.h
//  Gravity
//
//  Created by Vlad Getman on 04.02.15.
//  Copyright (c) 2015 HalcyonInnovation. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ProfileCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UIImageView *photoView;
@property (nonatomic, strong) IBOutlet UILabel *nameLabel;

@property (nonatomic, strong) User *user;

@end
