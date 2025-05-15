//
//  ScrollPhotoCell.m
//  Gravity
//
//  Created by Vlad Getman on 09.10.14.
//  Copyright (c) 2014 HalcyonInnovation. All rights reserved.
//

#import "ScrollPhotoCell.h"
#import "AppDelegate.h"
#import "ImageCell.h"
#import "IDMPhotoBrowser.h"

@implementation ScrollPhotoCell

- (void)awakeFromNib {
    
    self.photos = @[@"example_logo", @"example_logo", @"example_logo"];
    
    [self.collectionView registerCellClass:[ImageCell class]];
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
    layout.itemSize = [ScrollPhotoCell imageSize];
    self.collectionView.collectionViewLayout = layout;
}

+ (CGSize)imageSize {
    CGSize size;
    size.width = CGRectGetWidth(APP.window.frame);
    size.height = size.width / 16 * 9;
    return size;
}

- (IBAction)leftAction {
    if (self.photos.count == 0 || page == 0)
        return;
    
    page--;
    
    CGPoint offset = self.collectionView.contentOffset;
    offset.x = page * CGRectGetWidth(self.collectionView.frame);
    
    [self.collectionView setContentOffset:offset animated:YES];
}

- (IBAction)rightAction {
    if (self.photos.count == 0 || page +1 == self.photos.count)
        return;
    
    page++;
    
    CGPoint offset = self.collectionView.contentOffset;
    offset.x = page * CGRectGetWidth(self.collectionView.frame);
    
    [self.collectionView setContentOffset:offset animated:YES];
}

#pragma mark - collectionview

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.photos.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    ImageCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cellIdentifier" forIndexPath:indexPath];
    
    cell.image = self.photos[indexPath.row];
    
    return cell;
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

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat pageWidth = self.collectionView.frame.size.width;
    CGFloat fractionalPage = self.collectionView.contentOffset.x / pageWidth;
    page = lround(fractionalPage);
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
