//
//  NavigationControllerDelegate.m
//  NavigationTransitionController
//
//  Created by Chris Eidhof on 09.10.13.
//  Copyright (c) 2013 Chris Eidhof. All rights reserved.
//

#import "NavigationControllerDelegate.h"
#import "TransitionManager.h"
#import "AppDelegate.h"

@interface NavigationControllerDelegate ()

@property (weak, nonatomic) IBOutlet UINavigationController *navigationController;
@property (nonatomic, strong) TransitionManager *transitionManager;
@property (strong, nonatomic) UIPercentDrivenInteractiveTransition* interactionController;

@end

@implementation NavigationControllerDelegate

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController animationControllerForOperation:(UINavigationControllerOperation)operation fromViewController:(UIViewController *)fromVC toViewController:(UIViewController *)toVC
{
    
    if (!self.transitionManager) {
        self.transitionManager = [[TransitionManager alloc] init];
    }
    
    if (operation == UINavigationControllerOperationPop) {
        self.transitionManager.transitionTo = INITIAL;
        return self.transitionManager;
    } else if (operation == UINavigationControllerOperationPush) {
        self.transitionManager.transitionTo = MODAL;
        return self.transitionManager;
    }
    return nil;
}

- (id<UIViewControllerInteractiveTransitioning>)navigationController:(UINavigationController *)navigationController interactionControllerForAnimationController:(id<UIViewControllerAnimatedTransitioning>)animationController
{
    return self.interactionController;
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    //APP.transitionInProgress = YES;
}
- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    //APP.transitionInProgress = NO;
}

@end
