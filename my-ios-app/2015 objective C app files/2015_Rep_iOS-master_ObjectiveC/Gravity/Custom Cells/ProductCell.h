//
//  ProductCell.h
//  Gravity
//
//  Created by Vlad Getman on 28.10.14.
//  Copyright (c) 2014 HalcyonInnovation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Product.h"

@interface ProductCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UIImageView *logoView;
@property (nonatomic, strong) IBOutlet UILabel *nameLabel;
@property (nonatomic, strong) IBOutlet UILabel *subtitleLabel;
@property (nonatomic, strong) IBOutlet UILabel *priceLabel;
@property (nonatomic, strong) IBOutlet UIButton *minusBtn;
@property (nonatomic, strong) IBOutlet UIButton *plusBtn;

@property (nonatomic, strong) Product *product;

@property (nonatomic, assign) NSInteger count;
@property (nonatomic, strong) void (^changeBlock)(NSInteger count);


@end
