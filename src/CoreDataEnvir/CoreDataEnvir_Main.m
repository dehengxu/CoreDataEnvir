//
//  CoreDataEnvir_Main.m
//  CoreDataEnvirSample
//
//  Created by NicholasXu on 15/8/31.
//  Copyright (c) 2015年 Nicholas.Xu. All rights reserved.
//

#import "CoreDataEnvir_Main.h"
#import "CoreDataEnvirDescriptor.h"

@implementation CoreDataEnvir (CDEMain)

+ (CoreDataEnvir *)mainInstance
{
    return [CoreDataEnvirDescriptor.defaultInstance mainInstance];
}

+ (dispatch_queue_t)mainQueue
{
    return [[CoreDataEnvir mainInstance] currentQueue];
}

@end
