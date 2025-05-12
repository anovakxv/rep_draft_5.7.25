//
//  TransitionManager.m
//  ClickIn
//
//  Created by Vlad Getman on 23.05.14.
//  Copyright (c) 2014 HalcyonLA. All rights reserved.
//

#import "TransitionManager.h"

@implementation TransitionManager


#pragma mark - UIViewControllerAnimatedTransitioning -

//Define the transition duration
-(NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext{
    return 0.3;
}


//Define the transition
- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    
    //STEP 1
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    CGRect sourceRect = [transitionContext initialFrameForViewController:fromVC];
    
    /*STEP 2:   Draw different transitions depending on the view to show
     for sake of clarity this code is divided in two different blocks
     */
    
    //STEP 2A: From the First View(INITIAL) -> to the Second View(MODAL)
    if(self.transitionTo == MODAL){
        //[fromVC viewWillDisappear:YES];
        //[toVC viewWillAppear:YES];
        
        //1.Insert the toVC view...........................
        UIView *container = [transitionContext containerView];
        toVC.view.bounds = fromVC.view.bounds;
        [container insertSubview:toVC.view aboveSubview:fromVC.view];
        CGPoint final_toVC_Center = fromVC.view.center;
        
        toVC.view.center = CGPointMake(toVC.view.center.x, sourceRect.size.height * 1.5 );
        
        //2.Perform the animation...............................
        [UIView animateWithDuration:0.3
                              delay:0.0
             usingSpringWithDamping:1
              initialSpringVelocity:0
                            options:UIViewAnimationOptionCurveEaseIn
         
                         animations:^{
                             
                             //Setup the final parameters of the 2 views
                             //the animation interpolates from the current parameters
                             //to the next values.
                             fromVC.view.alpha = 0.75f;
                             //fromVC.view.transform = CGAffineTransformMakeScale(.85, .85);
                             toVC.view.center = final_toVC_Center;
                         } completion:^(BOOL finished) {
                             
                             //When the animation is completed call completeTransition
                             fromVC.view.alpha = 1;
                             toVC.view.alpha = 1;
                             [transitionContext completeTransition:YES];
                             //[fromVC viewDidDisappear:YES];
                             //[toVC viewDidAppear:YES];
                             
                             //fromVC.view.transform = CGAffineTransformIdentity;
                         }];
    }
    
    //STEP 2B: From the Second view(MODAL) -> to the First View(INITIAL)
    else{
        //[fromVC viewWillDisappear:YES];
        //[toVC viewWillAppear:YES];
        
        UIView *container = [transitionContext containerView];
        //Insert the toVC view view...........................
        [container insertSubview:toVC.view belowSubview:fromVC.view];
        toVC.view.alpha = 0.75f;
        //toVC.view.transform = CGAffineTransformMakeScale(.85, .85);
        //Perform the animation...............................
        [UIView animateWithDuration:0.3
                              delay:0.0
             usingSpringWithDamping:1
              initialSpringVelocity:0.0
                            options:UIViewAnimationOptionCurveEaseIn
         
                         animations:^{
                             
                             //Setup the final parameters of the 2 views
                             //the animation interpolates from the current parameters
                             //to the next values.
                             fromVC.view.center = CGPointMake(fromVC.view.center.x, fromVC.view.frame.size.height * 1.5);
                             toVC.view.alpha = 1.0f;
                             ///toVC.view.transform = CGAffineTransformIdentity;
                         } completion:^(BOOL finished) {
                             
                             //When the animation is completed call completeTransition
                             fromVC.view.alpha = 1;
                             toVC.view.alpha = 1;
                             [transitionContext completeTransition:YES];
                             //[fromVC viewDidDisappear:YES];
                             //[toVC viewDidAppear:YES];
                         }];
    }
    
    
}

@end