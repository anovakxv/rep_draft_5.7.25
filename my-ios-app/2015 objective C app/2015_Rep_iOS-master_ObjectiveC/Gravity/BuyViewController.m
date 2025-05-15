//
//  BuyViewController.m
//  Gravity
//
//  Created by Vlad Getman on 30.12.14.
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

#import "BuyViewController.h"
#import "ProductCell.h"
#import "ConfirmViewController.h"

@interface BuyViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) IBOutlet UITableView *tableView;

@end

@implementation BuyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView registerCellClass:[ProductCell class]];
    self.tableView.tableFooterView = [UIView new];
    self.tableView.backgroundColor = [UIColor whiteColor];
    
    [actionButton setBackgroundImage:[UIUtils roundedImageWithSize:actionButton.frame.size
                                                          andColor:actionButton.backgroundColor
                                                        withBorder:YES]
                            forState:UIControlStateNormal];
    actionButton.backgroundColor = nil;
    
    [self updateInfo];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self showContent:YES animated:YES];
}

- (IBAction)confirmArction {
    
    NSMutableDictionary *basket = [[NSMutableDictionary alloc] init];
    for (NSString *key in self.values.allKeys) {
        if ([self.values[key] integerValue] > 0) {
            basket[key] = self.values[key];
        }
    }
    
    /*NSMutableSet *ids = [[NSMutableSet alloc] init];
    for (Product *p in self.products) {
        NSString *key = p.productId.stringValue;
        NSNumber *c = self.values[key];
        if (c.integerValue > 0) {
            [ids addObject:key];
        }
    }*/
    if (basket.allKeys.count == 0) {
        [SUPPORT showError:@"Count of products must be at least one"];
        return;
    }
    
    [SUPPORT showLoading:YES];
    [DataMNG JSONTo:kServerUrl
     withDictionary:@{}
                log:NO
           function:@"api_get_payment_cards"
    completionBlock:^(NSDictionary *json, NSError *error) {
        [DATA mappingJSON:json
                     type:MAPPING_CARDS
         withCompletition:^(NSArray *items) {
             if (items.count == 0) {
                 [SUPPORT showLoading:NO];
                 ConfirmViewController *controller = [[ConfirmViewController alloc] init];
                 controller.basket = basket;
                 [self presentTransparentController:controller animated:YES];
             } else {
                 [DataMNG JSONTo:kServerUrl
                  withDictionary:@{@"aBasket":basket}
                             log:NO
                        function:@"api_basket_checkout"
                 completionBlock:^(NSDictionary *json, NSError *error) {
                     [SUPPORT showLoading:NO];
                     if (error) {
                         [SUPPORT showError:error.localizedDescription];
                     } else {
                         [SUPPORT showAlert:@"The Purchase is complete"
                                       body:nil];
                         [self showContent:NO animated:YES];
                     }
                 }];
             }
         }];
    }];
}

#pragma mark tableview

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.products.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ProductCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellIdentifier"];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    Product *product = self.products[indexPath.row];
    cell.product = product;
    cell.count = [self.values[product.productId.stringValue] integerValue];
    cell.changeBlock = ^(NSInteger count) {
        self.values[product.productId.stringValue] = @(count).stringValue;
        [self updateInfo];
    };
    return cell;
}

#pragma mark UI

- (void)updateInfo {
    NSInteger count = 0;
    CGFloat sum = 0;
    
    for (Product *p in self.products) {
        NSString *key = p.productId.stringValue;
        NSNumber *c = self.values[key];
        if (c.integerValue > 0) {
            count++;
            sum += (p.price.floatValue * c.floatValue);
        }
    }
    qtyLabel.text = @"";//[NSString stringWithFormat:@"Qty: %tu", count];
    totalLabel.text = [NSString stringWithFormat:@"Total: %@", @(sum).priceValue];
}

- (IBAction)cancelAction {
    [self showContent:NO animated:YES];
}

- (void)showContent:(BOOL)show animated:(BOOL)animated {
    
    [UIView animateWithDuration:animated ? 0.25 : 0
                          delay:show ? (animated ? 0.15 : 0) : 0
                        options:0
                     animations:^{
                         CGRect frame = contentView.frame;
                         frame.origin.y = show ? 64 : (CGRectGetHeight(self.view.frame) - 48);
                         contentView.frame = frame;
                     } completion:nil];
    
    [UIView animateWithDuration:animated ? 0.3 : 0
                          delay:!show ? (animated ? 0.15 : 0) : 0
                        options:0
                     animations:^{
                         self.view.alpha = show ? 1 : 0;
                     } completion:^(BOOL finished) {
                         if (!show) {
                             /*if (self.selectionBlock && self.tableView.indexPathForSelectedRow) {
                              self.selectionBlock(self.tableView.indexPathForSelectedRow.section);
                              }*/
                             [self dismissViewControllerAnimated:NO completion:nil];
                         }
                     }];
}

@end
