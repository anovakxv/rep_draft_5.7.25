//
//  SharedPortalCell.h
//  Gravity
//
//  Created by Vlad Getman on 17.02.15.
//  Copyright (c) 2015 HalcyonInnovation. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SharedPortalCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UIImageView *logoView;
@property (nonatomic, strong) IBOutlet UILabel *nameLabel;
@property (nonatomic, strong) IBOutlet UILabel *subtitleLabel;
@property (nonatomic, strong) IBOutlet UILabel *cityLabel;
@property (nonatomic, strong) IBOutlet UILabel *categoryLabel;
@property (nonatomic, strong) IBOutlet UILabel *timeLabel;

@property (nonatomic, strong) Portal *portal;

@end
