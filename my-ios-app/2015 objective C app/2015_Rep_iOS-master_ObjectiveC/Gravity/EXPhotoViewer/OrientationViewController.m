//
//  OrientationViewController.m
//  Gravity
//
//  Created by Vlad Getman on 18.11.14.
//  Copyright (c) 2014 HalcyonInnovation. All rights reserved.
//

#import "OrientationViewController.h"

@interface OrientationViewController ()

@end

@implementation OrientationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    //[self dismissViewControllerAnimated:NO completion:nil];
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    
    return UIInterfaceOrientationMaskPortrait;
}


- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}


@end
