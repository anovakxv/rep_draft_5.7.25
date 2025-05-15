//
//  DoubleImageCell.h
//  Gravity
//
//  Created by Vlad Getman on 10.10.14.
//  Copyright (c) 2014 HalcyonInnovation. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DoubleImageCell : UICollectionViewCell

@property (nonatomic, strong) IBOutlet UIImageView *firstImageView;
@property (nonatomic, strong) IBOutlet UIImageView *secondImageView;

@property (nonatomic, strong) IBOutlet UIButton *firstSelectionBtn;
@property (nonatomic, strong) IBOutlet UIButton *secondSelectionBtn;

@property (nonatomic, strong) id firstImage;
@property (nonatomic, strong) id secondImage;

@end
