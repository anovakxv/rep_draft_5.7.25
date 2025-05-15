//
//  GoalsDetailFeedTableViewCell.m
//  Goals
//
//  Created by Ahad on 9/9/14.
//  Copyright (c) 2014 ahad. All rights reserved.
//

#import "GoalsDetailFeedCell.h"
#import "ImageCell.h"
#import "ORNavigationController.h"
#import "IDMPhotoBrowser.h"
#import "AppDelegate.h"

@implementation GoalsDetailFeedCell

- (void)awakeFromNib
{
    self.photoView.layer.cornerRadius = CGRectGetHeight(self.photoView.frame) / 2;
    [self.collectionView registerCellClass:[ImageCell class]];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setFeed:(Feed *)feed {
    _feed = feed;
    self.user = [DataModel getUserWithId:feed.userId];
    
    self.dateLabel.text = [@"Added: " stringByAppendingString:[feed.timestamp stringWithFormat:@"MM/dd/yy h:mma"]];
    
    GoalMetrics *metrics = [DataModel getGoalMetricsWithId:self.goal.metricId];
    self.metricLabel.text = [NSString stringWithFormat:@"Metric Qty: %@ %@", feed.value.formattedString, metrics.name];
    if (feed.value.integerValue == 1 && [self.metricLabel.text hasSuffix:@"s"]) {
        self.metricLabel.text = [self.metricLabel.text substringToIndex:self.metricLabel.text.length - 1];
    }
    
    NSString *notes = feed.notes.length > 0 ? feed.notes.stringByStrippingHTMLItems : @"NA";
    self.notesLabel.text = [@"Notes: " stringByAppendingString:notes];
    
    BOOL photosExist = feed.attachments.count > 0;
    
    if (photosExist) {
        self.attachmentsLabel.text = [NSString stringWithFormat:@"Attachments: %@ %@", @(feed.attachments.count).stringValue, feed.attachments.count == 1 ? @"item" : @"items"];
        photos = feed.attachments;
        [self.collectionView reloadData];
    } else {
        self.attachmentsLabel.text = @"Attachments: NA";
    }
    self.attachmentsLabel.hidden = photosExist;
    self.collectionView.hidden = !photosExist;
}

- (void)setUser:(User *)user {
    _user = user;
    [self.photoView setImageWithURL:[NSURL URLWithString:user.photo]
        usingActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.nameLabel.text = user.fullName;
}

#pragma mark cv

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return photos.count;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGSize size;
    size.width = (CGRectGetWidth(self.frame) - 13) / 4;
    size.height = size.width;
    return size;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ImageCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cellIdentifier" forIndexPath:indexPath];
    cell.image = photos[indexPath.row];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self showPhotoWithIndex:indexPath.row];
}

- (void)showPhotoWithIndex:(NSInteger)index {
    
    NSMutableArray *graphics = [NSMutableArray new];
    
    for (NSDictionary *item in photos) {
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
            [graphics addObject:photo];
        }
    }
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    APP.mask = UIInterfaceOrientationMaskAll;
    
    IDMPhotoBrowser *browser = [[IDMPhotoBrowser alloc] initWithPhotos:graphics];
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
