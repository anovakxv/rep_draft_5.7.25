//
//  ImageButton.m
//  LuckyDay
//
//  Created by Vlad Getman on 17.09.14.
//  Copyright (c) 2014 halcyoninnovation. All rights reserved.
//

#import "ImageButton.h"

@implementation ImageButton

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.clipsToBounds = YES;
        self.contentMode = UIViewContentModeScaleAspectFill;
    }
    return self;
}

- (void)addTarget:(id)target action:(SEL)action {
    _target = target;
    _action = action;
}

- (void)removeTarget:(id)target action:(SEL)action {
    _target = nil;
    _action = nil;
}

- (void)setImage:(UIImage *)image {
    [super setImage:image];
    self.backgroundColor = [UIColor darkGrayColor];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                   ^{
                       UIImage *highlighted = [image imageByApplyingAlpha:0.6];
                       dispatch_async(dispatch_get_main_queue(), ^{
                           self.highlightedImage = highlighted;
                       });
                   });
    //self.highlightedImage = [image imageByApplyingAlpha:0.6];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.highlighted = YES;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.highlighted = NO;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.highlighted = NO;
    if (_target && _action != nil) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [_target performSelector:_action];
#pragma clang diagnostic pop
    }
}


@end
