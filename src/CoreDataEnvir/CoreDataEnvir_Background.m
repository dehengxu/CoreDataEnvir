//
//  CoreDataEnvir_Background.m
//  CoreDataEnvirSample
//
//  Created by NicholasXu on 15/8/30.
//  Copyright (c) 2015年 Nicholas.Xu. All rights reserved.
//

#import "CoreDataEnvir_Background.h"
#import "CoreDataEnvir_Private.h"

@implementation CoreDataEnvir (CDEBackground)

+ (CoreDataEnvir *)backgroundInstance
{
    static dispatch_once_t onceTokenInstance;
    dispatch_once(&onceTokenInstance, ^{
        if (!_backgroundInstance) {
            _backgroundInstance = [CoreDataEnvir createInstance];
        }
        
        if (_backgroundInstance && ![_backgroundInstance currentQueue] ) {
            _backgroundInstance.currentQueue = dispatch_queue_create([[NSString stringWithFormat:@"%@-%ld", [NSString stringWithUTF8String:"com.dehengxu.coredataenvir.background"], _create_counter] UTF8String], NULL);
        }

    });
    return _backgroundInstance;
}

+ (dispatch_queue_t)backgroundQueue
{
    return [[CoreDataEnvir backgroundInstance] currentQueue];
}

@end
