//
//  TextViewController.h
//  Gravity
//
//  Created by Vlad Getman on 06.03.15.
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

#import "VGViewController.h"

@interface TextViewController : VGViewController {
    IBOutlet UIWebView *webView;
}

@property (nonatomic) BOOL policy;

@end
