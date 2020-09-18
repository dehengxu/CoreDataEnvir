//
//  NSObject_Debug.h
//  CoreDataEnvirSample
//
//  Created by NicholasXu on 15/8/30.
//  Copyright (c) 2015年 Nicholas.Xu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CoreDataEnvir.h"
#import "CoreDataEnvir_Background.h"

@interface NSObject (CDEDebug)

/**
 Get current dispatch queue label string.
 */
- (NSString *)currentDispatchQueueLabel;

@end
