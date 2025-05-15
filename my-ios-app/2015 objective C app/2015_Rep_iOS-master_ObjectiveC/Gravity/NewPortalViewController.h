//
//  NewPortalViewController.h
//  Gravity
//
//  Created by Vlad Getman on 15.10.14.
//  Copyright (c) 2014 HalcyonInnovation. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SZTextView.h>
#import "Categories.h"
#import "Portal.h"

@interface NewPortalViewController : VGViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UITextViewDelegate> {
    
    NSMutableArray *textSections;
    NSMutableArray *graphicSections;
    
    NSArray *categories;
    NSArray *cities;
    
    NSMutableDictionary *params;
    NSArray *titles;
    NSArray *keys;
    
    NSDictionary *bankParams;
    
    IBOutlet UIView *bottomBar;
    IBOutlet UIButton *deleteBtn;
    NSMutableSet *deletedPhotos;
    NSMutableSet *deletedSections;
}

@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) Portal *portal;
@property (nonatomic, strong) void (^completionBlock)();

- (IBAction)deleteAction;

@end
