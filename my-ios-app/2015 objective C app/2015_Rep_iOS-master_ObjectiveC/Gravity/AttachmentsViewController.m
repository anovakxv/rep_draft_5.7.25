//
//  AttachmentsViewController.m
//  Gravity
//
//  Created by Vlad Getman on 04.02.15.
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

#import "AttachmentsViewController.h"
#import "ImageCell.h"
#import "ORNavigationController.h"
#import "IDMPhotoBrowser.h"
#import "AppDelegate.h"
#import "OrientationViewController.h"
#import "ORNavigationController.h"

@interface AttachmentsViewController ()

@end

@implementation AttachmentsViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        UIButton *addButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
        [addButton setTitle:@"+" forState:UIControlStateNormal];
        addButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:35];
        addButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
        addButton.titleEdgeInsets = UIEdgeInsetsMake(0, 0, 5, 0);
        [addButton addTarget:self
                      action:@selector(addPhoto)
            forControlEvents:UIControlEventTouchUpInside];
        [addButton setTitleColor:[UIColor appGreen]
                        forState:UIControlStateNormal];
        [addButton setTitleColor:[[UIColor appGreen] colorWithAlphaComponent:0.5]
                        forState:UIControlStateHighlighted];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:addButton];
        
        graphics = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.collectionView registerCellClass:[ImageCell class]];
    
    UIBarButtonItem *btnBack = [[UIBarButtonItem alloc]
                                initWithTitle:@" "
                                style:UIBarButtonItemStylePlain
                                target:self
                                action:nil];
    self.navigationController.navigationBar.topItem.backBarButtonItem =btnBack;
    
    UITapGestureRecognizer *deleteGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(deleteGesture:)];
    deleteGesture.numberOfTapsRequired = 2;
    [self.collectionView addGestureRecognizer:deleteGesture];
    
    UITapGestureRecognizer *selectGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didSelectItem:)];
    selectGesture.numberOfTouchesRequired = 1;
    [selectGesture requireGestureRecognizerToFail:deleteGesture];
    [self.collectionView addGestureRecognizer:selectGesture];
    
    if (self.photos) {
        [graphics addObjectsFromArray:self.photos];
    }
    [self reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.photosBlock)
        self.photosBlock(graphics);
}

- (void)reloadData {
    placeholderView.hidden = graphics.count > 0;
    [self.collectionView reloadData];
}

- (void)addPhoto {
    
    if (graphics.count == 10) {
        return;
    }
    
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:@"Camera Roll", @"Take a photo", nil];
    [sheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (actionSheet.cancelButtonIndex == buttonIndex)
        return;
    
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.sourceType = buttonIndex == 0 ? UIImagePickerControllerSourceTypePhotoLibrary : UIImagePickerControllerSourceTypeCamera;
    [self.navigationController presentViewController:picker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    PECropViewController *controller = [[PECropViewController alloc] init];
    controller.delegate = self;
    controller.image = image;
    
    CGRect cropRect;
    if ((image.size.width * 9.0f / 16.0f) > image.size.height) {
        cropRect.size.height = image.size.height;
        cropRect.size.width = CGRectGetHeight(cropRect) * 16.0f / 9.0f;
        cropRect.origin = CGPointMake((image.size.width - CGRectGetWidth(cropRect)) / 2, 0);
    } else {
        cropRect.size.width = image.size.width;
        cropRect.size.height = CGRectGetWidth(cropRect) * 9.0f / 16.0f;
        cropRect.origin = CGPointMake(0, (image.size.height - CGRectGetHeight(cropRect)) / 2);
    }
    controller.imageCropRect = cropRect;
    
    controller.keepingCropAspectRatio = YES;
    
    ORNavigationController *navigationController = [[ORNavigationController alloc] initWithRootViewController:controller];
    navigationController.navigationBarHidden = YES;
    [picker presentViewController:navigationController animated:NO completion:nil];
    
    APP.mask = UIInterfaceOrientationMaskAll;
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)cropViewController:(PECropViewController *)controller didFinishCroppingImage:(UIImage *)croppedImage
{
    [self dismissCropController:controller];
    
    [graphics addObject:croppedImage];
    [self reloadData];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)cropViewControllerDidCancel:(PECropViewController *)controller
{
    [self dismissCropController:controller];
}

- (void)dismissCropController:(PECropViewController *)controller {
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    APP.mask = UIInterfaceOrientationMaskPortrait;
    OrientationViewController *c = [[OrientationViewController alloc] init];
    [controller.navigationController pushViewController:c animated:NO];
    [controller dismissViewControllerAnimated:NO completion:nil];
}

#pragma mark collectionview

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return graphics.count;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGSize size;
    size.width = (CGRectGetWidth(collectionView.frame) - 3.0) / 4.0;
    size.height = size.width;
    return size;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ImageCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cellIdentifier" forIndexPath:indexPath];
    cell.image = graphics[indexPath.row];
    return cell;
}

- (void)didSelectItem:(UITapGestureRecognizer *)sender {
    if (UIGestureRecognizerStateEnded != sender.state)
        return;
    
    CGPoint p = [sender locationInView:sender.view];
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:p];
    if (!indexPath) return;
    
    NSMutableArray *images = [NSMutableArray new];
    
    for (id image in graphics) {
        IDMPhoto *photo;
        if ([image isKindOfClass:[NSDictionary class]]) {
            NSString *photoUrl;
            NSDictionary *item = image;
            for (NSString *key in item.allKeys) {
                if ([key rangeOfString:@"original"].location != NSNotFound) {
                    photoUrl = [item objectForKey:key];
                    break;
                } else if ([key rangeOfString:@"max_6"].location != NSNotFound) {
                    photoUrl = [item objectForKey:key];
                    break;
                }
            }
            if (photoUrl.length > 0)
                photo = [IDMPhoto photoWithURL:[NSURL URLWithString:photoUrl]];
        } else if ([image isKindOfClass:[UIImage class]]) {
            photo = [IDMPhoto photoWithImage:image];
        }
        if (photo)
            [images addObject:photo];
    }
    
    APP.mask = UIInterfaceOrientationMaskAll;
    
    IDMPhotoBrowser *browser = [[IDMPhotoBrowser alloc] initWithPhotos:images];
    browser.displayActionButton = NO;
    browser.displayArrowButton = NO;
    browser.displayCounterLabel = NO;
    browser.displayDoneButton = NO;
    browser.forceHideStatusBar = YES;
    [browser setInitialPageIndex:indexPath.row];
    
    ORNavigationController *nav = [[ORNavigationController alloc] initWithRootViewController:browser];
    nav.navigationBarHidden = YES;
    [self presentViewController:nav animated:YES completion:^{
        [[UIApplication sharedApplication] setStatusBarHidden:YES];
    }];
}

- (void)deleteGesture:(UITapGestureRecognizer *)sender {
    if (UIGestureRecognizerStateEnded != sender.state)
        return;
    
    CGPoint p = [sender locationInView:sender.view];
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:p];
    if (!indexPath) return;
    
    [self.collectionView performBatchUpdates:^{
        if (self.deleteBlock)
            self.deleteBlock(graphics[indexPath.row]);
        [graphics removeObjectAtIndex:indexPath.row];
        [self.collectionView deleteItemsAtIndexPaths:@[indexPath]];
    } completion:^(BOOL finished) {
        [self reloadData];
    }];
}

@end
