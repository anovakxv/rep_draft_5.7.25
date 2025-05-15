//
//  ArrayTransformer.m
//  iCollegeTree
//
//  Created by Vlad Getman on 20.06.14.
//  Copyright (c) 2025 Networked Capital Inc. All rights reserved.
//

#import "ArrayTransformer.h"

@implementation ArrayTransformer

+ (Class)transformedValueClass
{
    return [NSArray class];
}

+ (BOOL)allowsReverseTransformation
{
    return YES;
}

- (id)transformedValue:(id)value
{
    return [NSKeyedArchiver archivedDataWithRootObject:value];
}

- (id)reverseTransformedValue:(id)value
{
    return [NSKeyedUnarchiver unarchiveObjectWithData:value];
}


@end
