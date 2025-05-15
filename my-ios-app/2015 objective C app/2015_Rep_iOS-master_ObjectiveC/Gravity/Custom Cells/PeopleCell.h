//
//  PeopleTableViewCell.h
//  Goals
//
//  Created by Ahad on 9/6/14.
//  Copyright (c) 2014 ahad. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VGProgressBar.h"
#import "ImageButton.h"
#import "User.h"
#import "Message.h"

@interface PeopleCell : UITableViewCell

@property (nonatomic, strong) IBOutlet ImageButton *photoView;
@property (nonatomic, strong) IBOutlet UILabel *nameLabel;
@property (nonatomic, strong) IBOutlet UILabel *messageLabel;
@property (nonatomic, strong) IBOutlet UILabel *dateLabel;

@property (nonatomic, strong) User *user;
@property (nonatomic, strong) Message *message;

@end
