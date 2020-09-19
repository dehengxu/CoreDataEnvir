//
//  CoreDataEnvir_Background.h
//  CoreDataEnvirSample
//
//  Created by NicholasXu on 15/8/30.
//  Copyright (c) 2015年 Nicholas.Xu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreDataEnvir/CoreDataEnvir.h>

NS_ASSUME_NONNULL_BEGIN

@interface CoreDataEnvir (CDEBackground)

+ (CoreDataEnvir *)backgroundInstance;

+ (dispatch_queue_t)backgroundQueue;

@end

NS_ASSUME_NONNULL_END
