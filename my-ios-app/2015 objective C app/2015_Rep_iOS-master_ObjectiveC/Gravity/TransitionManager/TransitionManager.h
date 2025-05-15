//
//  TransitionManager.h
//  ClickIn
//
//  Created by Vlad Getman on 23.05.14.
//  Copyright (c) 2014 HalcyonLA. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, TransitionStep){
    INITIAL = 0,
    MODAL
};

@interface TransitionManager : NSObject <UIViewControllerAnimatedTransitioning>

@property (nonatomic, assign) TransitionStep transitionTo;

@end
