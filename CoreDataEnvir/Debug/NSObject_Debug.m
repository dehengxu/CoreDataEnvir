//
//  NSObject_Debug.m
//  CoreDataEnvirSample
//
//  Created by NicholasXu on 15/8/30.
//  Copyright (c) 2015年 Nicholas.Xu. All rights reserved.
//

#import "NSObject_Debug.h"

@implementation NSObject (Debug)

- (NSString *)currentDispatchQueueLabel
{
#if DEBUG
    dispatch_queue_t q = dispatch_get_current_queue();
    return [NSString stringWithCString:dispatch_queue_get_label(q) encoding:NSUTF8StringEncoding];
#else
    return nil;
#endif
}

@end
