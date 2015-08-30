//
//  CoreDataEnvir_Background.m
//  CoreDataEnvirSample
//
//  Created by NicholasXu on 15/8/30.
//  Copyright (c) 2015年 Nicholas.Xu. All rights reserved.
//

#import "CoreDataEnvir_Background.h"
#import "CoreDataEnvir_Private.h"

@implementation CoreDataEnvir (background)

+ (CoreDataEnvir *)backgroundInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!_backgroundInstance) {
            _backgroundInstance = [[CoreDataEnvir createInstance] retain];
        }
    });
    return _backgroundInstance;
}

+ (dispatch_queue_t)backgroundQueue
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!_backgroundQueue) {
            _backgroundQueue = dispatch_queue_create("me.deheng.coredataenvir.background", NULL);
        }
    });
    return _backgroundQueue;
}


@end
