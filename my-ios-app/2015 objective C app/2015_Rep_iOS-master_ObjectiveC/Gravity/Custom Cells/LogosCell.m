//
//  LogosCell.m
//  Gravity
//
//  Created by Vlad Getman on 10.10.14.
//  Copyright (c) 2014 HalcyonInnovation. All rights reserved.
//

#import "LogosCell.h"
#import "AppDelegate.h"
#import "IDMPhotoBrowser.h"
#import "ImageCell.h"

@implementation LogosCell

- (void)awakeFromNib {
    
    [self.collectionView registerCellClass:[ImageCell class]];
    
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
    layout.itemSize = [LogosCell size];
    self.collectionView.collectionViewLayout = layout;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

- (void)setPhotos:(NSArray *)photos {
    _photos = photos;
    [self.collectionView reloadData];
}

+ (CGSize)size {
    CGSize size;
    size.width = (CGRectGetWidth(APP.window.frame) - 24) / 2;
    size.height = size.width * 75 / 148;
    return size;
}

#pragma mark - collectionview

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.photos.count;//ceilf(self.photos.count / 2.0);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    ImageCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cellIdentifier" forIndexPath:indexPath];;
    cell.image = self.photos[indexPath.row];
    
    return cell;
}

- (void)tapOnImage:(UITapGestureRecognizer *)sender {
    
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    [self showPhotoWithIndex:indexPath.row];
}

- (void)showPhotoWithIndex:(NSInteger)index {
    
    NSMutableArray *photos = [NSMutableArray new];
    
    for (NSDictionary *item in self.photos) {
        NSString *photoUrl;
        for (NSString *key in item.allKeys) {
            if ([key rangeOfString:@"original"].location != NSNotFound) {
                photoUrl = [item objectForKey:key];
                break;
            } else if ([key rangeOfString:@"max_6"].location != NSNotFound) {
                photoUrl = [item objectForKey:key];
                break;
            }
        }
        if (photoUrl.length > 0) {
            NSURL *url = [NSURL URLWithString:photoUrl];
            IDMPhoto *photo = [IDMPhoto photoWithURL:url];
            [photos addObject:photo];
        }
    }
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    APP.mask = UIInterfaceOrientationMaskAll;
    
    IDMPhotoBrowser *browser = [[IDMPhotoBrowser alloc] initWithPhotos:photos];
    browser.displayActionButton = NO;
    browser.displayArrowButton = NO;
    browser.displayCounterLabel = NO;
    browser.displayDoneButton = NO;
    browser.forceHideStatusBar = YES;
    [browser setInitialPageIndex:index];
    
    ORNavigationController *nav = [[ORNavigationController alloc] initWithRootViewController:browser];
    nav.navigationBarHidden = YES;
    [APP.window.rootViewController presentViewController:nav animated:YES completion:nil];
}


@end
