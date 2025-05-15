//
//  ScrollPhotoCell.h
//  Gravity
//
//  Created by Vlad Getman on 09.10.14.
//  Copyright (c) 2014 HalcyonInnovation. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ScrollPhotoCell : UITableViewCell <UICollectionViewDataSource, UICollectionViewDelegate> {
    NSInteger page;
}

@property (nonatomic, strong) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) NSArray *photos;

- (IBAction)leftAction;
- (IBAction)rightAction;

+ (CGSize)imageSize;

@end
