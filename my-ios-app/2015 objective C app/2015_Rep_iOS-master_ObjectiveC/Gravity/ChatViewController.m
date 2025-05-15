//
//  ChatViewController.m
//  Gravity
//
//  Created by Vlad Getman on 10.14.14
//  Copyright (c) 2014 HalcyonLA. All rights reserved.
//

#import "ChatViewController.h"
#import "ProfileViewController.h"
#import "AppDelegate.h"
#import "PortalDetailViewController.h"

@interface ChatViewController ()

@end

@implementation ChatViewController

- (id)init
{
    self = [super init];
    if (self) {
        
        UIBarButtonItem *backBtn = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"BtnBack"]
                                                                    style:UIBarButtonItemStylePlain
                                                                   target:self
                                                                   action:@selector(backAction)];

        self.navigationItem.leftBarButtonItem = backBtn;
        
        photoView = [[ImageButton alloc] initWithFrame:CGRectMake(0, 0, 34, 34)];
        photoView.layer.cornerRadius = CGRectGetHeight(photoView.frame) / 2;
        photoView.layer.masksToBounds = YES;
        photoView.contentMode = UIViewContentModeScaleAspectFill;
        [photoView addTarget:self action:@selector(profileAction)];
        
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:photoView];
        
        self.view.backgroundColor = [UIColor whiteColor];
        chatData = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = NO;
    User *user = [DataModel getUserWithId:self.userId];
    if (user) {
        self.title = user.fullName;
        [photoView setImageWithURL:[NSURL URLWithString:user.photoSmall]
                  placeholderImage:nil
       usingActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    }
    
    [self loadData:0];
    [self startUpdating:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.navigationController.navigationBarHidden = YES;
    [self startUpdating:NO];
}


- (void)profileAction {
    
    if (!self.userId)
        return;
    
    ProfileViewController *controller = [[ProfileViewController alloc] init];
    controller.userId = self.userId;
    controller.hidesBottomBarWhenPushed = self.userId.integerValue != APP.user.userId.integerValue;
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)backAction {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    return CGRectGetWidth(self.view.frame) * 3/4;
}

- (UIFont *)messageFont
{
    return [UIFont systemFontOfSize:15];
}

- (void)configureMessageCell:(SOMessageCell *)cell forMessageAtIndex:(NSInteger)index
{
    //
    SOMessage *message = chatData[index];
    cell.textView.textColor = message.fromMe ? [UIColor appGreen] : [UIColor blackColor];
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
    if (!self.userId)
        return;
    
    message = [message stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if ([message length] == 0) {
        return;
    }
    
    [[DataManager sharedDataManager] JSONTo:kServerUrl
                             withDictionary:@{@"users_id":self.userId.stringValue,@"message":message}
                                        log:NO
                                   function:@"api_send_message"
                            completionBlock:^(NSDictionary *json, NSError *error) {
                                if (error) {
                                    [SUPPORT showError:error.localizedDescription];
                                } else {
                                    [self checkNewMessages];
                                }
                            }];
}

- (void)loadData:(NSInteger)offset {
    
    if (!self.userId)
        return;
    
    [[DataManager sharedDataManager] JSONTo:kServerUrl
                             withDictionary:@{@"users_id":self.userId.stringValue,@"order":@"ASC",@"limit":@"50",@"offset":@(offset).stringValue}
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
    
    if (!self.userId)
        return;
    
    if (chatData.count > 0) {
        
        NSInteger maxId = 0;
        
        for (SOMessage *bubble in chatData) {
            if (maxId < bubble.message.messageId.integerValue) {
                maxId = bubble.message.messageId.integerValue;
            }
        }
        
        [[DataManager sharedDataManager] JSONTo:kServerUrl
                                 withDictionary:@{@"users_id":self.userId.stringValue,@"order":@"ASC",@"limit":@"100", @"newer_than_id":@(maxId).stringValue}
                                            log:NO
                                       function:@"api_get_messages"
                                completionBlock:^(NSDictionary *json, NSError *error) {
                                    
                                    NSArray *messages = [DATA mappingJSON:json type:MAPPING_MESSAGES];
                                    
                                    if (messages.count > 0) {
                                        for (Message *message in messages) {
                                            
                                            SOMessage *messageItem = [[SOMessage alloc] init];
                                            messageItem.text = message.text.stringByStrippingHTMLItems;
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

@end
