//
//  SignUpViewController.m
//  Gravity
//
//  Created by Vlad Getman on 04.02.15.
//  Copyright (c) 2015 HalcyonInnovation. All rights reserved.
//

#import "SignUpViewController.h"
#import "ProfileCell.h"
#import "SignCell.h"
#import "SkillsViewController.h"
#import "PickerViewController.h"
#import "AppDelegate.h"

@interface SignUpViewController ()

@end

@implementation SignUpViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.title = @"Sign Up";
        
        titles = @[@"Name", /*@"User type", @"Broadcast", @"Phone", */@"Email", @"Password", @"Confirm Password", @"Home city"/*, @"Bio", @"Skill 1", @"Skill 2", @"Skill 3"*/];
        
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
    [registrationBtn backgroundToImage];
    registrationBtn.layer.cornerRadius = 5;
    
    self.tableView.contentInset = UIEdgeInsetsMake(-10, 0, 0, 0);
    [self.tableView registerCellClass:[ProfileCell class]
                       withIdentifier:@"ProfileCell"];
    [self.tableView registerCellClass:[SignCell class]
                       withIdentifier:@"SignCell"];
}

- (IBAction)signUp {
    [self.view endEditing:YES];
    
    for (NSString *key in params.allKeys) {
        params[key] = [params[key] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    
    NSArray *names = [params[@"name"] componentsSeparatedByString:@" "];
    if (names.count != 2) {
        [SUPPORT showError:@"Name must contain First and Last Name"];
        return;
    }
    
    for (NSString *key in titles) {
        if (![key hasPrefix:@"Skill"] && [params[[key lowercaseString]] length] == 0) {
            NSString *error = [NSString stringWithFormat:@"%@ must be filled", key];
            [SUPPORT showError:error];
            return;
        }
    }
    
    if (![params[@"password"] isEqual:params[@"confirm password"]]) {
        [SUPPORT showError:@"Passwords must be equal"];
        return;
    }
    
    /*if (skillIds.allKeys.count != 3) {
        [SUPPORT showError:@"You must select three skills"];
        return;
    }*/
    
    NSMutableDictionary *jsonParams = [[NSMutableDictionary alloc] initWithDictionary:params];
    
    for (NSString *key in @[@"user type", @"home city", @"bio", @"confirm password"]) {
        [jsonParams removeObjectForKey:key];
    }
    
    NSArray *types = [DATA fetchData:@"UserType"
                      withDescriptor:nil
                       withPredicate:[NSPredicate predicateWithFormat:@"title LIKE[c] %@", @"Network"]
                      withAttributes:nil];
    if (types.count > 0) {
        UserType *type = [types firstObject];
        jsonParams[@"users_types_id"] = type.userTypeId.stringValue;
    } else {
        jsonParams[@"users_types_id"] = @"3";
    }
    
    if ([params[@"manual_city"] length] == 0 && [params[@"home city"] integerValue] == 0) {
        [SUPPORT showError:@"Other city must be filled"];
        return;
    }
    
    //jsonParams[@"users_types_id"] = params[@"user type"];
    //jsonParams[@"about"] = params[@"bio"];
    jsonParams[@"cities_id"] = params[@"home city"];
    jsonParams[@"fname"] = [names firstObject];
    jsonParams[@"lname"] = [names lastObject];
    jsonParams[@"manual_city"] = params[@"manual_city"];
    //jsonParams[@"aSkills"] = [NSDictionary dictionaryWithDictionary:skillIds];
    
    NSDictionary *photoData;
    if (photo) {
        MediaData *mediaData = [[MediaData alloc] initWithData:UIImageJPEGRepresentation(photo, 1)
                                                          name:@"photo.jpg"
                                                   contentType:@"image/jpg"];
        photoData = @{@"img_name": mediaData};
    }
    
    [DataMNG JSONTo:kServerUrl
     withDictionary:jsonParams
         fileParams:photoData
                log:NO
           function:@"api_register_user"
    completionBlock:^(NSDictionary *json, NSError *error) {
        if (error) {
            [SUPPORT showError:error.localizedDescription];
        } else {
            [DATA mappingJSON:json
                         type:MAPPING_USER
             withCompletition:^(NSArray *items) {
                 if (items.count > 0) {
                     
                     APP.user = [items firstObject];
                     [Settings setObject:params[@"email"] forKey:@"email"];
                     [Settings synchronize];
                     [Keychain setObject:params[@"password"] forKey:@"password"];
                     
                     [APP startApp];
                 }
             }];
        }
    }];
}

#pragma mark tableview

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return section == 0 ? 1 : titles.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return section == 0 ? 0 : 15;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *title = titles[indexPath.row];
    if ([title isEqual:@"Broadcast"] || [title isEqual:@"Bio"]) {
        UIFont *font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:14];
        CGFloat titleWidth = [UIUtils findWidthForText:title
                                          havingHeight:21
                                               andFont:font];
        titleWidth = MAX(titleWidth, 45);
        CGFloat viewWidth = CGRectGetWidth(tableView.frame) - titleWidth - 36 - 10;
        CGFloat height = [UIUtils findHeightForText:params[[titles[indexPath.row] lowercaseString]]
                                        havingWidth:viewWidth
                                            andFont:font];
        
        height += 26;
        return MAX(44, height);
    }
    
    return 44;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 0) {
        ProfileCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ProfileCell"];
        cell.photoView.image = photo ? photo : [UIImage imageNamed:@"PhotoPlaceholder"];
        return cell;
    } else {
        SignCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SignCell"];
        cell.title = titles[indexPath.row];
        
        cell.textField.delegate = self;
        cell.phoneField.delegate = self;
        cell.textView.delegate = self;
        
        cell.textField.text = params[[titles[indexPath.row] lowercaseString]];
        
        BOOL selection = [self needPickerForTitle:cell.title];
        cell.accessoryType = selection ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
        cell.selectionStyle = selection ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone;
        cell.textField.userInteractionEnabled = !selection;
        
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
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0) {
        UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil
                                                           delegate:self
                                                  cancelButtonTitle:@"Cancel"
                                             destructiveButtonTitle:nil
                                                  otherButtonTitles:@"Camera Roll", @"Take a photo", nil];
        [sheet showInView:self.view];
    } else if (indexPath.section == 1 && [self needPickerForTitle:titles[indexPath.row]]) {
        NSString *title = titles[indexPath.row];
        
        [self.view endEditing:YES];
        UIBarButtonItem *btnBack = [[UIBarButtonItem alloc]
                                    initWithTitle:@" "
                                    style:UIBarButtonItemStylePlain
                                    target:self
                                    action:nil];
        self.navigationController.navigationBar.topItem.backBarButtonItem = btnBack;
        
        if ([title isEqual:@"User type"] || [title isEqual:@"Home city"]) {
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
        } else if ([title hasPrefix:@"Skill"]) {
            SkillsViewController *controller = [[SkillsViewController alloc] init];
            controller.selectionBlock = ^(NSNumber *skillId) {
                NSString *index = @([[title substringFromIndex:6] integerValue] - 1).stringValue;
                skillIds[index] = skillId;
                [self.tableView reloadData];
            };
            [self.navigationController pushViewController:controller animated:YES];
        }
    }
}

#pragma mark photo

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (actionSheet.cancelButtonIndex == buttonIndex)
        return;
    
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.sourceType = buttonIndex == 0 ? UIImagePickerControllerSourceTypePhotoLibrary : UIImagePickerControllerSourceTypeCamera;
    picker.allowsEditing = YES;
    [self.navigationController presentViewController:picker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    photo = [info objectForKey:UIImagePickerControllerEditedImage];
    [self.tableView reloadData];
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark textfield

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (BOOL)needPickerForTitle:(NSString *)title {
    return ([title isEqual:@"User type"] || [title isEqual:@"Home city"] || [title hasPrefix:@"Skill"]);
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

@end
