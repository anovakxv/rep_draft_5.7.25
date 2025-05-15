//
//  AttachmentsViewController.h
//  Gravity
//
//  Created by Vlad Getman on 04.02.15.
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PECropViewController.h"

@interface AttachmentsViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIActionSheetDelegate, PECropViewControllerDelegate> {
    IBOutlet UIView *placeholderView;
    NSMutableArray *graphics;
}

@property (nonatomic, strong) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) NSArray *photos;
@property (nonatomic, strong) void (^photosBlock)(NSArray *photos);
@property (nonatomic, strong) void (^deleteBlock)(id photo);
@end

