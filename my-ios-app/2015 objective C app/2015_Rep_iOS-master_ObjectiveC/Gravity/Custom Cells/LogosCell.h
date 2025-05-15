//
//  LogosCell.h
//  Gravity
//
//  Created by Vlad Getman on 10.10.14.
//  Copyright (c) 2014 HalcyonInnovation. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LogosCell : UITableViewCell <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, strong) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) NSArray *photos;

+ (CGSize)size;

@end
