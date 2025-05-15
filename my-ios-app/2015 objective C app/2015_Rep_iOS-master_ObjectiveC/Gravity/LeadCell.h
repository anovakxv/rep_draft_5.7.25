//
//  LeadCell.h
//  Gravity
//
//  Created by Vlad Getman on 09.02.15.
//  Copyright (c) 2015 HalcyonInnovation. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LeadCell : UICollectionViewCell

@property (nonatomic, strong) IBOutlet UIImageView *photoView;
@property (nonatomic, strong) IBOutlet UILabel *nameLabel;

@property (nonatomic, strong) NSString *userId;
@property (nonatomic, strong) User *user;

@end
