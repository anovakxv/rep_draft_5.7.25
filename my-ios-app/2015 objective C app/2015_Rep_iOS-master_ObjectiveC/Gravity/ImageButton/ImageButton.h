//
//  ImageButton.h
//  LuckyDay
//
//  Created by Vlad Getman on 17.09.14.
//  Copyright (c) 2014 halcyoninnovation. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ImageButton : UIImageView {
    id _target;
    SEL _action;
}

- (void)addTarget:(id)target action:(SEL)action;
- (void)removeTarget:(id)target action:(SEL)action;

@end
