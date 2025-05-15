//
//  ChatViewController.h
//  Gravity
//
//  Created by Vlad Getman on 10.14.14.
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SOMessagingViewController.h"
#import "ImageButton.h"

@interface ChatViewController : SOMessagingViewController {
    NSMutableArray *chatData;
    ImageButton *photoView;
    
    NSTimer *timer;
}

@property (nonatomic, strong) NSNumber *userId;

@end
