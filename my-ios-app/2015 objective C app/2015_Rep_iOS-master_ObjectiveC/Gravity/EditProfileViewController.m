//
//  EditProfileViewController.m
//  Gravity
//
//  Created by Vlad Getman on 19.11.14.
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

#import "EditProfileViewController.h"
#import "AppDelegate.h"
#import "EditCell.h"
#import "UserType.h"
#import "SkillsViewController.h"
#import "PickerViewController.h"

@interface EditProfileViewController ()

@end

@implementation EditProfileViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        UIBarButtonItem *cancelAction = [[UIBarButtonItem alloc] initWithTitle:@"Cancel"
                                                                         style:UIBarButtonItemStylePlain
                                                                        target:self
                                                                        action:@selector(cancelAction)];
        self.navigationItem.leftBarButtonItem = cancelAction;
        
        UIBarButtonItem *doneBtn = [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                                                    style:UIBarButtonItemStyleDone
                                                                   target:self
                                                                   action:@selector(doneAction)];
        self.navigationItem.rightBarButtonItem = doneBtn;
        
        params = [[NSMutableDictionary alloc] init];
        skillIds = [[NSMutableDictionary alloc] init];
        
        cities = [DATA fetchData:@"City"
                  withDescriptor:@[[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES selector:nil]]
                   withPredicate:nil
                  withAttributes:nil];
        userTypes = [DATA fetchData:@"UserType"
                     withDescriptor:@[[[NSSortDescriptor alloc] initWithKey:@"userTypeId" ascending:YES selector:nil]]
                      withPredicate:nil
                     withAttributes:nil];
        skills = [DATA fetchData:@"Skill"
                  withDescriptor:@[[[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:YES selector:nil]]
                   withPredicate:nil
                  withAttributes:nil];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    photoView.layer.cornerRadius = CGRectGetHeight(photoView.frame) / 2;
    UIView *separator = [self.tableView.tableHeaderView viewWithTag:100];
    CGRect frame = separator.frame;
    frame.size.height = 0.5;
    frame.origin.y += 0.5;
    separator.frame = frame;
    self.tableView.tableFooterView = [UIView new];
    [self.tableView registerCellClass:[EditCell class]
                       withIdentifier:@"EditCell"];
    
    self.title = self.newUser ? @"Create User Profile" : @"Edit User Profile";
    
    NSMutableArray *t = [[NSMutableArray alloc] initWithArray:@[@"Name", @"User type", @"Broadcast", @"Phone", @"Email", @"Home city", @"Bio", @"Skill 1", @"Skill 2", @"Skill 3", @"Other Skill"]];
    
    if (!self.newUser) {
        [self reloadData];
    } else {
        [t insertObject:@"Password" atIndex:5];
    }
    titles = [NSArray arrayWithArray:t];
}

- (void)reloadData {
    [photoView sd_setImageWithURL:[NSURL URLWithString:APP.user.photo] placeholderImage:nil];
    params[@"name"] = APP.user.fullName;
    params[@"broadcast"] = APP.user.broadcast.stringByStrippingHTMLItems;
    params[@"phone"] = APP.user.phone;
    params[@"email"] = APP.user.email;
    params[@"home city"] = APP.user.cityId.stringValue;
    params[@"bio"] = APP.user.about.stringByStrippingHTMLItems;
    params[@"user type"] = APP.user.userTypeId.stringValue;
    params[@"other skill"] = APP.user.otherSkill;
    params[@"manual_city"] = APP.user.manualCity;
    
    for (NSInteger i = 0; i < APP.user.skills.count; i++) {
        NSDictionary *s = APP.user.skills[i];
        NSNumber *skillId = @([s[@"id"] integerValue]);
        skillIds[@(i).stringValue] = skillId;
    }
}

- (void)cancelAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)doneAction {
    [self.view endEditing:YES];
    
    for (NSString *key in params.allKeys) {
        params[key] = [params[key] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    
    NSArray *names = [params[@"name"] componentsSeparatedByString:@" "];
    if (names.count != 2) {
        [SUPPORT showError:@"Name must contain First and Last Name"];
        return;
    }
    
    if ([params[@"manual_city"] length] == 0 && [params[@"home city"] integerValue] == 0) {
        [SUPPORT showError:@"Other city must be filled"];
        return;
    }
    
    /*if (skillIds.allKeys.count != 3) {
        [SUPPORT showError:@"You must select three skills"];
        return;
    }*/
    
    if (self.newUser) {
        for (NSString *key in titles) {
            if (![key hasPrefix:@"Skill"] && [params[[key lowercaseString]] length] == 0) {
                NSString *error = [NSString stringWithFormat:@"%@ must be filled", key];
                [SUPPORT showError:error];
                return;
            }
        }
    }
    
    NSMutableDictionary *jsonParams = [[NSMutableDictionary alloc] initWithDictionary:params];
    
    for (NSString *key in @[@"user type", @"home city", @"bio"]) {
        [jsonParams removeObjectForKey:key];
    }
    
    jsonParams[@"users_types_id"] = params[@"user type"];
    jsonParams[@"about"] = params[@"bio"];
    jsonParams[@"cities_id"] = params[@"home city"];
    jsonParams[@"fname"] = [names firstObject];
    jsonParams[@"lname"] = [names lastObject];
    jsonParams[@"other_skill"] = params[@"other skill"];
    jsonParams[@"manual_city"] = params[@"manual_city"];
    
    if (skillIds.count > 0)
        jsonParams[@"aSkills"] = [NSDictionary dictionaryWithDictionary:skillIds];
    
    NSDictionary *photoData;
    if (photo) {
        MediaData *mediaData = [[MediaData alloc] initWithData:UIImageJPEGRepresentation(photo, 1)
                                                          name:@"photo.jpg"
                                                   contentType:@"image/jpg"];
        photoData = @{@"img_name": mediaData};
    }
    
    [SUPPORT showLoading:YES];
    
    [DataMNG JSONTo:kServerUrl
     withDictionary:jsonParams
         fileParams:photoData
                log:NO
           function:self.newUser ? @"api_register_user" : @"api_edit_user"
    completionBlock:^(NSDictionary *json, NSError *error) {
        if (error) {
            [SUPPORT showError:error.localizedDescription];
        } else {
            [DATA mappingJSON:json
                         type:MAPPING_USER
             withCompletition:^(NSArray *items) {
                 if (items.count > 0) {
                     
                     APP.user = [items firstObject];
                     if (self.newUser) {
                         [Settings setObject:params[@"email"] forKey:@"email"];
                         [Settings synchronize];
                         [Keychain setObject:params[@"password"] forKey:@"password"];
                         
                         [APP startApp];
                     } else {
                         [self dismissViewControllerAnimated:YES completion:nil];
                     }
                 }
             }];
        }
        [SUPPORT showLoading:NO];
    }];
}

#pragma mark tableview

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return titles.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *title = titles[indexPath.row];
    if ([title isEqual:@"Broadcast"] || [title isEqual:@"Bio"]) {
        UIFont *font = [UIFont fontWithName:@"HelveticaNeue-Light" size:17];
        title = [title stringByAppendingString:@":"];
        CGFloat titleWidth = [UIUtils findWidthForText:title
                                          havingHeight:21
                                               andFont:font];
        titleWidth = MAX(titleWidth, 45);
        CGFloat viewWidth = CGRectGetWidth(tableView.frame) - titleWidth - 36;
        CGFloat height = [UIUtils findHeightForText:params[[titles[indexPath.row] lowercaseString]]
                                        havingWidth:viewWidth
                                            andFont:font];
        
        height += 30;
        return MAX(50, height);
    }
    
    return 50;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    EditCell *cell = [tableView dequeueReusableCellWithIdentifier:@"EditCell"];
    
    cell.title = titles[indexPath.row];
    
    cell.textField.delegate = self;
    cell.phoneField.delegate = self;
    cell.textView.delegate = self;
    
    cell.textField.text = params[[titles[indexPath.row] lowercaseString]];
    
    if ([cell.title isEqual:@"Phone"]) {
        [cell.phoneField setFormattedText:cell.textField.text];
    } else if ([cell.title isEqual:@"Home city"]) {
        NSInteger cityId = [params[@"home city"] integerValue];
        if (cityId > 0) {
            City *city = [[cities filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"cityId == %@", @(cityId)]] firstObject];
            cell.textField.text = city.name;
        } else {
            cell.textField.text = params[@"manual_city"];
        }
    } else if ([cell.title isEqual:@"User type"]) {
        UserType *userType = [[userTypes filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"userTypeId == %@", @([params[@"user type"] integerValue])]] firstObject];
        cell.textField.text = userType.title;
    } else if ([cell.title isEqual:@"Broadcast"] || [cell.title isEqual:@"Bio"]) {
        cell.textView.text = params[[titles[indexPath.row] lowercaseString]];
    } else if ([cell.title hasPrefix:@"Skill"]) {
        NSString *index = @([[cell.title substringFromIndex:6] integerValue] - 1).stringValue;
        NSNumber *skillId = skillIds[index];
        if (skillId) {
            Skill *skill = [DataModel getSkillWithId:skillId];
            cell.textField.text = skill.skillDescription;
        }
    }
    return cell;
}

#pragma mark textfield

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    
    CGPoint center = textField.center;
    CGPoint rootViewPoint = [textField.superview convertPoint:center toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:rootViewPoint];
    if (!indexPath)
        return YES;
    
    NSString *title = titles[indexPath.row];
    if ([title isEqual:@"User type"] || [title isEqual:@"Home city"]) {
        [self.view endEditing:YES];
        
        UIBarButtonItem *btnBack = [[UIBarButtonItem alloc]
                                    initWithTitle:@" "
                                    style:UIBarButtonItemStylePlain
                                    target:self
                                    action:nil];
        self.navigationController.navigationBar.topItem.backBarButtonItem = btnBack;
        
        PickerViewController *controller = [[PickerViewController alloc] init];
        NSInteger index = 0;
        if (indexPath.row == 1) {
            UserType *userType = [[userTypes filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"userTypeId == %@", @([params[@"user type"] integerValue])]] firstObject];
            index = [userTypes indexOfObject:userType];
            
            controller.titles = [userTypes valueForKey:@"title"];
        } else {
            NSInteger cityId = [params[@"home city"] integerValue];
            if (cityId > 0) {
                City *city = [[cities filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"cityId == %@", @([params[@"home city"] integerValue])]] firstObject];
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
                UserType *userType = userTypes[picker.selectedIndex];
                params[@"user type"] = userType.userTypeId.stringValue;
            } else {
                if (picker.selectedIndex == cities.count) {
                    params[@"home city"] = @"0";
                    params[@"manual_city"] = picker.manualCity;
                } else {
                    City *city = cities[picker.selectedIndex];
                    params[@"home city"] = city.cityId.stringValue;
                    params[@"manual_city"] = @"";
                }
            }
            [self.tableView reloadData];
        };
        [self.navigationController pushViewController:controller animated:YES];

        return NO;
    } else if ([title hasPrefix:@"Skill"]) {
        SkillsViewController *controller = [[SkillsViewController alloc] init];
        controller.selectionBlock = ^(NSNumber *skillId) {
            NSString *index = @([[title substringFromIndex:6] integerValue] - 1).stringValue;
            skillIds[index] = skillId;
            [self.tableView reloadData];
        };
        [self.navigationController pushViewController:controller animated:YES];
        
        return NO;
    }
    
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    CGPoint center = textField.center;
    CGPoint rootViewPoint = [textField.superview convertPoint:center toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:rootViewPoint];
    if (indexPath) {
        NSString *text = textField.text;
        if ([textField isKindOfClass:[SHSPhoneTextField class]]) {
            SHSPhoneTextField *field = (SHSPhoneTextField *)textField;
            text = field.phoneNumber;
        }
        params[[titles[indexPath.row] lowercaseString]] = text;
        
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    CGPoint center = textView.center;
    CGPoint rootViewPoint = [textView.superview convertPoint:center toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:rootViewPoint];
    if (indexPath) {
        params[[titles[indexPath.row] lowercaseString]] = textView.text;
    }
}

- (void)textViewDidChange:(UITextView *)textView {
    CGPoint center = textView.center;
    CGPoint rootViewPoint = [textView.superview convertPoint:center toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:rootViewPoint];
    if (indexPath) {
        params[[titles[indexPath.row] lowercaseString]] = textView.text;
    }
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
}

- (void)viewWillAdjustingWithKbHeight:(CGFloat)kbOffset {
    CGRect frame = self.tableView.frame;
    frame.size.height -= kbOffset;
    self.tableView.frame = frame;
}

#pragma mark picker

- (IBAction)photoAction {
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.allowsEditing = YES;
    imagePicker.delegate = self;
    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:imagePicker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    photo = [info objectForKey:UIImagePickerControllerEditedImage];
    photoView.image = photo;
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

@end
