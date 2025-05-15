//
//  NewProductViewController.m
//  Gravity
//
//  Created by Vlad Getman on 15.10.14.
//  Copyright (c) 2014 HalcyonInnovation. All rights reserved.
//

#import "NewProductViewController.h"
#import "AppDelegate.h"
#import "SignCell.h"
#import "AttachmentsCell.h"
#import "AttachmentsViewController.h"

@interface NewProductViewController ()

@end

@implementation NewProductViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        self.title = @"New Offering";
        
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
        
        titles = @[@"Name", @"Sub Title", @"About", @"Price"];
        keys = @[@"name", @"subtitle", @"description", @"price"];
        
        params = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView registerCellClass:[SignCell class]
                       withIdentifier:@"SignCell"];
    [self.tableView registerCellClass:[AttachmentsCell class]
                       withIdentifier:@"AttachmentsCell"];
    
    params[@"portals_id"] = self.portalId.stringValue;
}

- (void)cancelAction {
    [self.view endEditing:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)doneAction {
    [self.view endEditing:YES];
    
    for (NSInteger i = 0; i < titles.count; i++) {
        NSString *value = params[keys[i]];
        if (value.length == 0) {
            NSString *title = titles[i];
            NSString *error = [NSString stringWithFormat:@"%@ must be filled", title];
            [SUPPORT showError:error];
            return;
        }
    }
    if (graphics.count == 0) {
        [SUPPORT showError:@"Graphics must be contains at least 1 photo"];
        return;
    }
    
    [self registerAction];
}

- (void)registerAction {
    
    [SUPPORT showLoading:YES];
    
    NSMutableArray *mediaArray = [[NSMutableArray alloc] init];
    NSMutableDictionary *filesParams = [[NSMutableDictionary alloc] init];
    
    for (NSInteger i = 0; i < graphics.count; i++) {
        [mediaArray addObject:@(i).stringValue];
        UIImage *image = (UIImage *)graphics[i];
        
        MediaData *mediaData = [[MediaData alloc] initWithData:UIImageJPEGRepresentation(image, 1.0) name:@"photo.jpg" contentType:@"image/jpg"];
        filesParams[[NSString stringWithFormat:@"aMultipleFiles[%@]", @(i).stringValue]] = mediaData;
    }
    params[@"aSources"] = mediaArray;
    
    [DataMNG JSONTo:kServerUrl
     withDictionary:params
         fileParams:filesParams
                log:NO
           function:@"api_create_product"
    completionBlock:^(NSDictionary *json, NSError *error) {
        if (error) {
            [SUPPORT showError:error.localizedDescription];
        } else {
            [self cancelAction];
        }
        [SUPPORT showLoading:NO];
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - tableview

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return section == 0 ? titles.count : 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 1)
        return 87;
    
    if (indexPath.row == 2) {
        NSString *title = titles[indexPath.row];
        NSString *value = params[keys[indexPath.row]];
        UIFont *font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:14];
        CGFloat titleWidth = [UIUtils findWidthForText:title
                                          havingHeight:21
                                               andFont:font];
        titleWidth = MAX(titleWidth, 45);
        CGFloat viewWidth = CGRectGetWidth(self.tableView.frame) - titleWidth - 36 - 10;
        CGFloat height = [UIUtils findHeightForText:value
                                        havingWidth:viewWidth
                                            andFont:font];
        
        height += 26;
        return MAX(44, height);
    }
    
    return 44;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return section == 0 ? 0 : 44;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 0)
        return nil;
    
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(tableView.frame), 44)];
    header.backgroundColor = [UIColor clearColor];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(15, 20, CGRectGetWidth(tableView.frame) - 30, 18)];
    label.backgroundColor = [UIColor clearColor];
    label.text = [@"Graphic Section:" uppercaseString];
    label.textColor = UIColorFromRGB(0x4d4d4d);
    label.font = [UIFont fontWithName:@"HelveticaNeue" size:14];
    [header addSubview:label];
    
    return header;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        SignCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SignCell"];
        cell.textField.delegate = self;
        cell.phoneField.delegate = self;
        cell.textView.delegate = self;
        
        cell.title = titles[indexPath.row];
        
        NSString *value = params[keys[indexPath.row]];
        
        if (!cell.textField.hidden)
            cell.textField.text = value;
        else
            cell.textView.text = value;
        
        return cell;
    } else {
        AttachmentsCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AttachmentsCell"];
        cell.photos = graphics;
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 1) {
        AttachmentsViewController *controller = [[AttachmentsViewController alloc] init];
        controller.title = @"Attachments";
        controller.photos = graphics;
        controller.photosBlock = ^(NSArray *photos) {
            graphics = photos;
            [self.tableView reloadData];
        };
        [self.navigationController pushViewController:controller animated:YES];
    }
}

#pragma mark - text 

- (void)viewWillAdjustingWithKbHeight:(CGFloat)kbOffset {
    CGRect frame = self.tableView.frame;
    frame.size.height -= kbOffset;
    self.tableView.frame = frame;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    CGPoint point = [textField.superview convertPoint:textField.center toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:point];
    if (!indexPath)
        return;
    
    params[keys[indexPath.row]] = textField.text;
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    CGPoint point = [textView.superview convertPoint:textView.center toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:point];
    if (!indexPath)
        return;
    
    params[keys[indexPath.row]] = textView.text;
}

- (void)textViewDidChange:(UITextView *)textView {
    CGPoint center = textView.center;
    CGPoint rootViewPoint = [textView.superview convertPoint:center toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:rootViewPoint];
    if (indexPath) {
        params[keys[indexPath.row]] = textView.text;
    }
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    CGPoint point = [textField.superview convertPoint:textField.center toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:point];
    if (!indexPath)
        return YES;
    
    if (indexPath.row == 3)
    {
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        NSString *decimalSymbol = [formatter decimalSeparator];
        
        NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
        
        NSString *expression = [NSString stringWithFormat:@"^([0-9]+)?(\\%@([0-9]{1,2})?)?$", decimalSymbol];
        
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:expression
                                                                               options:NSRegularExpressionCaseInsensitive
                                                                                 error:nil];
        NSUInteger numberOfMatches = [regex numberOfMatchesInString:newString
                                                            options:0
                                                              range:NSMakeRange(0, [newString length])];
        if (numberOfMatches == 0) {
            return NO;
        }
    }
    return YES;
}


@end
