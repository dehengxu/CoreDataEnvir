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

NSString* const CDE_DOMAIN = @"com.dehengxu.CoreDataEnvir";

NSString* const kDEFAULT_CONFIGURATION_NAME = @"PF_DEFAULT_CONFIGURATION_NAME";

static NSString *_default_model_name = nil;
static NSString *_default_model_dir = nil;
static NSString *_default_db_dir = nil;
static NSString *_default_db_file_name = nil;
static dispatch_semaphore_t _sem_main = NULL;

#pragma mark - CoreDataEnvir implementation

@interface CoreDataEnvir ()
#pragma mark - rewrite property

/// Current work queue
//@property (nonatomic, strong) dispatch_queue_t currentQueue;

/**
 A model object.
 */
@property (nonatomic, strong) NSManagedObjectModel *model;

/**
 A context object.
 */
@property (nonatomic, strong) NSManagedObjectContext *context;

@property (nonatomic, strong) NSMutableDictionary* persistentStoreCacheForName;

@end

@implementation CoreDataEnvir

+ (id<CoreDataRescureDelegate>)rescureDelegate {
	return _rescureDelegate;
}

+ (void)setRescureDelegate:(id<CoreDataRescureDelegate>)rescureDelegate {
	_rescureDelegate = rescureDelegate;
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
		_persistentStoreCacheForName = @{}.mutableCopy;
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
		NSLog(@"Context no changed.");
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

- (BOOL)save {
	return [self saveDataBase];
}

- (void)undo {
	if (self.context) {
		[self.context undo];
	}
}

- (void)redo {
	if (self.context) {
		[self.context redo];
	}
}

- (BOOL)saveForConfiguration:(NSString *)name {
	return NO;
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
    if (@available(iOS 9.0, *)) {
        NSMutableArray* ids = [NSMutableArray arrayWithCapacity:16];
        for (NSManagedObject *item in aItemSet) {
            [ids addObject:item.objectID];
        }
        return [self deleteDataIDs:ids];
    }else {
        NSInteger c = 0;
        for (NSManagedObject *obj in aItemSet) {
            c += (int)[self deleteDataItem:obj];
        }
        return c == aItemSet.count;
    }
    return YES;
}

- (BOOL)deleteDataItems:(NSArray *)items
{
    if (@available(iOS 9.0, *)) {
        NSMutableArray* ids = [NSMutableArray arrayWithCapacity:16];
        for (NSManagedObject *item in items) {
            [ids addObject:item.objectID];
        }
        return [self deleteDataIDs:ids];
    } else {
        NSInteger c = 0;
        for (NSManagedObject *obj in items) {
            c += (int)[self deleteDataItem:obj];
        }
        return c == items.count;
    }
    
    return YES;
}


- (BOOL)deleteDataIDs:(NSArray *)IDs API_AVAILABLE(macosx(10.11), ios(9.0)) {
    NSBatchDeleteRequest *batchDelete = [[NSBatchDeleteRequest alloc] initWithObjectIDs:IDs];
    NSError *err = nil;
    [self.context executeRequest:batchDelete error:&err];
    if (err) {
        return NO;
    }
    return YES;
}

- (BOOL)deleteTable:(Class)aClass where:(NSPredicate *)predicate NS_AVAILABLE_IOS(9.0) {
	if (![aClass isSubclassOfClass:NSManagedObject.class]) {
		return NO;
	}
	NSFetchRequest *fr = [[NSFetchRequest alloc] initWithEntityName:NSStringFromClass(aClass)];
	fr.predicate = predicate;
	NSBatchDeleteRequest* deleteFr = [[NSBatchDeleteRequest alloc] initWithFetchRequest:fr];
	NSError* err;
	[self.context executeRequest:deleteFr error:&err];
	if (err) {
		return NO;
	}
	return YES;
}

- (BOOL)insertDataIntoEntity:(NSEntityDescription *)entity withItems:(NSArray<NSDictionary<NSString*, id> *> *)items API_AVAILABLE(macosx(10.15),ios(13.0),tvos(13.0),watchos(6.0)) {
    NSBatchInsertRequest *batchInsert = [[NSBatchInsertRequest alloc] initWithEntity:entity objects:items];
    NSError *err = nil;
    [self.context executeRequest:batchInsert error:&err];
    if (err) {
        return NO;
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
	self.context.undoManager = [[NSUndoManager alloc] init];
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

	if (!_persistentStoreCoordinator) {
		self.persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.model];
	}
    if (!self.persistentStoreCoordinator) {
        NSAssert(false, @"Create persistentStoreCoordinator failed");
        return nil;
    }
	[self.context setPersistentStoreCoordinator:self.persistentStoreCoordinator];

	[self registerObserving];

	if (![self setupPersistentStoreWithURL:fileURL forConfiguration:nil]) {
		return nil;
	}
    
    return self;
}

- (instancetype)setupPersistentStoreWithURL:(NSURL *)fileURL forConfiguration:(NSString *_Nullable)name {

	NSError* error = nil;
	[self.persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:name URL:fileURL options:[self defaultPersistentOptions] error:&error];
	if (error) {
		NSAssert(error, @"Add persistent store failed: %@", error);
		return nil;
	}
	NSLog(@"Add persistent store %@ to %@", name, fileURL);

    return self;
}

- (NSPersistentStore *)persistentStoreForURL:(NSURL *)fileURL {
    return [_persistentStoreCoordinator persistentStoreForURL:fileURL];
}

- (NSPersistentStore *)persistentStoreForConfiguration:(NSString *)name {
	id store = _persistentStoreCacheForName[name];
	if (store) { return store; }
    store = [_persistentStoreCoordinator persistentStoreForConfiguration:name];
	_persistentStoreCacheForName[name] = store; // over write cache
	return store;
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
