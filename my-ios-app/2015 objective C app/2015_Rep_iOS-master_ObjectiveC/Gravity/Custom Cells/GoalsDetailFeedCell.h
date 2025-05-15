//
//  GoalsDetailFeedTableViewCell.h
//  Goals
//
//  Created by Ahad on 9/9/14.
//  Copyright (c) 2014 ahad. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GoalsDetailFeedCell : UITableViewCell <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout> {
    NSArray *photos;
}

@property (nonatomic, strong) IBOutlet UIImageView *photoView;
@property (nonatomic, strong) IBOutlet UILabel *nameLabel;
@property (nonatomic, strong) IBOutlet UILabel *dateLabel;
@property (nonatomic, strong) IBOutlet UILabel *metricLabel;
@property (nonatomic, strong) IBOutlet UILabel *notesLabel;
@property (nonatomic, strong) IBOutlet UILabel *attachmentsLabel;
@property (nonatomic, strong) IBOutlet UICollectionView *collectionView;

@property (nonatomic, strong) Feed *feed;
@property (nonatomic, strong) User *user;
@property (nonatomic, strong) Goal *goal;

@end
