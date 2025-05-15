//
//  BuyViewController.h
//  Gravity
//
//  Created by Vlad Getman on 30.12.14.
//  Copyright (c) 2014 HalcyonInnovation. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BuyViewController : UIViewController {
    IBOutlet UIButton *actionButton;
    IBOutlet UIView *contentView;
    
    IBOutlet UILabel *qtyLabel;
    IBOutlet UILabel *totalLabel;
}

@property (nonatomic, strong) NSArray *products;
@property (nonatomic, strong) NSMutableDictionary *values;

@end
