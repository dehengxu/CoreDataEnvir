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

#import "NSManagedObject_Debug.h"
#import "NSManagedObject_Convient.h"
#import "NSManagedObject_MainThread.h"
#import "NSManagedObject_Background.h"
#import "NSObject_Debug.h"


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


static NSString *_default_model_file_name = nil;
static NSString *_default_db_file_name = nil;
static NSString *_default_data_file_root_path = nil;

static BOOL _default_is_share_persistence = YES;

static NSPersistentStoreCoordinator * __sharedStoreCoordinator = nil;

dispatch_semaphore_t _sem = NULL;
dispatch_semaphore_t _sem_main = NULL;

#pragma mark - CoreDataEnvir implementation

@implementation CoreDataEnvir

@synthesize //model,
context = _context,

storeCoordinator = _storeCoordinator,

fetchedResultsCtrl;

+ (void)initialize
{
    _default_data_file_root_path = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] copy];
    _default_db_file_name = @"db.sqlite";
    _default_model_file_name = @"Model";
    _sem = dispatch_semaphore_create(1l);
    _sem_main = dispatch_semaphore_create(1l);
}

+ (void)registDefaultModelFileName:(NSString *)name
{
    if (_default_model_file_name) {
        [_default_model_file_name release];
        _default_model_file_name = nil;
    }
    _default_model_file_name = [name copy];
}

+ (void)registDefaultDataFileName:(NSString *)name
{
    if (_default_db_file_name) {
        [_default_db_file_name release];
        _default_db_file_name = nil;
    }
    _default_db_file_name = [name copy];
}

+ (void)registDefaultDataFileRootPath:(NSString *)path
{
    if (_default_data_file_root_path) {
        [_default_data_file_root_path release];
        _default_data_file_root_path = nil;
    }
    _default_data_file_root_path = [path copy];
}

+ (void)registRescureDelegate:(id<CoreDataRescureDelegate>)delegate
{
    _rescureDelegate = delegate;
}


+ (NSString *)defaultModelFileName
{
    return [[_default_model_file_name copy] autorelease];
}

+ (NSString *)defaultDatabaseFileName
{
    return [[_default_db_file_name copy] autorelease];
}

+ (NSString *)dataRootPath
{
    //NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    //return path;
    return [[_default_data_file_root_path copy] autorelease];
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
    return [cde autorelease];
}

+ (CoreDataEnvir *)createInstanceWithDatabaseFileName:(NSString *)databaseFileName modelFileName:(NSString *)modelFileName
{
    id cde = nil;
    cde = [[self alloc] initWithDatabaseFileName:databaseFileName modelFileName:modelFileName];
    NSLog(@"\n\n------\ncreate counter :%d\n\n------", _create_counter);
    return [cde autorelease];
}

- (id)init
{
    return [self initWithDatabaseFileName:nil modelFileName:nil];
}

- (id)initWithDatabaseFileName:(NSString *)databaseFileName modelFileName:(NSString *)modelFileName
{
    return [self initWithDatabaseFileName:databaseFileName modelFileName:modelFileName sharingPersistence:_default_is_share_persistence];
}

- (id)initWithDatabaseFileName:(NSString *)databaseFileName modelFileName:(NSString *)modelFileName sharingPersistence:(BOOL)isSharePersistence
{
    self = [super init];
    
    if (self) {
        _sharePersistence = isSharePersistence;
        __recursiveLock = [[NSRecursiveLock alloc] init];
        
        if (databaseFileName) {
            [self registDatabaseFileName:databaseFileName];
        }else {
            [self registDatabaseFileName:_default_db_file_name];
        }
        
        if (modelFileName) {
            [self registModelFileName:modelFileName];
        }else {
            [self registModelFileName:_default_model_file_name];
        }
        
        [self registDataFileRootPath:_default_data_file_root_path];
        
        @try {
            [self _initCoreDataEnvirWithPath:[self dataRootPath] andFileName:[self databaseFileName]];
        }
        @catch (NSException *exception) {
            NSError *err = [[exception userInfo] valueForKey:@"error"];
            NSLog(@"err %@, %s %d", [err description], __FILE__, __LINE__);
            [self release];
            return nil;
        }
        @finally {
            
        }
        
        //[self.class _renameDatabaseFile];

        //Create default work queue
        if (!_currentQueue) {
            _currentQueue = dispatch_queue_create([[NSString stringWithFormat:@"%@-%d", [NSString stringWithUTF8String:"com.dehengxu.coredataenvir.background"], _create_counter] UTF8String], NULL);
        }


        _create_counter ++;

    }
    return self;
}

- (NSPersistentStoreCoordinator *)storeCoordinator
{
    if (self.sharePersistence) {
        return __sharedStoreCoordinator;
    }else {
        return _storeCoordinator;
    }
}

- (void)setStoreCoordinator:(NSPersistentStoreCoordinator *)storeCoordinator
{
    if (_sharePersistence) {
        if (__sharedStoreCoordinator != storeCoordinator) {
            [__sharedStoreCoordinator release];
            __sharedStoreCoordinator = [storeCoordinator retain];
        }
    }else {
        if (_storeCoordinator != storeCoordinator) {
            [_storeCoordinator release];
            _storeCoordinator = [storeCoordinator retain];
        }
    }
}

- (NSManagedObjectContext *)context
{
    if (nil == _context) {
        _context = [[NSManagedObjectContext alloc] init];
    }
    return _context;
}

- (NSManagedObjectModel *)model
{
    return self.storeCoordinator.managedObjectModel;
}

#pragma mark - Synchronous method

- (void)dealloc {
#if DEBUG && CORE_DATA_ENVIR_SHOW_LOG
    NSLog(@"%@", [self currentDispatchQueueLabel]);
#endif
    _create_counter --;

    NSLog(@"%s\ncreate counter :%d\n\n", __func__, _create_counter);
    [self unregisterObserving];
    //[_context reset];
    
    [__recursiveLock release];
    [_context release];
	[fetchedResultsCtrl release];
    [_storeCoordinator release];
    if (_currentQueue) {
        dispatch_release(_currentQueue);
        _currentQueue = NULL;
    }
    [super dealloc];
}

#pragma mark - NSFetchedResultsControllerDelegate
- (NSFetchedResultsController *) fetchedResultsCtrl
{
	//It no used!
	if (fetchedResultsCtrl != nil) {
		return fetchedResultsCtrl;
	}
	
	return fetchedResultsCtrl;
}

- (BOOL)saveDataBase
{
    __block BOOL bResult = NO;
    if (![self.context hasChanges]) {
        return YES;
    }
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
        [self.storeCoordinator performBlockAndWait:doWork];
    }else {
        [self.storeCoordinator lock];
        doWork();
        [self.storeCoordinator unlock];
    }
    #pragma clang pop
    NSLog(@"%s", __FUNCTION__);
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
    [items retain];
    
    for (NSManagedObject *obj in items) {
        [self deleteDataItem:obj];
    }
    
    [items release];
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

- (void)syncInBlock:(void (^)(CoreDataEnvir *))CoreDataBlock
{
    dispatch_sync([self currentQueue], ^{
        CoreDataBlock(self);
        [self saveDataBase];
    });
}

+ (void)asyncMainInBlock:(void (^)(CoreDataEnvir *))CoreDataBlock
{
    [[self mainInstance] asyncInBlock:CoreDataBlock];
}

+ (void)asyncBackgroundInBlock:(void (^)(CoreDataEnvir *))CoreDataBlock
{
    [[self backgroundInstance] asyncInBlock:CoreDataBlock];
}

@end

