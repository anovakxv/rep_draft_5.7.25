//
//  NewPortalViewController.m
//  Gravity
//
//  Created by Vlad Getman on 15.10.14.
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

#import "NewPortalViewController.h"
#import "AppDelegate.h"
#import "PortalDetailViewController.h"
#import "SignCell.h"
#import "AttachmentsCell.h"
#import "AttachmentsViewController.h"
#import "PickerViewController.h"
#import "SelectLeadViewController.h"
#import "PortalPaymentsViewController.h"

@interface NewPortalViewController ()

@end

@implementation NewPortalViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        self.title = @"New Portal";
        
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
        
        categories = [DATA fetchData:@"Categories" withDescriptor:nil withPredicate:nil withAttributes:nil];
        cities = [DATA fetchData:@"City" withDescriptor:nil withPredicate:nil withAttributes:nil];
        
        graphicSections = [[NSMutableArray alloc] init];
        NSMutableDictionary *firstSection = [[NSMutableDictionary alloc] initWithDictionary:@{@"title":@"Graphics", @"files":[NSArray array]}];
        [graphicSections addObject:firstSection];
        textSections = [[NSMutableArray alloc] init];
        params = [[NSMutableDictionary alloc] init];
        deletedPhotos = [[NSMutableSet alloc] init];
        deletedSections = [[NSMutableSet alloc] init];
        
        titles = @[@"Portal Name", @"Category", @"City", @"Portal Leads", @"Portal Subtitle", @"Description"];
        keys = @[@"name", @"categories_id", @"cities_id", @"aLeadsIDs", @"subtitle", @"about"];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView registerCellClass:[SignCell class]
                       withIdentifier:@"SignCell"];
    [self.tableView registerCellClass:[AttachmentsCell class]
                       withIdentifier:@"AttachmentsCell"];
    
    if (self.portal) {
        bottomBar.hidden = NO;
        [deleteBtn setBackgroundImage:[UIUtils roundedImageWithSize:deleteBtn.frame.size
                                                           andColor:deleteBtn.backgroundColor
                                                         withBorder:YES]
                             forState:UIControlStateNormal];
        deleteBtn.backgroundColor = nil;
        self.tableView.contentInset = UIEdgeInsetsMake(-10, 0, 49, 0);
        self.tableView.scrollIndicatorInsets = self.tableView.contentInset;
        [self reloadData];
    }
}

- (void)reloadData {
    self.title = self.portal.name;
    params[@"portals_id"] = self.portal.portalId.stringValue;
    params[@"name"] = self.portal.name.stringByStrippingHTMLItems;
    params[@"subtitle"] = self.portal.subtitle.stringByStrippingHTMLItems;
    params[@"cities_id"] = self.portal.cityId.stringValue;
    params[@"manual_city"] = self.portal.manualCity;
    params[@"categories_id"] = self.portal.categoryId.stringValue;
    params[@"about"] = self.portal.about.stringByStrippingHTMLItems;

    if (self.portal.texts.count > 0) {
        for (NSDictionary *item in self.portal.texts) {
            NSMutableDictionary *d = [[NSMutableDictionary alloc] initWithDictionary:item];
            d[@"title"] = [item[@"title"] stringByStrippingHTMLItems];
            d[@"text"] = [item[@"text"] stringByStrippingHTMLItems];
            [textSections addObject:d];
        }
    }
    if (self.portal.sections.count > 0) {
        [graphicSections removeObjectAtIndex:0];
        for (GraphicSection *section in self.portal.sections.array) {
            NSDictionary *item = @{@"title":section.title.stringByStrippingHTMLItems,
                                   @"id":section.sectionId.stringValue,
                                   @"files":section.files};
            NSMutableDictionary *s = [[NSMutableDictionary alloc] initWithDictionary:item];
            [graphicSections addObject:s];
        }
    }
    [self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

- (void)cancelAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)doneAction {
    [self.view endEditing:YES];
    
    for (NSInteger i = 0; i < titles.count; i++) {
        NSString *value = params[keys[i]];
        if ([value isKindOfClass:[NSString class]] && value.length == 0) {
            NSString *title = titles[i];
            NSString *action = (i > 0 && i < 4) ? @"selected" : @"filled";
            NSString *error = [NSString stringWithFormat:@"%@ must be %@", title, action];
            [SUPPORT showError:error];
            return;
        }
    }
    
    BOOL photoExists = NO;
    for (NSArray *photos in graphicSections) {
        if (photos.count > 0) {
            photoExists = YES;
            break;
        }
    }
    if (!photoExists) {
        [SUPPORT showError:@"Graphics must contain at least one image"];
        return;
    }
    [self registerAction];
}

- (void)registerAction {
    [SUPPORT showLoading:YES];
    
    NSMutableArray *mediaArray = [[NSMutableArray alloc] init];
    NSMutableDictionary *filesParams = [[NSMutableDictionary alloc] init];
    
    NSInteger index = 0;
    for (NSInteger i = 0; i < graphicSections.count; i++) {
        NSMutableDictionary *section = graphicSections[i];
        NSArray *sectionArray = section[@"files"];
        if (sectionArray.count > 0) {
            NSMutableString *indexes = [[NSMutableString alloc] init];
            
            for (id item in sectionArray) {
                if ([item isKindOfClass:[UIImage class]]) {
                    UIImage *image = item;
                    MediaData *mediaData = [[MediaData alloc] initWithData:UIImageJPEGRepresentation(image, 1.0) name:@"photo.jpg" contentType:@"image/jpg"];
                    NSString *indexString = @(index).stringValue;
                    filesParams[[NSString stringWithFormat:@"aMultipleFiles[%@]", indexString]] = mediaData;
                    [indexes appendFormat:@"%@,", indexString];
                    index++;
                }
            }
            
            if (indexes.length > 0)
                [indexes deleteCharactersInRange:NSMakeRange(indexes.length - 1, 1)];
            
            NSMutableDictionary *item = [[NSMutableDictionary alloc] init];
            item[@"title"] = section[@"title"];
            if (section[@"id"])
                item[@"id"] = section[@"id"];
            if (indexes.length > 0)
                item[@"indexes"] = indexes;
            if (item.allKeys.count > 1)
                [mediaArray addObject:item];
        }
    }
    params[@"aSections"] = mediaArray;
    
    if (textSections.count > 0) {
        NSMutableArray *texts = [[NSMutableArray alloc] init];
        for (NSMutableDictionary *obj in textSections) {
            if ([[obj objectForKey:@"title"] length] > 0 &&
                [[obj objectForKey:@"text"] length] > 0) {
                obj[@"title"] = [obj[@"title"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                obj[@"text"] = [obj[@"text"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                [texts addObject:obj];
            }
        }
        params[@"aTexts"] = texts;
    } else {
        params[@"aTexts"] = @[];
    }
    
    if (deletedPhotos.count > 0) {
        params[@"aDeleteGraphicGroupHashes"] = deletedPhotos.allObjects;
    }
    if (deletedSections.count > 0) {
        params[@"aDeletePGSIDs"] = deletedSections.allObjects;
    }
    [DataMNG JSONTo:kServerUrl
     withDictionary:params
         fileParams:filesParams
                log:NO
           function:self.portal ? @"api_edit_portal" : @"api_create_portal"
    completionBlock:^(NSDictionary *json, NSError *error) {
        if (error) {
            [SUPPORT showError:error.localizedDescription];
            [SUPPORT showLoading:NO];
        } else {
            [DATA mappingJSON:json
                         type:MAPPING_PORTAL
             withCompletition:^(NSArray *items) {
                 
                 if (self.portal) {
                     [SUPPORT showLoading:NO];
                     [self cancelAction];
                 } else {
                     if (!self.portal && bankParams) {
                         Portal *portal = [items firstObject];
                         NSMutableDictionary *p = [bankParams mutableCopy];
                         p[@"portals_id"] = portal.portalId.stringValue;
                         bankParams = p;
                         
                         [DataMNG JSONTo:kServerUrl
                          withDictionary:bankParams
                                     log:NO
                                function:@"api_save_portal_bank_account_stripe"
                         completionBlock:^(NSDictionary *json, NSError *error) {
                             [SUPPORT showLoading:NO];
                             if (error) {
                                 [SUPPORT showError:error.localizedDescription];
                             } else {
                                 [self cancelAction];
                             }
                         }];
                     } else {
                         [SUPPORT showLoading:NO];
                         [self cancelAction];
                     }
                 }
             }];
        }
    }];
}

- (IBAction)deleteAction {
    
    NSString *title = @"Are you sure you want to delete Portal and associated goals?";
    [UIAlertView showWithTitle:title
                       message:nil
             cancelButtonTitle:@"Cancel"
             otherButtonTitles:@[@"Delete"]
                      tapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
                          if (buttonIndex == alertView.cancelButtonIndex)
                              return;
                          
                          [DataMNG JSONTo:kServerUrl
                           withDictionary:@{@"portals_id":self.portal.portalId.stringValue}
                                      log:NO
                                 function:@"api_delete_portal"
                          completionBlock:^(NSDictionary *json, NSError *error) {
                              if (error) {
                                  [SUPPORT showError:error.localizedDescription];
                              } else {
                                  if (self.completionBlock)
                                      self.completionBlock();
                                  
                                  [self.navigationController dismissViewControllerAnimated:YES
                                                                                completion:nil];
                              }
                          }];
                      }];
}

#pragma mark - tableview

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return (self.portal && self.portal.userId.integerValue == APP.user.userId.integerValue) ? 4 : 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return titles.count;
            
        case 1:
            return textSections.count + 1;
            
        case 2:
            return graphicSections.count + 1;
            
        case 3:
            return 1;
    }
    
    return 0;
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
    
    if (section == 1) {
        label.text = @"TEXT SECTION:";
    } else if (section == 2) {
        label.text = @"GRAPHIC SECTION:";
    } else if (section == 3) {
        label.text = @"PORTAL PAYMENTS ACCOUNT:";
    }
    
    label.textColor = UIColorFromRGB(0x4d4d4d);
    label.font = [UIFont fontWithName:@"HelveticaNeue" size:14];
    [header addSubview:label];
    
    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 2 && indexPath.row < graphicSections.count) {
        return 87;
    }
    
    if (indexPath.section == 0 && indexPath.row == 5) {
        return [self heightForTitle:titles[indexPath.row]
                           andValue:params[keys[indexPath.row]]];
    }
    
    if (indexPath.section == 1 && textSections.count > indexPath.row) {
        NSDictionary *item = textSections[indexPath.row];
        return [self heightForTitle:item[@"title"]
                           andValue:item[@"text"]];
    }
    
    return 44;
}

- (CGFloat)heightForTitle:(NSString *)title andValue:(NSString *)value {
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 2 && indexPath.row < graphicSections.count) {
        AttachmentsCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AttachmentsCell"];
        NSDictionary *section = graphicSections[indexPath.row];
        cell.section = section;
        return cell;
    } else {
        SignCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SignCell"];
        cell.textField.delegate = self;
        cell.phoneField.delegate = self;
        cell.textView.delegate = self;
        
        if (indexPath.section == 0) {
            cell.title = titles[indexPath.row];
            
            NSString *value = params[keys[indexPath.row]];
            
            if ([value isKindOfClass:[NSString class]]) {
                if (!cell.textField.hidden)
                    cell.textField.text = value;
                else
                    cell.textView.text = value;
            }
            
            BOOL selection = [self needPickerForTitle:cell.title];
            cell.accessoryType = selection ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
            cell.selectionStyle = selection ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone;
            cell.textField.userInteractionEnabled = !selection;
            
            if ([cell.title isEqual:@"Category"]) {
                NSNumber *caregoryId = @([params[@"categories_id"] integerValue]);
                Categories *category = [DataModel getCategoryWithId:caregoryId];
                cell.textField.text = category.name;
            } else if ([cell.title isEqual:@"Portal Leads"]) {
                
                NSMutableString *leadsNames = [NSMutableString new];
                for (NSString *lId in params[@"aLeadsIDs"]) {
                    NSNumber *leadId = @([lId integerValue]);
                    User *user = [DataModel getUserWithId:leadId];
                    [leadsNames appendFormat:@"%@, ", user.fullName];
                }
                if (leadsNames.length > 0)
                    [leadsNames deleteCharactersInRange:NSMakeRange(leadsNames.length - 2, 2)];
                
                cell.textField.text = leadsNames;
            } else if ([cell.title isEqual:@"City"]) {
                NSNumber *cityId = @([params[@"cities_id"] integerValue]);
                if (cityId.integerValue == 0) {
                    cell.textField.text = params[@"manual_city"];
                } else {
                    City *city = [DataModel getCityWithId:cityId];
                    cell.textField.text = city.name;
                }
            }
            
        } else if ((indexPath.section == 1 && textSections.count == indexPath.row) || (indexPath.section == 2 && indexPath.row == graphicSections.count) || indexPath.section == 3) {
            
            if (indexPath.section == 1) {
                cell.title = @"Add Text Section";
            } else if (indexPath.section == 2) {
                cell.title = @"Add Graphic Section";
            } else if (indexPath.section == 3) {
                cell.title = @"Edit Portal Payments";
            }
            
            cell.textField.userInteractionEnabled = NO;
            cell.textField.text = nil;
            cell.textView.text = nil;
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        } else if (indexPath.section == 1 && textSections.count > indexPath.row) {
            cell.infoLabel.text = textSections[indexPath.row][@"title"];
            cell.textField.hidden = YES;
            cell.textView.hidden = NO;
            cell.textView.text = textSections[indexPath.row][@"text"];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;;
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        return cell;
    }
    
    return [UITableViewCell new];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 3) {
        
        PortalPaymentsViewController *controller = [[PortalPaymentsViewController alloc] init];
        if (self.portal) {
            controller.portalId = self.portal.portalId;
        } else {
            controller.bankBlock = ^(NSDictionary *bank) {
                bankParams = bank;
            };
            if (bankParams) {
                controller.bankParams = bankParams;
            }
        }
        [self.navigationController pushViewController:controller animated:YES];
        
    } else if (indexPath.section == 0 && indexPath.row > 0 && indexPath.row < 4) {
        if (indexPath.row == 3) {
            SelectLeadViewController *controller = [[SelectLeadViewController alloc] init];
            controller.multiselect = YES;
            controller.leadIds = params[@"aLeadsIDs"];
            controller.multiPickBlock = ^(NSArray *leads) {
                params[@"aLeadsIDs"] = leads;
                [self.tableView reloadData];
            };
            [self.navigationController pushViewController:controller animated:YES];
        } else {
            PickerViewController *controller = [[PickerViewController alloc] init];
            NSInteger index = 0;
            if (indexPath.row == 1) {
                Categories *category = [[categories filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"categoryId == %@", @([params[@"categories_id"] integerValue])]] firstObject];
                index = [categories indexOfObject:category];
                
                controller.titles = [categories valueForKey:@"name"];
            } else {
                NSInteger cityId = [params[@"cities_id"] integerValue];
                if (cityId > 0) {
                    City *city = [[cities filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"cityId == %@", @([params[@"cities_id"] integerValue])]] firstObject];
                    index = [cities indexOfObject:city];
                } else {
                    index = cities.count;
                }
                
                controller.titles = [cities valueForKey:@"name"];
                controller.manualCity = params[@"manual_city"];
                controller.showOther = YES;
            }
            controller.selectedIndex = index;
            controller.selectBlock = ^(PickerViewController *picker) {
                if (indexPath.row == 1) {
                    Categories *category = categories[picker.selectedIndex];
                    params[@"categories_id"] = category.categoryId.stringValue;
                } else {
                    if (picker.selectedIndex == cities.count) {
                        params[@"cities_id"] = @"0";
                        params[@"manual_city"] = picker.manualCity;
                    } else {
                        City *city = cities[picker.selectedIndex];
                        params[@"cities_id"] = city.cityId.stringValue;
                        params[@"manual_city"] = @"";
                    }
                }
                [self.tableView reloadData];
            };
            [self.navigationController pushViewController:controller animated:YES];
        }
    } if ((indexPath.section == 1 && textSections.count == indexPath.row) || (indexPath.section == 2 && indexPath.row == graphicSections.count)) {
        
        if (indexPath.section == 1) {
            [self addText];
        } else {
            [self addGraphic];
        }
        
    } else if (indexPath.section == 2 && indexPath.row < graphicSections.count) {
        AttachmentsViewController *controller = [[AttachmentsViewController alloc] init];
        controller.title = @"Attachments";
        if (graphicSections.count > indexPath.row)
            controller.photos = graphicSections[indexPath.row][@"files"];
        
        controller.photosBlock = ^(NSArray *photos) {
            NSMutableDictionary *section = graphicSections[indexPath.row];
            section[@"files"] = photos;
            [graphicSections replaceObjectAtIndex:indexPath.row withObject:section];
            [self.tableView reloadData];
        };
        controller.deleteBlock = ^(id photo) {
            if ([photo isKindOfClass:[NSDictionary class]]) {
                [deletedPhotos addObject:[photo objectForKey:@"gr_hash"]];
            }
        };
        [self.navigationController pushViewController:controller animated:YES];
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    BOOL canDelete = (indexPath.section == 2 && indexPath.row < graphicSections.count && graphicSections.count > 1) || (indexPath.section == 1 && textSections.count > indexPath.row);
    return canDelete ? UITableViewCellEditingStyleDelete : UITableViewCellEditingStyleNone;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 2 && indexPath.row < graphicSections.count) {
        NSDictionary *section = graphicSections[indexPath.row];
        if (section[@"id"]) {
            [deletedSections addObject:section[@"id"]];
        }
        [tableView beginUpdates];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [graphicSections removeObjectAtIndex:indexPath.row];
        [tableView endUpdates];
    } else if (indexPath.section == 1 && textSections.count > indexPath.row) {
        [tableView beginUpdates];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [textSections removeObjectAtIndex:indexPath.row];
        [tableView endUpdates];
    }
}

- (void)addText {
   
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Input title for new text section" message:nil delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:@"Add", nil];
    
    alertView.shouldEnableFirstOtherButtonBlock = ^(UIAlertView *alertView) {
        BOOL filled = [alertView textFieldAtIndex:0].text.length > 0;
        return filled;
    };
    alertView.tapBlock = ^(UIAlertView *alertView, NSInteger buttonIndex) {
        if (alertView.cancelButtonIndex == buttonIndex)
            return;
        
        [self.tableView beginUpdates];
        NSMutableDictionary *text = [[NSMutableDictionary alloc] init];
        text[@"title"] = [alertView textFieldAtIndex:0].text;
        text[@"text"] = @"";
        [textSections addObject:text];
        [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForItem:textSections.count - 1 inSection:1]]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    };
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alertView textFieldAtIndex:0].placeholder = @"Title";
    [alertView show];
}

- (void)addGraphic {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Input title for new graphic section" message:nil delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:@"Add", nil];
    
    alertView.shouldEnableFirstOtherButtonBlock = ^(UIAlertView *alertView) {
        BOOL filled = [alertView textFieldAtIndex:0].text.length > 0;
        return filled;
    };
    alertView.tapBlock = ^(UIAlertView *alertView, NSInteger buttonIndex) {
        if (alertView.cancelButtonIndex == buttonIndex)
            return;
        
        [self.tableView beginUpdates];
        NSMutableDictionary *section = [[NSMutableDictionary alloc] init];
        section[@"title"] = [alertView textFieldAtIndex:0].text;
        section[@"files"] = [NSArray array];
        [graphicSections addObject:section];
        [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForItem:graphicSections.count - 1 inSection:2]]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    };
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alertView textFieldAtIndex:0].placeholder = @"Title";
    [alertView show];
}

#pragma mark - text

- (BOOL)needPickerForTitle:(NSString *)title {
    return ([title isEqual:@"Category"] || [title isEqual:@"City"] || [title isEqual:@"Portal Leads"]);
}

- (void)viewWillAdjustingWithKbHeight:(CGFloat)kbOffset {
    CGRect frame = self.tableView.frame;
    frame.size.height -= kbOffset;
    self.tableView.frame = frame;
}

- (void)textViewDidChange:(UITextView *)textView {
    
    CGPoint center = textView.center;
    CGPoint rootViewPoint = [textView.superview convertPoint:center toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:rootViewPoint];
    if (indexPath) {
        if (indexPath.section == 1) {
            NSMutableDictionary *text = textSections[indexPath.row];
            text[@"text"] = textView.text;
            [textSections replaceObjectAtIndex:indexPath.row withObject:text];
        } else {
            params[keys[indexPath.row]] = textView.text;
        }
    }
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
}

- (void)textFieldDidChange:(UITextField *)textField {
    CGPoint center = textField.center;
    CGPoint rootViewPoint = [textField.superview convertPoint:center toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:rootViewPoint];
    if (!indexPath)
        return;
    
    if (indexPath.section == 1) {
        NSMutableDictionary *text = textSections[indexPath.row];
        text[@"title"] = textField.text;
        [textSections replaceObjectAtIndex:indexPath.row withObject:text];
    } else {
        NSString *text = textField.text;
        params[keys[indexPath.row]] = text;
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    CGPoint center = textField.center;
    CGPoint rootViewPoint = [textField.superview convertPoint:center toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:rootViewPoint];
    if (indexPath && indexPath.section == 0) {
        NSString *text = textField.text;
        params[keys[indexPath.row]] = text;
    }
}

@end
