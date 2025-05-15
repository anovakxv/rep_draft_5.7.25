//
//  ActionCell.h
//  Gravity
//
//  Created by Vlad Getman on 10.10.14.
//  Copyright (c) 2014 HalcyonInnovation. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ActionCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UIButton *button;
@property (nonatomic, strong) IBOutlet UIImageView *arrow;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) IBOutlet UILabel *label;

@end

