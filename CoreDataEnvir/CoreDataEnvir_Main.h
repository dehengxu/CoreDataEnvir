//
//  CoreDataEnvir_Main.h
//  CoreDataEnvirSample
//
//  Created by NicholasXu on 15/8/31.
//  Copyright (c) 2015年 Nicholas.Xu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CoreDataEnvir.h"

@interface CoreDataEnvir (CDEMain)

/**
 Only returen a single instance runs on main thread.
 */
+ (CoreDataEnvir *)mainInstance;

/**
 Main queue.
 */
+ (dispatch_queue_t)mainQueue;

+ (void)saveDataBaseOnMainThread;

@end
