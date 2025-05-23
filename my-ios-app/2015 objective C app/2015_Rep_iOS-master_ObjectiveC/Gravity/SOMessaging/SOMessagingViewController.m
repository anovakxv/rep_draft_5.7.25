//
//  SOMessagingViewController.m
//  SOMessaging
//
// Created by : arturdev
// Copyright (c) 2014 SocialObjects Software. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
// the Software, and to permit persons to whom the Software is furnished to do so,
// subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE

#import "SOMessagingViewController.h"
#import "SOMessage.h"
#import "SOMessageCell.h"

#import "NSString+Calculation.h"

#import "SOImageBrowserView.h"
#import <MediaPlayer/MediaPlayer.h>

#define kMessageMaxWidth [[UIScreen mainScreen] bounds].size.width * 0.75


@interface SOMessagingViewController () <UITableViewDelegate, SOMessageCellDelegate>
{

}

@property (strong, nonatomic) UIImage *balloonSendImage;
@property (strong, nonatomic) UIImage *balloonReceiveImage;

@property (strong, nonatomic) UIView *tableViewHeaderView;

@property (strong, nonatomic) NSMutableArray *conversation;


@property (strong, nonatomic) SOImageBrowserView *imageBrowser;
@property (strong, nonatomic) MPMoviePlayerViewController *moviePlayerController;

@end

@implementation SOMessagingViewController {
    dispatch_once_t onceToken;
}

- (void)setup
{
    CGRect frame = self.view.bounds;
    self.tableView = [[UITableView alloc] initWithFrame:frame style:UITableViewStyleGrouped];
    self.tableView.backgroundColor = [UIColor whiteColor];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    self.tableViewHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 10)];
    self.tableViewHeaderView.backgroundColor = [UIColor clearColor];
    self.tableView.tableHeaderView = self.tableViewHeaderView;
    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    
    [self.view addSubview:self.tableView];
    
    self.inputView = [[SOMessageInputView alloc] init];
    self.inputView.delegate = self;
    self.inputView.tableView = self.tableView;
    [self.view addSubview:self.inputView];
    [self.inputView adjustPosition];
}

#pragma mark - View lifecicle
- (void)viewDidLoad
{
    [super viewDidLoad];
 
    [self setup];
    
    self.balloonSendImage    = [self balloonImageForSending];
    self.balloonReceiveImage = [self balloonImageForReceiving];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.inputView adjustInputView];
    
    self.conversation = [self grouppedMessages];
    
    [self.tableView reloadData];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    dispatch_once(&onceToken, ^{
        if ([self.conversation count]) {
            NSInteger section = self.conversation.count - 1;
            NSInteger row = [self.conversation[section] count] - 1;
            if (row > 0) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
                [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:NO];
            }
            
        }
    });
}

// This code will work only if this vc hasn't navigation controller
- (BOOL)shouldAutorotate
{
    if (self.inputView.viewIsDragging) {
        return NO;
    }
    return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return self.conversation.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.conversation[section] count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height;
    
    SOMessage *message = self.conversation[indexPath.section][indexPath.row];
    int index = (int)[[self messages] indexOfObject:message];
    height = [self heightForMessageForIndex:index];

    return height;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.01f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if ([self intervalForMessagesGrouping])
        return 40;
    
    return 0.01f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (![self intervalForMessagesGrouping])
        return nil;
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 40)];
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    view.backgroundColor = [UIColor clearColor];
    
    SOMessage *firstMessageInGroup = [self.conversation[section] firstObject];
    NSDate *date = [firstMessageInGroup date];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"eee, dd MMM, h:mm a"];
    formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US"];
    
    NSDateFormatter *timeFormatter = [[NSDateFormatter alloc] init];
    [timeFormatter setDateFormat:@"h:mm a"];
    timeFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US"];
    
    UILabel *label = [[UILabel alloc] init];
    label.text = [formatter stringFromDate:date];
    
    label.textColor = [UIColor colorFromHexString:@"#8e8e93" alpha:1];
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] init];
    [attributedString.mutableString appendString:label.text];
    [attributedString addColor:label.textColor substring:attributedString.string];
    [attributedString addFontWithName:@"HelveticaNeue-Bold" size:11 substring:attributedString.string];
    [attributedString addFontWithName:@"HelveticaNeue" size:11 substring:[timeFormatter stringFromDate:date]];
    
    label.attributedText = attributedString;
    
    [label sizeToFit];
    
    label.center = CGPointMake(view.frame.size.width/2, view.frame.size.height/2);
    label.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    
    [view addSubview:label];
    
    return view;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"sendCell";

    SOMessageCell *cell;

    SOMessage *message = self.conversation[indexPath.section][indexPath.row];
    
    cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[SOMessageCell alloc] initWithStyle:UITableViewCellStyleDefault
                                    reuseIdentifier:cellIdentifier
                                    messageMaxWidth:[self messageMaxWidth]];
        [cell setMediaImageViewSize:[self mediaThumbnailSize]];
        [cell setUserImageViewSize:[self userImageSize]];
    }
    cell.tableView = self.tableView;
    cell.balloonMinHeight = [self balloonMinHeight];
    cell.balloonMinWidth  = [self balloonMinWidth];
    cell.delegate = self;
    cell.messageFont = [self messageFont];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.balloonImage = message.fromMe ? self.balloonSendImage : self.balloonReceiveImage;
    cell.textView.textColor = message.fromMe ? [UIColor whiteColor] : [UIColor blackColor];
    cell.message = message;    
    
    // For user customization
    NSInteger index = [[self messages] indexOfObject:message];
    [self configureMessageCell:cell forMessageAtIndex:index];
    
    [cell adjustCell];
    
    return cell;
}

#pragma mark - SOMessaging datasource

- (NSMutableArray *)messages
{
    return nil;
}

- (CGFloat)heightForMessageForIndex:(NSInteger)index
{
    CGFloat height;
    
    SOMessage *message = [self messages][index];
    
    if (message.type == SOMessageTypeText) {
        CGSize size = [message.text usedSizeForMaxWidth:[self messageMaxWidth] withFont:[self messageFont]];
        if (message.attributes) {
            size = [message.text usedSizeForMaxWidth:[self messageMaxWidth] withAttributes:message.attributes];
        }
        if (message.message.portalId.integerValue > 0) {
            size.height += 100;
        }
        
        if (self.balloonMinWidth) {
            CGFloat messageMinWidth = self.balloonMinWidth - [SOMessageCell messageLeftMargin] - [SOMessageCell messageRightMargin];
            if (size.width <  messageMinWidth) {
                size.width = messageMinWidth;

                CGSize newSize = [message.text usedSizeForMaxWidth:messageMinWidth withFont:[self messageFont]];
                if (message.attributes) {
                    newSize = [message.text usedSizeForMaxWidth:messageMinWidth withAttributes:message.attributes];
                }
                
                size.height = newSize.height;
            }
        }
        
        CGFloat messageMinHeight = self.balloonMinHeight - ([SOMessageCell messageTopMargin] + [SOMessageCell messageBottomMargin]);
        if ([self balloonMinHeight] && size.height < messageMinHeight) {
            size.height = messageMinHeight;
        }
        
        size.height += [SOMessageCell messageTopMargin] + [SOMessageCell messageBottomMargin];
        
        if (!CGSizeEqualToSize([self userImageSize], CGSizeZero)) {
            if (size.height < [self userImageSize].height) {
                size.height = [self userImageSize].height;
            }
        }
        
        height = size.height + kBubbleTopMargin + kBubbleBottomMargin;
        
    } else {
        CGSize size = [self mediaThumbnailSize];
        if (size.height < [self userImageSize].height) {
            size.height = [self userImageSize].height;
        }
        height = size.height + kBubbleTopMargin + kBubbleBottomMargin;
    }
    return height;
}

- (NSTimeInterval)intervalForMessagesGrouping
{
    return 0;
}

- (UIImage *)balloonImageForReceiving
{
    UIImage *bubble = [UIImage imageNamed:@"bubbleReceive.png"];
    UIColor *color = [UIColor colorWithRed:210.0/255.0 green:210.0/255.0 blue:215.0/255.0 alpha:1.0];
    bubble = [self tintImage:bubble withColor:color];
    return [bubble resizableImageWithCapInsets:UIEdgeInsetsMake(17, 27, 21, 17)];
}

- (UIImage *)balloonImageForSending
{
    UIImage *bubble = [UIImage imageNamed:@"bubble.png"];
    UIColor *color = [UIColor blackColor];
    bubble = [self tintImage:bubble withColor:color];
    return [bubble resizableImageWithCapInsets:UIEdgeInsetsMake(17, 21, 16, 27)];
}

- (void)configureMessageCell:(SOMessageCell *)cell forMessageAtIndex:(NSInteger)index
{

}

- (CGFloat)messageMaxWidth
{
    return kMessageMaxWidth;
}

- (CGFloat)balloonMinHeight
{
    return 0;
}

- (CGFloat)balloonMinWidth
{
    return 0;
}

- (UIFont *)messageFont
{
    return [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
}

- (CGSize)mediaThumbnailSize
{
    return CGSizeMake(90, 100);
}

- (CGSize)userImageSize
{
    return CGSizeMake(0, 0);
}

#pragma mark - Public methods
- (void)sendMessage:(SOMessage *)message
{
    message.fromMe = YES;
    NSMutableArray *messages = [self messages];
    NSArray *duplicates = [messages filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"message.messageId == %@", message.message.messageId]];
    if (duplicates.count > 0)
        return;
    
    [messages addObject:message];

    [self refreshMessages];
}

- (void)receiveMessage:(SOMessage *)message
{
    message.fromMe = NO;

    NSMutableArray *messages = [self messages];
    NSArray *duplicates = [messages filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"message.messageId == %@", message.message.messageId]];
    if (duplicates.count > 0)
        return;
    
    [messages addObject:message];

    [self refreshMessages];
}

- (void)refreshMessagesAnimated:(BOOL)animated {
    self.conversation = [self grouppedMessages];
    [self.tableView reloadData];
    
    if ([self.tableView numberOfSections] == 0)
        return;
    
    NSInteger section = [self.tableView numberOfSections] - 1;
    NSInteger row = [self.tableView numberOfRowsInSection:section] - 1;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
    if (row >= 0) {
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:animated];
    }
}

- (void)refreshMessages
{
    [self refreshMessagesAnimated:YES];
}

#pragma mark - Private methods
- (NSMutableArray *)grouppedMessages
{
    NSMutableArray *conversation = [NSMutableArray new];
    
    if (![self intervalForMessagesGrouping]) {
        if ([self messages]) {
            [conversation addObject:[self messages]];
        }
    } else {
        int groupIndex = 0;
        NSMutableArray *allMessages = [self messages];

        for (int i = 0; i < allMessages.count; i++) {
            if (i == 0) {
                NSMutableArray *firstGroup = [NSMutableArray new];
                [firstGroup addObject:allMessages[i]];
                [conversation addObject:firstGroup];
            } else {
                SOMessage *prevMessage    = allMessages[i-1];
                SOMessage *currentMessage = allMessages[i];
                
                NSDate *prevMessageDate    = prevMessage.date;
                NSDate *currentMessageDate = currentMessage.date;
                
                NSTimeInterval interval = [currentMessageDate timeIntervalSinceDate:prevMessageDate];
                if (interval < [self intervalForMessagesGrouping]) {
                    NSMutableArray *group = conversation[groupIndex];
                    [group addObject:currentMessage];
                    
                } else {
                    NSMutableArray *newGroup = [NSMutableArray new];
                    [newGroup addObject:currentMessage];
                    [conversation addObject:newGroup];
                    groupIndex++;
                }
            }
        }
    }
    
    return conversation;
}

#pragma mark - SOMessaging delegate

- (void)messageCell:(SOMessageCell *)cell didTapPortal:(Portal *)portal {
    
}

- (void)messageCell:(SOMessageCell *)cell didTapMedia:(NSData *)media
{
    [self didSelectMedia:media inMessageCell:cell];
}

- (void)didSelectMedia:(NSData *)media inMessageCell:(SOMessageCell *)cell
{
    if (cell.message.type == SOMessageTypePhoto) {
        self.imageBrowser = [[SOImageBrowserView alloc] init];
        
        self.imageBrowser.image = [UIImage imageWithData:cell.message.media];

        self.imageBrowser.startFrame = [cell convertRect:cell.containerView.frame toView:self.view];
        
        [self.imageBrowser show];
    } else if (cell.message.type == SOMessageTypeVideo) {
        
        NSString *appFile = [NSTemporaryDirectory() stringByAppendingPathComponent:@"video.mp4"];
        [cell.message.media writeToFile:appFile atomically:YES];
        

        self.moviePlayerController = [[MPMoviePlayerViewController alloc] initWithContentURL:[NSURL fileURLWithPath:appFile]];
        [self.moviePlayerController.moviePlayer prepareToPlay];
        [self.moviePlayerController.moviePlayer setShouldAutoplay:YES];

        [self presentViewController:self.moviePlayerController animated:YES completion:^{
            [[UIApplication sharedApplication] setStatusBarHidden:YES];
        }];
        [[UIApplication sharedApplication] setStatusBarHidden:NO];
    }
}
#pragma mark - Helper methods
- (UIImage *)tintImage:(UIImage *)image withColor:(UIColor *)color
{
    UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, 0, image.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextSetBlendMode(context, kCGBlendModeNormal);
    CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
    CGContextClipToMask(context, rect, image.CGImage);
    [color setFill];
    CGContextFillRect(context, rect);
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}
@end
