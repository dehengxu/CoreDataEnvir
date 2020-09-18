//
//  CoreDataEnvir_Main.m
//  CoreDataEnvirSample
//
//  Created by NicholasXu on 15/8/31.
//  Copyright (c) 2015年 Nicholas.Xu. All rights reserved.
//

#import "CoreDataEnvir_Main.h"
#import "CoreDataEnvir_Private.h"

@implementation CoreDataEnvir (CDEMain)

+ (CoreDataEnvir *)mainInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (_mainInstance == nil) {
            _mainInstance = [self createInstanceWithDatabaseFileName:nil modelFileName:nil];
        }
        
        if (_mainInstance && _mainInstance->_currentQueue != dispatch_get_main_queue()) {
            _mainInstance->_currentQueue = dispatch_get_main_queue();
        }
    });

    return _mainInstance;
}

+ (dispatch_queue_t)mainQueue
{
    return [[CoreDataEnvir mainInstance] currentQueue];
}

+ (void)saveDataBaseOnMainThread
{
    [[self mainInstance] saveDataBase];
}


@end
