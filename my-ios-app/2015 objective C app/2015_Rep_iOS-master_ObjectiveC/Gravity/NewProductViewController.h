//
//  NewProductViewController.h
//  Gravity
//
//  Created by Vlad Getman on 15.10.14.
//  Copyright (c) 2014 HalcyonInnovation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SZTextView.h>

@interface NewProductViewController : VGViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UITextViewDelegate> {
    NSArray *titles;
    NSArray *keys;
    
    NSArray *graphics;
    NSMutableDictionary *params;
}

@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSNumber *portalId;

@end
