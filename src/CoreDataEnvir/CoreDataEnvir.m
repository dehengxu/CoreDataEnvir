//
//  CoreDataEnvir.m
//  CoreDataLab
//
//  Created by NicholasXu on 11-5-25.
//  Copyright 2011 NicholasXu. All rights reserved.
//

#import "CoreDataEnvir.h"

#import "CoreDataEnvir_Private.h"
#import "CoreDataEnvir_Main.h"
#import "CoreDataEnvirObserver.h"
#import "CoreDataRescureDelegate.h"
#import "CoreDataEnvirDescriptor.h"

// debug
#if __has_include("NSManagedObject_Debug.h")
#import "NSManagedObject_Debug.h"
#import "NSObject_Debug.h"
#endif

// NSManagedObeject
#import "NSManagedObject_Convenient.h"
#import "NSManagedObject_MainThread.h"
#import "NSManagedObject_Background.h"

/**
 Do not use any lock method to protect thread resources in CoreData under concurrency condition!
 */
#define CONTEXT_LOCK_BEGIN  do {\
BOOL _isLocked = [context tryLock];\
if (_isLocked) {\

#define CONTEXT_LOCK_END    [context unlock];\
break;\
}\
} while(0);

#define LOCK_BEGIN  [recursiveLock lock];
#define LOCK_END    [recursiveLock unlock];

NSString* CDE_DOMAIN = @"com.dehengxu.CoreDataEnvir";

static NSString *_default_model_name = nil;
static NSString *_default_model_dir = nil;
static NSString *_default_db_dir = nil;
static NSString *_default_db_file_name = nil;
static dispatch_semaphore_t _sem_main = NULL;

#pragma mark - CoreDataEnvir implementation

@interface CoreDataEnvir ()
#pragma mark - rewrite property

/// Current work queue
@property (nonatomic, strong) dispatch_queue_t currentQueue;

/**
 A model object.
 */
@property (nonatomic, strong) NSManagedObjectModel *model;

/**
 A context object.
 */
@property (nonatomic, strong) NSManagedObjectContext *context;


@end

@implementation CoreDataEnvir

#pragma mark - Configuration

+ (NSString *)defaultModelName {
	return _default_model_name;
}

/**
 Get data base file name.
 */
+ (NSString *)defaultDatabaseFileName {
	return _default_db_file_name;
}

+ (NSString*)defaultDatabaseDir {
	return _default_db_dir;
}

+ (id<CoreDataRescureDelegate>)rescureDelegate {
	return _rescureDelegate;
}

+ (void)setRescureDelegate:(id<CoreDataRescureDelegate>)rescureDelegate {
	_rescureDelegate = rescureDelegate;
}

- (void)setModelName:(NSString *)modelName {
	if (!modelName.length) {
		_modelName = [_default_model_name copy];
	}
	_modelName = [modelName copy];
}

- (void)setDatabaseFileName:(NSString *)databaseFileName {
	if (!databaseFileName.length) {
		_databaseFileName = [_default_db_file_name copy];
	}
	_modelName = [databaseFileName copy];
}

#pragma mark - Initialization

+ (void)initialize
{
	// Default db dir is document
	_default_db_dir = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] copy];
	_default_db_file_name = @"db.sqlite";
	_default_model_name = @"Model";
    _sem_main = dispatch_semaphore_create(1l);
}

+ (void)registerRescureDelegate:(id<CoreDataRescureDelegate>)delegate
{
	_rescureDelegate = delegate;
}

#pragma mark - instance handle

+ (CoreDataEnvir *)instance
{
    dispatch_semaphore_wait(_sem_main, ~0ull);
    CoreDataEnvir *db = nil;
	if ([[NSThread currentThread] isMainThread]) {
		db = [self mainInstance];
	}else {
		db = [self createInstance];
	}
    dispatch_semaphore_signal(_sem_main);

	return db;
}

+ (CoreDataEnvir *)createInstance
{
	CoreDataEnvir *cde = [CoreDataEnvirDescriptor.defaultInstance instance]; //[[self alloc] initWithDatabaseFileName:nil modelFileName:nil];
    return cde;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _create_counter ++;
		__recursiveLock = [[NSRecursiveLock alloc] init];
    }
    return self;
}

- (void)dealloc {
#if DEBUG && CORE_DATA_ENVIR_SHOW_LOG
	NSLog(@"%@", [self currentDispatchQueueLabel]);
#endif
	_create_counter --;
	NSAssert(_create_counter >=0, @"over dealloc. %ld", _create_counter);
#if DEBGU && CORE_DATA_ENVIR_SHOW_LOG
	NSLog(@"%s\ncreate counter :%d\n\n", __func__, _create_counter);
#endif
	[self unregisterObserving];
}

#pragma mark - Handle data store

- (BOOL)saveDataBase
{
	if (![self.context hasChanges]) {
		return YES;
	}
    __block BOOL bResult = NO;
    #pragma clang push
    #pragma clang diagnostic ignored "-Wdeprecated-declarations"

    void(^doWork)(void) = ^ {
        NSError *error = nil;
        bResult = [self.context save:&error];

        if (!bResult) {
            if (error != nil) {
                NSLog(@"%s, %d, error:%@", __PRETTY_FUNCTION__, __LINE__, error);
            }
            //Do we need rollback?
            //[context rollback];
        }
    };

    if ([[UIDevice currentDevice] systemVersion].floatValue >= 8.0) {
        [self.persistentStoreCoordinator performBlockAndWait:doWork];
    }else {
        [self.persistentStoreCoordinator lock];
        doWork();
        [self.persistentStoreCoordinator unlock];
    }
    #pragma clang pop

#if DEBGU && CORE_DATA_ENVIR_SHOW_LOG
    NSLog(@"%s", __FUNCTION__);
#endif
    return bResult;
}

#pragma mark - Data handling

- (id)dataItemWithID:(NSManagedObjectID *)objectId
{
    if (objectId && self.context) {
        
        NSManagedObject *item = nil;
        
        @try {
            item = [self.context objectWithID:objectId];
        }
        @catch (NSException *exception) {
            NSLog(@"exce :%@", [exception description]);
            item = nil;
        }
        @finally {
            
        }
        
        return item;
    }
    return nil;
}

- (id)updateDataItem:(NSManagedObject *)object
{
    if (object.isFault) {
        return [self dataItemWithID:object.objectID];
    }
    return object;
}

- (BOOL)deleteDataItem:(NSManagedObject *)object
{
    if (!object) {
        return NO;
    }
    
    NSManagedObject *getObject = object;
    if (object.isFault) {
        getObject = [self dataItemWithID:object.objectID];
    }
#if DEBUG && CORE_DATA_ENVIR_SHOW_LOG
    NSLog(@"%s  objectID :%@; getObject :%@;", __FUNCTION__, aItem.objectID, getObject);
#endif
    
    if (getObject) {
        @try {
            [self.context deleteObject:getObject];
        }
        @catch (NSException *exception) {
            NSLog(@"Deleting abort cause exce :%@", [exception description]);
			return NO;
        }
        @finally {
            
        }
    }
#if DEBUG && CORE_DATA_ENVIR_SHOW_LOG
    NSLog(@"delete finished!");
#endif
    
    return YES;
}

- (BOOL) deleteDataItemSet:(NSSet *)aItemSet
{
    for (NSManagedObject *obj in aItemSet) {
        [self deleteDataItem:obj];
    }
    
    return YES;
}

- (BOOL)deleteDataItems:(NSArray *)items
{
    for (NSManagedObject *obj in items) {
        [self deleteDataItem:obj];
    }
    
    return YES;
}

#pragma mark - Obseving context

- (void)registerObserving
{
#if DEBUG
	NSLog(@"%s", __FUNCTION__);
#endif
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mergeChanges:) name:NSManagedObjectContextDidSaveNotification object:nil];
}

- (void)unregisterObserving
{
#if DEBUG
	NSLog(@"%s", __FUNCTION__);
#endif
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextDidSaveNotification object:nil];
}

#pragma mark - Work queue relevant

- (void)asyncWithBlock:(void (^)(CoreDataEnvir *))CoreDataBlock
{
    dispatch_async([self currentQueue], ^{
        CoreDataBlock(self);
    });
}

- (void)syncWithBlock:(void (^)(CoreDataEnvir *)) CoreDataBlock
{
    if ([NSThread isMainThread] && self.currentQueue == dispatch_get_main_queue()) {
        CoreDataBlock(self);
    }else {
        dispatch_sync([self currentQueue], ^{
            CoreDataBlock(self);
        });
    }
}

//+ (void)asyncMainInBlock:(void (^)(CoreDataEnvir *))CoreDataBlock
//{
//    [[self mainInstance] asyncInBlock:CoreDataBlock];
//}
//
//+ (void)asyncBackgroundInBlock:(void (^)(CoreDataEnvir *))CoreDataBlock
//{
//    [[self backgroundInstance] asyncInBlock:CoreDataBlock];
//}

#pragma mark - NewAPIs

+ (instancetype)create {
    CoreDataEnvir* db = [CoreDataEnvir new];
    db.currentQueue = dispatch_queue_create([[NSString stringWithFormat:@"%@-%ld", [NSString stringWithUTF8String:"com.dehengxu.coredataenvir.background"], _create_counter] UTF8String], NULL);
    return db;
}

+ (instancetype)createMain {
    CoreDataEnvir* db = [CoreDataEnvir new];
    db.currentQueue = dispatch_get_main_queue();
    return db;
}


#pragma mark - setup CoreData requires

- (instancetype)setupWithBlock:(void (^)(CoreDataEnvir * _Nonnull))config {
    [self syncWithBlock:config];
    return self;
}

- (instancetype)setupModelWithURL:(NSURL *)fileURL {
    NSAssert(fileURL, @"fileURL must be non-null.");
    NSAssert(fileURL.isFileURL, @"fileURL must begin with file://");
    if (!fileURL || !fileURL.isFileURL) {
        return nil;
    }
    
    NSLog(@"model %d, url: %@", fileURL.isFileURL, fileURL.path);
    if (![NSFileManager.defaultManager fileExistsAtPath:fileURL.path isDirectory:NULL]) {
        NSAssert(false, @"fileURL does not exist: %@", fileURL.absoluteString);
        return nil;
    }
    
    self.model = [[NSManagedObjectModel alloc] initWithContentsOfURL:fileURL];
	if (!_context) {
		_context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
	}
	[self.context setRetainsRegisteredObjects:NO];
	[self.context setPropagatesDeletesAtEndOfEvent:NO];
	[self.context setMergePolicy:NSOverwriteMergePolicy];

    return self;
}

- (instancetype)setupDefaultPersistentStoreWithURL:(NSURL *)fileURL {
    if (!self.model) {
        NSAssert(false, @"Should initialize model prior");
        return nil;
    }
    
    self.persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.model];
    if (!self.persistentStoreCoordinator) {
        NSAssert(false, @"Create persistentStoreCoordinator failed");
        return nil;
    }
    
    NSError* error = nil;
    [self.persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:fileURL options:[self defaultPersistentOptions] error:&error];
    if (error) {
        NSAssert(error, @"Add persistent store failed: %@", error);
        return nil;
    }
    
    [self.context setPersistentStoreCoordinator:self.persistentStoreCoordinator];
    
    [self registerObserving];
    return self;
}

- (instancetype)setupPersistentStoreWithURL:(NSURL *)fileURL forConfiguration:(nonnull NSString *)name {
    return self;
}

- (NSPersistentStore *)persistentStoreForURL:(NSURL *)fileURL {
    return [self.persistentStoreCoordinator persistentStoreForURL:fileURL];
}

- (NSPersistentStore *)persistentStoreForConfiguration:(NSString *)name {
    return [self.persistentStoreCoordinator persistentStoreForConfiguration:name];
}


@end

#pragma mark - NSPersistentStoreCoordinator

@implementation NSPersistentStoreCoordinator (CoreDataEnvir)

- (NSPersistentStore *)persistentStoreForConfiguration:(NSString *)name {
    for (NSPersistentStore* persi in self.persistentStores) {
        if ([persi.configurationName isEqualToString:name]) {
            return persi;
        }
    }
    return nil;
}

@end
