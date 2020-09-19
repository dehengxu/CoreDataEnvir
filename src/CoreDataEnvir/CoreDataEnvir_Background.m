//
//  CoreDataEnvir_Background.m
//  CoreDataEnvirSample
//
//  Created by NicholasXu on 15/8/30.
//  Copyright (c) 2015年 Nicholas.Xu. All rights reserved.
//

#import "CoreDataEnvir_Background.h"
#import "CoreDataEnvirDescriptor.h"

@implementation CoreDataEnvir (CDEBackground)

+ (CoreDataEnvir *)backgroundInstance
{
    return [CoreDataEnvirDescriptor.defaultInstance backgroundInstance];
}

+ (dispatch_queue_t)backgroundQueue
{
    return [[CoreDataEnvir backgroundInstance] currentQueue];
}

@end
