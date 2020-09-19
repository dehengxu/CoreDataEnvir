//
//  CoreDataEnvirDescriptor.m
//  CoreDataEnvirSample
//
//  Created by Deheng Xu on 2020/9/19.
//  Copyright © 2020 Nicholas.Xu. All rights reserved.
//

#import "CoreDataEnvirDescriptor.h"
#import "CoreDataEnvir.h"
#import "CoreDataEnvir_Private.h"

@interface CoreDataEnvirDescriptor ()
@end

@implementation CoreDataEnvirDescriptor

+ (instancetype)defaultInstance {
	static dispatch_once_t onceToken = 0;
	static CoreDataEnvirDescriptor* __shared__ = nil;
	dispatch_once(&onceToken, ^{
		__shared__ = [[super alloc] init];
		__shared__.modelName = nil;//@"Model";
		__shared__.storeFileName = @"db.sqlite";
		__shared__.storeDirectory = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] copy];
		__shared__.bundle = NSBundle.mainBundle;
	});
	return __shared__;
}

+ (instancetype)instanceWithModelName:(NSString *)modelName bundle:(NSBundle *)bundle storeFileName:(NSString *)fileName storedUnderDirectory:(NSString *)directory {
	CoreDataEnvirDescriptor* ins = [[CoreDataEnvirDescriptor alloc] initWithModelName:modelName bundle:bundle storeFileName:fileName storedUnderDirectory:directory];
	return ins;
}

//- (instancetype)init {
//	self = [super init];
//	if (self) {
//		self.modelName = [self.class.defaultInstance modelName];
//		self.storeFileName = self.class.defaultInstance.storeFileName;
//		self.storeDirectory = self.class.defaultInstance.storeDirectory;
//		self.bundle = self.class.defaultInstance.bundle;
//	}
//	return self;
//}

- (instancetype)initWithModelName:(NSString *)modelName bundle:(NSBundle *)bundle storeFileName:(NSString *)fileName storedUnderDirectory:(NSString *)directory {
	self = [super init];
	if (self) {
		self.modelName = modelName ?: [self.class.defaultInstance modelName];
		self.storeFileName = fileName ?: self.class.defaultInstance.storeFileName;
		self.storeDirectory = directory ?: self.class.defaultInstance.storeDirectory;
		self.bundle = bundle ?: self.class.defaultInstance.bundle;
	}
	return self;
}

- (NSURL*)modelURL {
	NSURL* url = [self.bundle URLForResource:self.modelName withExtension:@"momd"];
	return url;
}

- (NSURL*)storeURL {
	NSURL* url = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@", self.storeDirectory, self.storeFileName]];
	return url;
}

- (CoreDataEnvir *)mainInstance {
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_mainInstance = [self generate];
		_mainInstance.currentQueue = dispatch_get_main_queue();
	});

	return _mainInstance;
}

- (CoreDataEnvir *)backgroundInstance {

	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_backgroundInstance = [self instance];
	});

	return _backgroundInstance;
}

- (CoreDataEnvir*)generate {
	CoreDataEnvir* ins = [CoreDataEnvir new];
	[ins setupModelWithURL:[self modelURL]];
	[ins setupDefaultPersistentStoreWithURL:[self storeURL]];
	for (int i = 0; i < self.configurations.count; i++) {
		NSString* name = self.configurations[i];
		NSURL* url = [self storeURL];

		if (self.storeURLs.count) {
			url = [self.storeURLs objectAtIndex:i];
		}
		
		[ins setupPersistentStoreWithURL:url forConfiguration:name];
	}
	return ins;
}

- (CoreDataEnvir *)instance {
	CoreDataEnvir* ins = [self generate];
	if (ins && ![ins currentQueue] ) {
		ins.currentQueue = dispatch_queue_create([[NSString stringWithFormat:@"%@-%ld", [NSString stringWithUTF8String:"com.dehengxu.coredataenvir.background"], _create_counter] UTF8String], NULL);
	}
	return ins;
}

@end
