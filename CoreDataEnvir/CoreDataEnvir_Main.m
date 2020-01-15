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
        if (_coreDataEnvir == nil) {
            _coreDataEnvir = [[self createInstanceWithDatabaseFileName:nil modelFileName:nil] retain];
        }
        
        if (_coreDataEnvir && _coreDataEnvir->_currentQueue != dispatch_get_main_queue()) {
            if (_coreDataEnvir->_currentQueue) {
                dispatch_release(_coreDataEnvir->_currentQueue);
                _coreDataEnvir->_currentQueue = 0;
            }
            _coreDataEnvir->_currentQueue = dispatch_get_main_queue();
        }
    });

    return _coreDataEnvir;
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
