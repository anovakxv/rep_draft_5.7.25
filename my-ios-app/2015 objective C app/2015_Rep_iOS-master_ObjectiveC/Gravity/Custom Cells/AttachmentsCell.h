//
//  AttachmentsCell.h
//  Gravity
//
//  Created by Vlad Getman on 04.02.15.
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AttachmentsCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UIImageView *photoView;
@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UILabel *countLabel;

@property (nonatomic, strong) NSArray *photos;
@property (nonatomic, strong) id image;
@property (nonatomic, strong) id section;

@end
