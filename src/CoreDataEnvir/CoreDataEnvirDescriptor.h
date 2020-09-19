//
//  CoreDataEnvirDescriptor.h
//  CoreDataEnvirSample
//
//  Created by Deheng Xu on 2020/9/19.
//  Copyright © 2020 Nicholas.Xu. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CoreDataEnvir;

@interface CoreDataEnvirDescriptor : NSObject

@property (nonatomic, copy, nullable) NSString* modelName;
@property (nonatomic, copy) NSString* storeFileName;
@property (nonatomic, copy) NSString* storeDirectory;

+ (instancetype)defaultInstance;
+ (instancetype)instanceWithModelName:(NSString*)modelName bundle:(NSBundle*)bundle storeFileName:(NSString*)fileName storedUnderDirectory:(NSString*)directory;

- (CoreDataEnvir*)mainInstance;
- (CoreDataEnvir*)backgroundInstance;
- (CoreDataEnvir*)instance;

@end

NS_ASSUME_NONNULL_END
