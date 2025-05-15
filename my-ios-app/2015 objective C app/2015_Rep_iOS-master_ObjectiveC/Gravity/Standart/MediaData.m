//
//  MediaData.m
//  BarWarriors
//
//  Created by Halcyoni on 12/20/12.
//
//

#import "MediaData.h"

@implementation MediaData

@synthesize data = _data;
@synthesize name = _name;
@synthesize contentType = _contentType;


-(id)initWithData: (NSData *)data name:(NSString*)name contentType:(NSString*)contentType{
    self = [super init];
    if(self){
        self.data = data;
        self.name = name;
        self.contentType = contentType;
    }
    return self;
}



@end
