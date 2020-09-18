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
#if __has_include("NSManagedObject_Debug.h")
#import "NSManagedObject_Debug.h"
#import "NSObject_Debug.h"
#endif
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

NSString* CDE_ERROR_DOMAIN = @"com.dehengxu.CoreDataEnvir";

static NSString *_default_model_file_name = nil;
static NSString *_default_model_file_path = nil;
static NSString *_default_db_file_name = nil;
static NSString *_default_data_file_root_path = nil;

static BOOL _default_is_share_persistence = YES;

//static NSPersistentStoreCoordinator * __sharedStoreCoordinator = nil;

dispatch_semaphore_t _sem = NULL;
dispatch_semaphore_t _sem_main = NULL;

#pragma mark - CoreDataEnvir implementation

@interface CoreDataEnvir ()
@property (nonatomic, strong) NSManagedObjectModel    *model;
@property (nonatomic, strong) NSManagedObjectContext *context;
@property (nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@end

@implementation CoreDataEnvir

+ (void)initialize
{
    _default_data_file_root_path = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] copy];
    _default_db_file_name = @"db.sqlite";
    _default_model_file_name = @"Model";
    _sem = dispatch_semaphore_create(1l);
    _sem_main = dispatch_semaphore_create(1l);
}

+ (void)registerDefaultModelFileName:(NSString *)name
{
	NSString *momdPath = [[NSBundle mainBundle] pathForResource:name ofType:@"momd"];
	if (!momdPath.length) {
		NSString* reason = [NSString stringWithFormat:@"Model file %@.momd not found", name];
		NSException *exce = [NSException exceptionWithName:[NSString stringWithFormat:@"CoreDataEnvir exception %d", CDEErrorModelFileNotFound] reason:reason userInfo:@{@"error": [NSError errorWithDomain:CDE_ERROR_DOMAIN code:CDEErrorModelFileNotFound userInfo:nil]}];
		[exce raise];
		return;
	}

    _default_model_file_name = [name copy];
}

+ (void)registerModelFilePath:(NSString *)filePath {
	if (!filePath.length) return;
	_default_model_file_path = [filePath copy];
}

+ (NSString *)modelFilePath {
	return _default_model_file_path;
}

+ (void)registerDefaultDataFileName:(NSString *)name
{
    _default_db_file_name = [name copy];
}

+ (void)registerDefaultDataFileRootPath:(NSString *)path
{
    _default_data_file_root_path = [path copy];
}

+ (void)registerRescureDelegate:(id<CoreDataRescureDelegate>)delegate
{
    _rescureDelegate = delegate;
}


+ (NSString *)defaultModelFileName
{
    return _default_model_file_name;
}

+ (NSString *)defaultDatabaseFileName
{
    return _default_db_file_name;
}

+ (NSString *)dataRootPath
{
    //NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    //return path;
    return _default_data_file_root_path;
}

#pragma mark - instance handle

+ (CoreDataEnvir *)instance
{
    
    dispatch_semaphore_wait(_sem_main, ~0ull);

    CoreDataEnvir *a_new_db = nil;
        if ([[NSThread currentThread] isMainThread]) {
#if DEBUG && CORE_DATA_ENVIR_SHOW_LOG
            NSLog(@"CoreDataEnvir on main thread!");
#endif
            a_new_db = [self mainInstance];
        }else {
#if DEBUG && CORE_DATA_ENVIR_SHOW_LOG
            NSLog(@"CoreDataEnvir on other thread!");
#endif
            a_new_db = [self createInstance];
            
            if (a_new_db && ![a_new_db currentQueue]) {
                a_new_db->_currentQueue = dispatch_queue_create([[NSString stringWithFormat:@"%@-%d", [NSString stringWithUTF8String:"com.dehengxu.coredataenvir.background"], _create_counter] UTF8String], NULL);

            }
        }
    dispatch_semaphore_signal(_sem_main);

	return a_new_db;
}

+ (CoreDataEnvir *)createInstance
{
    CoreDataEnvir *cde = [self createInstanceWithDatabaseFileName:nil modelFileName:nil];
    return cde;
}

+ (CoreDataEnvir *)createInstanceShareingPersistence:(BOOL)isSharePersistence
{
    CoreDataEnvir *cde = [[self alloc] initWithDatabaseFileName:nil modelFileName:nil sharingPersistence:isSharePersistence];
    return cde;
}

+ (CoreDataEnvir *)createInstanceWithDatabaseFileName:(NSString *)databaseFileName modelFileName:(NSString *)modelFileName
{
    id cde = nil;
    cde = [[self alloc] initWithDatabaseFileName:databaseFileName modelFileName:modelFileName];
#if DEBGU && CORE_DATA_ENVIR_SHOW_LOG
    NSLog(@"\n\n------\ncreate counter :%d\n\n------", _create_counter);
#endif
    return cde;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _create_counter ++;
    }
    return self;
}

- (id)initWithDatabaseFileName:(NSString *)databaseFileName modelFileName:(NSString *)modelFileName
{
    return [self initWithDatabaseFileName:databaseFileName modelFileName:modelFileName sharingPersistence:_default_is_share_persistence];
}

- (id)initWithDatabaseFileName:(NSString *)databaseFileName modelFileName:(NSString *)modelFileName sharingPersistence:(BOOL)isSharePersistence
{
    self = [self init];
    
    if (self) {
        _sharePersistence = isSharePersistence;
        __recursiveLock = [[NSRecursiveLock alloc] init];
        
        if (databaseFileName) {
            [self registerDatabaseFileName:databaseFileName];
        }else {
            [self registerDatabaseFileName:_default_db_file_name];
        }
        
        if (modelFileName) {
            [self registerModelFileName:modelFileName];
        }else {
            [self registerModelFileName:_default_model_file_name];
        }
        
        [self registerDataFileRootPath:_default_data_file_root_path];
        
        @try {
            [self _initCoreDataEnvirWithPath:[self dataRootPath] andFileName:[self databaseFileName]];
        }
        @catch (NSException *exception) {
            NSError *err = [[exception userInfo] valueForKey:@"error"];
            NSLog(@"err %@, %s %d", [err description], __FILE__, __LINE__);
            return nil;
        }
        @finally {
            
        }
        
        //Create buildin background work queue
        if (!_currentQueue) {
            _currentQueue = dispatch_queue_create([[NSString stringWithFormat:@"%@-%d", [NSString stringWithUTF8String:"com.dehengxu.coredataenvir.background"], _create_counter] UTF8String], NULL);
        }

    }
    return self;
}

//- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
//{
//    if (self.sharePersistence) {
//        return __sharedStoreCoordinator;
//    }else {
//        return _persistentStoreCoordinator;
//    }
//}
//
//- (void)setPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)storeCoordinator
//{
//    if (_sharePersistence) {
//        if (__sharedStoreCoordinator != storeCoordinator) {
//            __sharedStoreCoordinator = storeCoordinator;
//        }
//    }else {
//        if (_persistentStoreCoordinator != storeCoordinator) {
//            _persistentStoreCoordinator = storeCoordinator;
//        }
//    }
//}

- (NSManagedObjectContext *)context
{
    if (nil == _context) {
        _context = [[NSManagedObjectContext alloc] init];
    }
    return _context;
}

#pragma mark - Synchronous method

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
    //[_context reset];
    
    //[__recursiveLock release];
    //[_context release];

}

#pragma mark - NSFetchedResultsControllerDelegate

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
                NSLog(@"%s, error:%@", __FUNCTION__, error);
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

#pragma mark - Deleting

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
    if (object && object.isFault) {
        return [self dataItemWithID:object.objectID];
    }
    return object;
}

- (BOOL)deleteDataItem:(NSManagedObject *)aItem
{
    if (!aItem) {
        return NO;
    }
    
    NSManagedObject *getObject = aItem;
    if (aItem.isFault) {
        getObject = [self dataItemWithID:aItem.objectID];
    }
#if DEBUG && CORE_DATA_ENVIR_SHOW_LOG
    NSLog(@"%s  objectID :%@; getObject :%@;", __FUNCTION__, aItem.objectID, getObject);
#endif
    
    if (getObject) {
        @try {
            [self.context deleteObject:getObject];
        }
        @catch (NSException *exception) {
            NSLog(@"exce :%@", [exception description]);
        }
        @finally {
            
        }
    }
#if DEBUG && CORE_DATA_ENVIR_SHOW_LOG
    NSLog(@" delete finished!");
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

- (dispatch_queue_t)currentQueue
{
    return _currentQueue;
}

- (void)asyncInBlock:(void (^)(CoreDataEnvir *))CoreDataBlock
{
    dispatch_async([self currentQueue], ^{
        CoreDataBlock(self);
        [self saveDataBase];
    });
}

- (void)syncInBlock:(void (^)(CoreDataEnvir *)) CoreDataBlock
{
    if ([NSThread isMainThread] && self.currentQueue == dispatch_get_main_queue()) {
        CoreDataBlock(self);
        [self saveDataBase];
    }else {
        dispatch_sync([self currentQueue], ^{
            CoreDataBlock(self);
            [self saveDataBase];
        });
    }
}

+ (void)asyncMainInBlock:(void (^)(CoreDataEnvir *))CoreDataBlock
{
    [[self mainInstance] asyncInBlock:CoreDataBlock];
}

+ (void)asyncBackgroundInBlock:(void (^)(CoreDataEnvir *))CoreDataBlock
{
    [[self backgroundInstance] asyncInBlock:CoreDataBlock];
}

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
    [self syncInBlock:config];
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
    [self.persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:fileURL options:self.persistentOptions error:&error];
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
