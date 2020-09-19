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

@property (class, nonatomic, readonly) CoreDataEnvirDescriptor* defaultInstance;

@property (nonatomic, copy, nullable) NSString* modelName;
@property (nonatomic, copy) NSString* storeFileName;
@property (nonatomic, copy) NSString* storeDirectory;
@property (nonatomic, copy, nullable) NSArray<NSURL*>* storeURLs;
@property (nonatomic, copy, nullable) NSArray<NSString*>* configurations;

+ (instancetype)instanceWithModelName:(NSString* _Nullable)modelName bundle:(NSBundle* _Nullable)bundle storeFileName:(NSString* _Nullable)fileName storedUnderDirectory:(NSString* _Nullable)directory;

//- (instancetype) NS_DESIGNATED_INITIALIZER init;

- (instancetype) NS_DESIGNATED_INITIALIZER initWithModelName:(NSString* _Nullable)modelName bundle:(NSBundle* _Nullable)bundle storeFileName:(NSString* _Nullable)fileName storedUnderDirectory:(NSString* _Nullable)directory;

- (CoreDataEnvir*)mainInstance;
- (CoreDataEnvir*)backgroundInstance;
- (CoreDataEnvir*)instance;

@end

NS_ASSUME_NONNULL_END
