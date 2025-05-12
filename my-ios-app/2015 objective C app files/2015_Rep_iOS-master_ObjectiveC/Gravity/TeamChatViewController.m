//
//  TeamChatViewController.m
//  Gravity
//
//  Created by Vlad Getman on 10.14.14
//  Copyright (c) 2014 HalcyonLA. All rights reserved.
//

#import "TeamChatViewController.h"
#import "ProfileViewController.h"
#import "AppDelegate.h"
#import "PortalDetailViewController.h"
#import "LeadCell.h"
#import "InviteNetworksCell.h"

@interface NetworkDelegate ()

@end

@implementation NetworkDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return self.network.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 90;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    InviteNetworksCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellIdentifier"];
    cell.user = self.network[indexPath.row];
    cell.inviteBtn.selected = [self.ids containsObject:cell.user.userId.stringValue];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    
    [cell.inviteBtn addTarget:self.target
                       action:@selector(inviteAction:)
             forControlEvents:UIControlEventTouchUpInside];
    
#pragma clang diagnostic pop
    return cell;
}


@end

@interface TeamChatViewController ()

@end

@implementation TeamChatViewController

- (id)init
{
    self = [super init];
    if (self) {
        
        UIBarButtonItem *backBtn = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"BtnBack"]
                                                                    style:UIBarButtonItemStylePlain
                                                                   target:self
                                                                   action:@selector(backAction)];

        self.navigationItem.leftBarButtonItem = backBtn;
        
        /*photoView = [[ImageButton alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
        photoView.layer.cornerRadius = CGRectGetHeight(photoView.frame) / 2;
        photoView.layer.masksToBounds = YES;
        photoView.contentMode = UIViewContentModeScaleAspectFill;
        [photoView addTarget:self action:@selector(profileAction)];
        
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:photoView];*/
        
        self.title = @"Team Chat";
        
        self.view.backgroundColor = [UIColor whiteColor];
        chatData = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.collectionView registerCellClass:[LeadCell class]];
    [self.networkTableView registerCellClass:[InviteNetworksCell class]];
    self.networkTableView.tableFooterView = [UIView new];
    
    networkDelegate = [[NetworkDelegate alloc] init];
    self.networkTableView.delegate = networkDelegate;
    self.networkTableView.dataSource = networkDelegate;
    networkDelegate.target = self;
    networkDelegate.ids = [[NSMutableSet alloc] init];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    CGRect frame = self.tableView.frame;
    frame.size.height -= 102;
    frame.origin.y += 102;
    self.tableView.frame = frame;
    [self.view insertSubview:pickerView aboveSubview:self.inputView];
    [self showTeamPicker:NO animated:NO];
    
    [addBtn setBackgroundImage:[UIUtils roundedImageWithSize:addBtn.frame.size
                                                    andColor:addBtn.backgroundColor
                                                  withBorder:YES]
                      forState:UIControlStateNormal];
    addBtn.backgroundColor = nil;
    
    if (self.chatId) {
        Chat *chat = [DataModel getItem:[Chat class] withId:self.chatId];
        if (!chat)
            return;
        
        if (chat.title.length > 0) {
            self.title = chat.title.stringByStrippingHTMLItems;
            self.chatName = chat.title.stringByStrippingHTMLItems;
        }
        if (chat.userId.integerValue == APP.user.userId.integerValue) {
            [self showRenameOption];
        }
        
    } else {
        [self showRenameOption];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = NO;
    /*User *user = [DataModel getUserWithId:self.userId];
    if (user) {
        self.title = user.fullName;
        [photoView setImageWithURL:[NSURL URLWithString:user.photo]
                  placeholderImage:nil
       usingActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    }*/
    [self loadData:0];
    [self startUpdating:YES];
    [self getChatUsers];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.navigationController.navigationBarHidden = YES;
    [self startUpdating:NO];
}


/*- (void)profileAction {
    ProfileViewController *controller = [[ProfileViewController alloc] init];
    controller.userId = self.userId;
    controller.hidesBottomBarWhenPushed = self.userId.integerValue != APP.user.userId.integerValue;
    [self.navigationController pushViewController:controller animated:YES];
}*/

- (void)showRenameOption {
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Rename" style:UIBarButtonItemStyleDone target:self action:@selector(doRename)];
}

- (void)doRename {
    [self.view endEditing:YES];
    
    self.inputView.preventKeybordOffset = YES;
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Rename chat"
                                                        message:nil
                                                       delegate:nil
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"Rename", nil];
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alertView textFieldAtIndex:0].placeholder = @"Chat Name";
    [alertView textFieldAtIndex:0].autocapitalizationType = UITextAutocapitalizationTypeWords;
    alertView.shouldEnableFirstOtherButtonBlock = ^(UIAlertView *alertView) {
        return @([alertView textFieldAtIndex:0].text.length > 0).boolValue;
    };
    alertView.tapBlock = ^(UIAlertView *alertView, NSInteger buttonIndex) {
        if (alertView.cancelButtonIndex == buttonIndex)
            return;
        [self.view endEditing:YES];
        self.chatName = [alertView textFieldAtIndex:0].text;
        if (self.chatId) {
            [self changeName];
        }
    };
    alertView.didDismissBlock = ^(UIAlertView *alertView, NSInteger buttonIndex) {
        self.inputView.preventKeybordOffset = NO;
    };
    [alertView show];
}

- (void)changeName {

    if ([self.title isEqual:self.chatName])
        return;
    
    [SUPPORT showLoading:YES];
    NSDictionary *params = @{@"chats_id":self.chatId.stringValue,
                             @"title":self.chatName};
    
    [DataMNG JSONTo:kServerUrl
     withDictionary:params
                log:NO
           function:@"api_manage_chat"
    completionBlock:^(NSDictionary *json, NSError *error) {
        if (error) {
            [SUPPORT showError:error.localizedDescription];
            
        } else {
            self.title = self.chatName;
        }
        [SUPPORT showLoading:NO];
    }];
}

- (void)getNetwork {
    NSMutableDictionary *params = [NSMutableDictionary new];
    params[@"users_id"] = APP.user.userId.stringValue;
    if (self.chatId)
        params[@"not_in_chats_id"] = self.chatId;
    
    [DataMNG JSONTo:kServerUrl
     withDictionary:params
                log:NO
           function:@"api_members_of_my_network"
    completionBlock:^(NSDictionary *json, NSError *error) {
        [DATA mappingJSON:json
                     type:MAPPING_USERS
         withCompletition:^(NSArray *items) {
             networkDelegate.network = items;
             [self.networkTableView reloadData];
         }];
    }];
}

- (void)getChatUsers {
    if (!self.chatId)
        return;
    
    [DataMNG JSONTo:kServerUrl
     withDictionary:@{@"chats_id":self.chatId.stringValue}
                log:NO
           function:@"api_get_chat_users"
    completionBlock:^(NSDictionary *json, NSError *error) {
        [DATA mappingJSON:json
                     type:MAPPING_USERS
         withCompletition:^(NSArray *items) {
             users = items;
             [self.collectionView reloadData];
         }];
    }];
}

- (IBAction)addToChat {
    if (networkDelegate.ids.count == 0)
        return;
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    if (self.chatId)
        params[@"chats_id"] = self.chatId.stringValue;
    params[@"aAddIDs"] = networkDelegate.ids.allObjects;
    if (self.chatName.length > 0 && !self.chatId) {
        params[@"title"] = self.chatName;
    }
    
    [DataMNG JSONTo:kServerUrl
     withDictionary:params
                log:NO
           function:@"api_manage_chat"
    completionBlock:^(NSDictionary *json, NSError *error) {
        if (error) {
            [SUPPORT showError:error.localizedDescription];
        } else {
            if (!self.chatId) {
                self.chatId = @([json[@"chats_id"] integerValue]);
                [self loadData:0];
                [self getChatUsers];
                [self doRename];
            }
            [self closePicker];
        }
    }];
}

- (IBAction)showPicker {
    if (pickerView.alpha == 1)
        return;
    
    [self getNetwork];
    [networkDelegate.ids removeAllObjects];
    
    [self showTeamPicker:YES animated:YES];
}

- (IBAction)closePicker {
    [self showTeamPicker:NO animated:YES];
}

- (void)showTeamPicker:(BOOL)show animated:(BOOL)animated {
    
    [UIView animateWithDuration:animated ? 0.25 : 0
                          delay:show ? (animated ? 0.15 : 0) : 0
                        options:0
                     animations:^{
                         CGRect frame = self.networkTableView.frame;
                         frame.origin.y = show ? 0 : CGRectGetHeight(self.view.frame);
                         self.networkTableView.frame = frame;
                     } completion:nil];
    
    [UIView animateWithDuration:animated ? 0.3 : 0
                          delay:!show ? (animated ? 0.15 : 0) : 0
                        options:0
                     animations:^{
                         pickerView.alpha = show ? 1 : 0;
                     } completion:nil];
}

- (void)backAction {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - SOMessaging data source
- (NSMutableArray *)messages
{
    return chatData;
}

- (NSTimeInterval)intervalForMessagesGrouping
{
    // Return 0 for disableing grouping
    return 2 * 24 * 3600;
}

- (CGSize)userImageSize
{
    return CGSizeMake(40, 40);
}

- (CGFloat)messageMinHeight
{
    return 0;
}

- (CGFloat)messageMaxWidth {
    return CGRectGetWidth(self.view.frame) * 3/4 - 60;
}

- (UIFont *)messageFont
{
    return [UIFont systemFontOfSize:15];
}

- (void)configureMessageCell:(SOMessageCell *)cell forMessageAtIndex:(NSInteger)index
{
    
    SOMessage *message = chatData[index];
    cell.textView.textColor = message.fromMe ? [UIColor appGreen] : [UIColor blackColor];
    
    cell.userImageView.layer.cornerRadius = self.userImageSize.width / 2;
    
    // Fix user image position on top or bottom.
    cell.userImageView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
    [cell setUserImageViewSize:CGSizeMake(message.fromMe ? 0 : 40, message.fromMe ? 0 : 40)];
    
    if (message.fromMe) {
        [cell.userImageView sd_cancelCurrentImageLoad];
    } else {
        cell.userImage = [UIImage imageNamed:@"PhotoPlaceholder"];
        User *user = [DataModel getUserWithId:message.message.userId1];
        [cell.userImageView sd_setImageWithURL:[NSURL URLWithString:user.photoSmall]
                                     completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                         if (image)
                                             cell.userImage = image;
                                         else
                                             [UIImage imageNamed:@"PhotoPlaceholder"];
                                     }];
    }
}

#pragma mark - SOMessaging delegate

- (void)messageCell:(SOMessageCell *)cell didTapPortal:(Portal *)portal {
    
    if (!portal)
        return;
    
    PortalDetailViewController *controller = [[PortalDetailViewController alloc] init];
    controller.portalId = portal.portalId;
    controller.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)messageInputView:(SOMessageInputView *)inputView didSendMessage:(NSString *)message
{
    
    if (!self.chatId)
        return;
    
    message = [message stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if ([message length] == 0) {
        return;
    }
    
    [[DataManager sharedDataManager] JSONTo:kServerUrl
                             withDictionary:@{@"chats_id":self.chatId.stringValue,@"message":message}
                                        log:NO
                                   function:@"api_send_chat_message"
                            completionBlock:^(NSDictionary *json, NSError *error) {
                                if (error) {
                                    [SUPPORT showError:error.localizedDescription];
                                } else {
                                    //[self checkNewMessages];
                                }
                            }];
}

- (void)loadData:(NSInteger)offset {
    
    if (!self.chatId)
        return;
    
    [[DataManager sharedDataManager] JSONTo:kServerUrl
                             withDictionary:@{@"chats_id":self.chatId.stringValue,@"order":@"ASC",@"limit":@"50",@"offset":@(offset).stringValue}
                                        log:NO
                                   function:@"api_get_messages"
                            completionBlock:^(NSDictionary *json, NSError *error) {
                                
                                if (offset == 0) [chatData removeAllObjects];
                                
                                NSArray *messages = [DATA mappingJSON:json type:MAPPING_MESSAGES];
                                
                                for (Message *message in messages) {
                                    SOMessage *messageItem = [[SOMessage alloc] init];
                                    messageItem.text = [message.text stringByStrippingHTMLItems];
                                    messageItem.date = message.timestamp;
                                    messageItem.fromMe = message.userId1 == APP.user.userId;
                                    messageItem.type = SOMessageTypeText;
                                    messageItem.message = message;
                                    
                                    [chatData addObject:messageItem];
                                }
                                [self refreshMessagesAnimated:NO];
                            }];
}

- (void)startUpdating:(BOOL)start {
    if (start) {
        timer = [NSTimer scheduledTimerWithTimeInterval:5
                                                 target:self
                                               selector:@selector(checkNewMessages)
                                               userInfo:nil
                                                repeats:YES];
        
    } else {
        [timer invalidate];
        timer = nil;
    }
}

- (void)checkNewMessages {
    
    if (!self.chatId)
        return;
    
    if (chatData.count > 0) {
        
        NSInteger maxId = 0;
        
        for (SOMessage *bubble in chatData) {
            if (maxId < bubble.message.messageId.integerValue) {
                maxId = bubble.message.messageId.integerValue;
            }
        }
        
        [[DataManager sharedDataManager] JSONTo:kServerUrl
                                 withDictionary:@{@"chats_id":self.chatId.stringValue,@"order":@"ASC",@"limit":@"100", @"newer_than_id":@(maxId).stringValue}
                                            log:NO
                                       function:@"api_get_messages"
                                completionBlock:^(NSDictionary *json, NSError *error) {
                                    
                                    NSArray *messages = [DATA mappingJSON:json type:MAPPING_MESSAGES];
                                    
                                    if (messages.count > 0) {
                                        for (Message *message in messages) {
                                            
                                            SOMessage *messageItem = [[SOMessage alloc] init];
                                            messageItem.text = message.text;
                                            messageItem.date = [message.timestamp currentTimezone];
                                            messageItem.fromMe = message.userId1 == APP.user.userId;
                                            messageItem.type = SOMessageTypeText;
                                            messageItem.message = message;
                                            
                                            if (messageItem.fromMe)
                                                [self sendMessage:messageItem];
                                            else
                                                [self receiveMessage:messageItem];
                                        }
                                    }
                                }];
    } else {
        [self loadData:0];
    }
}

#pragma mark collectionview

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return users.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    LeadCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cellIdentifier" forIndexPath:indexPath];
    cell.user = users[indexPath.row];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    User *user = users[indexPath.row];
    ProfileViewController *controller = [[ProfileViewController alloc] init];
    controller.userId = user.userId;
    controller.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:controller animated:YES];
}

#pragma mark tableview

- (void)inviteAction:(UIButton *)sender {
    CGPoint center = sender.center;
    CGPoint rootViewPoint = [sender.superview convertPoint:center toView:self.networkTableView];
    NSIndexPath *indexPath = [self.networkTableView indexPathForRowAtPoint:rootViewPoint];
    if (!indexPath)
        return;
    
    User *user = networkDelegate.network[indexPath.row];
    NSString *itemId = user.userId.stringValue;
    
    if (![networkDelegate.ids containsObject:itemId]) {
        [networkDelegate.ids addObject:itemId];
    } else {
        [networkDelegate.ids removeObject:itemId];
    }
    sender.selected = !sender.selected;
}

@end
