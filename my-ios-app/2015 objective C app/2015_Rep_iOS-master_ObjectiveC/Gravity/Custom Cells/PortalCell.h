//
//  PatnersTableViewCell.h
//  Goals
//
//  Created by Ahad on 9/6/14.
//  Copyright (c) 2014 ahad. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Portal.h"

@interface PortalCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UIImageView *logoView;
@property (nonatomic, strong) IBOutlet UILabel *nameLabel;
@property (nonatomic, strong) IBOutlet UILabel *subtitleLabel;
@property (nonatomic, strong) IBOutlet UILabel *cityLabel;
@property (nonatomic, strong) IBOutlet UILabel *categoryLabel;

@property (nonatomic, strong) Portal *portal;

@end
