//
//  CoreDataEnvir_Main.m
//  CoreDataEnvirSample
//
//  Created by NicholasXu on 15/8/31.
//  Copyright (c) 2015年 Nicholas.Xu. All rights reserved.
//

#import "CoreDataEnvir_Main.h"
#import "CoreDataEnvir_Private.h"

@implementation CoreDataEnvir (Main)

+ (CoreDataEnvir *)mainInstance
{
    if (_coreDataEnvir == nil) {
        _coreDataEnvir = [[self createInstanceWithDatabaseFileName:nil modelFileName:nil] retain];
    }
    
    if (_coreDataEnvir && ![_coreDataEnvir currentQueue]) {
        _coreDataEnvir->_currentQueue = dispatch_get_main_queue();
    }
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
