//
//  MediaData.h
//  BarWarriors
//
//  Created by Halcyoni on 12/20/12.
//
//

#import <Foundation/Foundation.h>



@interface MediaData : NSObject
-(id)initWithData: (NSData *)data name:(NSString*)name contentType:(NSString*)contentType;

@property (nonatomic, strong) NSData *data;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *contentType;

@end
