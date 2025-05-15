//
//  GoalsDetailTeamTableViewCell.h
//  Goals
//
//  Created by Ahad on 9/9/14.
//  Copyright (c) 2014 ahad. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GoalsDetailTeamCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UIImageView *photoView;
@property (nonatomic, strong) IBOutlet UILabel *nameLabel;
@property (nonatomic, strong) IBOutlet UILabel *infoLabel;

@property (nonatomic, strong) User *user;

@end
