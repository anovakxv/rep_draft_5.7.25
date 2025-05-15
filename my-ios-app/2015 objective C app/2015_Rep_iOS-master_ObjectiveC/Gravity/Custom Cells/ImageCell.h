//
//  ImageCell.h
//  Gravity
//
//  Created by Vlad Getman on 09.10.14.
//  Copyright (c) 2014 HalcyonInnovation. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ImageCell : UICollectionViewCell

@property (nonatomic, strong) IBOutlet UIImageView *imageView;
@property (nonatomic, strong) id image;

@end
