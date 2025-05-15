//
//  EcoLoginViewController.m
//  Gravity
//
//  Created by Vlad Getman on 24.02.15.
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

#import "EcoLoginViewController.h"

@interface EcoLoginViewController ()

@end

@implementation EcoLoginViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.title = @"Login";
        
        UIBarButtonItem *cancelBtn = [[UIBarButtonItem alloc] initWithTitle:@"Cancel"
                                                                      style:UIBarButtonItemStyleDone
                                                                     target:self
                                                                     action:@selector(cancelAction)];
        self.navigationItem.leftBarButtonItem = cancelBtn;
        
        UIBarButtonItem *doneBtn = [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                                                    style:UIBarButtonItemStyleDone
                                                                   target:self
                                                                   action:@selector(doneAction)];
        self.navigationItem.rightBarButtonItem = doneBtn;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)cancelAction {
    [self close];
}

- (void)doneAction {
    [self close];
}

- (void)close {
    [self dismissViewControllerAnimated:NO completion:nil];
    self.completionBlock();
    
    
}


@end
