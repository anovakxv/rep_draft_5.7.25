//
//  TeamChatViewController.h
//  Gravity
//
//  Created by Vlad Getman on 10.14.14.
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SOMessagingViewController.h"
#import "ImageButton.h"

@interface NetworkDelegate : NSObject <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NSArray *network;
@property (nonatomic, strong) NSMutableSet *ids;
@property (nonatomic, strong) id target;

@end

@interface TeamChatViewController : SOMessagingViewController <UICollectionViewDelegate, UICollectionViewDataSource> {
    NSMutableArray *chatData;
    NSArray *users;
    NetworkDelegate *networkDelegate;
    
    NSTimer *timer;
    
    ImageButton *photoView;
    IBOutlet UIView *teamView;
    IBOutlet UIView *pickerView;
    IBOutlet UIButton *addBtn;
}

@property (nonatomic, strong) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) IBOutlet UITableView *networkTableView;

@property (nonatomic, strong) NSNumber *chatId;
@property (nonatomic, strong) NSString *chatName;

- (IBAction)addToChat;
- (IBAction)showPicker;
- (IBAction)closePicker;

@end
