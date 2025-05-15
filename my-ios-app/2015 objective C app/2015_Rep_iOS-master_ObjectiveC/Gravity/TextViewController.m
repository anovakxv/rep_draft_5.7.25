//
//  TextViewController.m
//  Gravity
//
//  Created by Vlad Getman on 06.03.15.
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

#import "TextViewController.h"

@interface TextViewController ()

@end

@implementation TextViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        UIBarButtonItem *backBtn = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"BtnBack"]
                                                                    style:UIBarButtonItemStylePlain
                                                                   target:self
                                                                   action:@selector(backAction)];
        
        self.navigationItem.leftBarButtonItem = backBtn;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.policy ? @"Policy" : @"Privacy";
    
    NSString *fileName = self.policy ? @"privacy_policy" : @"conditions_of_use";
    webView.scrollView.contentInset = UIEdgeInsetsMake(10, 10, 10, 10);
    [webView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:fileName ofType:@"html"] isDirectory:NO]]];
    
}

- (void)backAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
