//
//  CoreDataEnvir.m
//  CoreDataLab
//
//  Created by NicholasXu on 11-5-25.
//  Copyright 2011 NicholasXu. All rights reserved.
//

#import "CoreDataEnvir.h"

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

#pragma mark - ---------------------- private methods ------------------------

@interface CoreDataEnvir ()

/**
 Rename database file with new registed name.
 */
+ (void)_renameDatabaseFile;

- (void)_initCoreDataEnvirWithPath:(NSString *) path andFileName:(NSString *) dbName;


/**
 Insert a new record into the table by className.
 */
- (NSManagedObject *)buildManagedObjectByName:(NSString *)className;
- (NSManagedObject *)buildManagedObjectByClass:(Class)theClass;


/**
 Get entity descritpion from name string
 */
- (NSEntityDescription *) entityDescriptionByName:(NSString *)className;

/**
 Fetching record item.
 */
- (NSArray *)fetchItemsByEntityDescriptionName:(NSString *)entityName;
- (NSArray *)fetchItemsByEntityDescriptionName:(NSString *)entityName usingPredicate:(NSPredicate *) predicate;
- (NSArray *)fetchItemsByEntityDescriptionName:(NSString *)entityName usingPredicate:(NSPredicate *)predicate usingSortDescriptions:(NSArray *)sortDescriptions;
- (NSArray *)fetchItemsByEntityDescriptionName:(NSString *)entityName usingPredicate:(NSPredicate *) predicate usingSortDescriptions:(NSArray *)sortDescriptions fromOffset:(NSUInteger) aOffset LimitedBy:(NSUInteger)aLimited;

/**
 Add observing for concurrency.
 */
- (void)registerObserving;
- (void)unregisterObserving;

- (void)updateContext:(NSNotification *)notification;
- (void)mergeChanges:(NSNotification *)notification;

/**
 Send processPendingChanges message on non-main thread.
 You should call this method after cluster of actions.
 */
- (void)sendPendingChanges;

/**
 Operating on NSManagedObject
 */
- (id)dataItemWithID:(NSManagedObjectID *)objectId;
- (id)updateDataItem:(NSManagedObject *)object;
- (BOOL)deleteDataItem:(NSManagedObject *)aItem;
- (BOOL)deleteDataItemSet:(NSSet *)aItemSet;
- (BOOL)deleteDataItems:(NSArray*)items;

@end

#pragma mark - ---------------------- CoreDataEnvirement -----------------------

static CoreDataEnvir *_coreDataEnvir = nil;

static CoreDataEnvir *_backgroundInstance = nil;
static dispatch_queue_t _backgroundQueue = nil;

static NSString *_default_model_file_name = nil;
static NSString *_default_db_file_name = nil;
static NSString *_default_data_file_root_path = nil;
static id<CoreDataRescureDelegate> _rescureDelegate = nil;

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

+ (void)_renameDatabaseFile
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *checkName = nil;
    
    NSArray *contents = [fm contentsOfDirectoryAtPath:path error:nil];
    
    for (NSString *name in contents) {
        if ([name rangeOfString:@"."].location == 0) {
            continue;
        }
        if ([name isEqualToString:[self mainInstance].databaseFileName]) {
            break;
        }
        checkName = [NSString stringWithFormat:@"%@/%@", path, name];
        
        BOOL isDir = NO;
        if ([fm fileExistsAtPath:checkName isDirectory:&isDir] && !isDir, [[name pathExtension] isEqualToString:@"sqlite"]) {
            [fm moveItemAtPath:checkName toPath:[NSString stringWithFormat:@"%@/%@", path, [[self mainInstance] databaseFileName]] error:nil];
            NSLog(@"Rename sqlite database from %@ to %@ finished!", name, [[self mainInstance] databaseFileName]);
            break;
        }
    }
    NSLog(@"No sqlite database be renamed!");
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

unsigned int _create_counter = 0;
+ (CoreDataEnvir *) instance
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
        }
    dispatch_semaphore_signal(_sem_main);

	return a_new_db;
}

+ (CoreDataEnvir *)mainInstance
{
    if (_coreDataEnvir == nil) {
        _coreDataEnvir = [[self createInstanceWithDatabaseFileName:nil modelFileName:nil] retain];
    }
    return _coreDataEnvir;
}

+ (dispatch_queue_t)mainQueue
{
    return dispatch_get_main_queue();
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

+ (CoreDataEnvir *)backgroundInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!_backgroundInstance) {
            _backgroundInstance = [[CoreDataEnvir createInstance] retain];
        }
    });
    return _backgroundInstance;
}

+ (dispatch_queue_t)backgroundQueue
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!_backgroundQueue) {
            _backgroundQueue = dispatch_queue_create("me.deheng.coredataenvir.background", NULL);
        }
    });
    return _backgroundQueue;
}

//+ (void) deleteInstance
//{
//	if (_coreDataEnvir) {
//		[_coreDataEnvir dealloc];
//        _coreDataEnvir = nil;
//	}
//}

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
            [self release];
            return nil;
        }
        @finally {
            
        }
        
        //[self.class _renameDatabaseFile];
        
        _create_counter ++;

    }
    return self;
}

- (void) _initCoreDataEnvirWithPath:(NSString *)path andFileName:(NSString *) dbName
{
    NSLog(@"%s   %@  /  %@", __FUNCTION__,path, dbName);
    //Scan all of momd directory.
    //NSArray *momdPaths = [[NSBundle mainBundle] pathsForResourcesOfType:@"momd" inDirectory:nil];
    NSURL *fileUrl = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@", path, dbName]];
    
    NSFileManager *fman = [NSFileManager defaultManager];
    if (![fman fileExistsAtPath:path]) {
        [fman createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    [self.context setRetainsRegisteredObjects:NO];
    [self.context setPropagatesDeletesAtEndOfEvent:NO];
    [self.context setMergePolicy:NSOverwriteMergePolicy];
    
    if (self.storeCoordinator == nil) {
        NSString *momdPath = [[NSBundle mainBundle] pathForResource:[self modelFileName] ofType:@"momd"];
        NSURL *momdURL = [NSURL fileURLWithPath:momdPath];

        NSManagedObjectModel *model = nil;
        model = [[[NSManagedObjectModel alloc] initWithContentsOfURL:momdURL] autorelease];
        if (!model) {
            NSLog(@"You create instances' number more than 123.");
            NSException *exce = [NSException exceptionWithName:[NSString stringWithFormat:@"CoreDataEnvir exception %d", CDEErrorInstanceCreateTooMutch] reason:@"You create instances' number more than 123." userInfo:@{@"error": [NSError errorWithDomain:@"com.cyblion.CoreDataEnvir" code:CDEErrorInstanceCreateTooMutch userInfo:nil]}];
            [exce raise];
            return;
        }
        
        self.storeCoordinator = [[[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model] autorelease];

        NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                                 [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption,
                                 nil];
        
        NSError *error;

        if (![self.storeCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:fileUrl options:options error:&error]) {
            NSLog(@"%s Failed! %@", __FUNCTION__, error);
            if (_rescureDelegate &&
                [_rescureDelegate respondsToSelector:@selector(shouldRescureCoreData)] &&
                [_rescureDelegate shouldRescureCoreData]) {
                
                if (_rescureDelegate && [_rescureDelegate respondsToSelector:@selector(didStartRescureCoreData:)]) {
                    [_rescureDelegate didStartRescureCoreData:self];
                }
                
                //Create new store coordinator.
                self.storeCoordinator = [[[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model] autorelease];

                
                if (![self.storeCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:fileUrl options:options error:&error]) {
                    //Rescure failed again!!
                    if (_rescureDelegate &&
                        [_rescureDelegate respondsToSelector:@selector(rescureFailed:)]) {
                        [_rescureDelegate rescureFailed:self];
                    }
                    
                    //Abort while rescure failed.
                    if (_rescureDelegate &&
                        [_rescureDelegate respondsToSelector:@selector(shouldAbortWhileRescureFailed)] &&
                        [_rescureDelegate shouldAbortWhileRescureFailed]) {
                        abort();
                    }
                }else {
                    //Rescure finished.
                    [self.context setPersistentStoreCoordinator:self.storeCoordinator];
                    if (_rescureDelegate && [_rescureDelegate respondsToSelector:@selector(didFinishedRescuringCoreData:)]) {
                        [_rescureDelegate didFinishedRescuringCoreData:self];
                    }
                }
            }else {
                abort();
            }
        }else {
            [self.context setPersistentStoreCoordinator:self.storeCoordinator];
        }
        
    }else {
        [self.context setPersistentStoreCoordinator:self.storeCoordinator];
    }
    
    [self registerObserving];
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

- (NSManagedObject *) buildManagedObjectByName:(NSString *)className
{
    NSManagedObject *_object = nil;
    _object = [NSEntityDescription insertNewObjectForEntityForName:className inManagedObjectContext:self.context];
    return _object;
}

- (NSManagedObject *)buildManagedObjectByClass:(Class)theClass
{
    NSManagedObject *_object = nil;
    _object = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass(theClass) inManagedObjectContext:self.context];
    return _object;
}

- (NSEntityDescription *) entityDescriptionByName:(NSString *)className
{
	return [NSEntityDescription entityForName:className inManagedObjectContext:self.context];
}

- (NSManagedObjectModel *)model
{
    return self.storeCoordinator.managedObjectModel;
}

#pragma mark - Synchronous method

- (NSArray *) fetchItemsByEntityDescriptionName:(NSString *)entityName
{
    NSArray *items = nil;
    
    NSFetchRequest *req = [[NSFetchRequest alloc] init];
    [req setEntity:[self entityDescriptionByName:entityName]];
    
    NSError *error = nil;
    items = [self.context executeFetchRequest:req error:&error];
    if (error) {
        NSLog(@"%s, error:%@, entityName:%@", __FUNCTION__, error, entityName);
    }
    [req release];
    
	return items;
}

- (NSArray *) fetchItemsByEntityDescriptionName:(NSString *)entityName usingPredicate:(NSPredicate *)predicate
{
    NSArray *items = nil;
    
    NSFetchRequest *req = [[NSFetchRequest alloc] init];
    [req setEntity:[self entityDescriptionByName:entityName]];
    [req setPredicate:predicate];
    
    NSError *error = nil;
    items = [self.context executeFetchRequest:req error:&error];
    if (error) {
        NSLog(@"%s, error:%@, entityName:%@", __FUNCTION__, [error localizedDescription], entityName);
    }
    [req release];
    
	return items;
}

- (NSArray *) fetchItemsByEntityDescriptionName:(NSString *)entityName usingPredicate:(NSPredicate *)predicate usingSortDescriptions:(NSArray *)sortDescriptions
{
    NSArray *items = nil;
    
    NSFetchRequest *req = [[NSFetchRequest alloc] init];
    NSEntityDescription * entityDescritpion = [self entityDescriptionByName:entityName];
    [req setEntity:entityDescritpion];
    [req setSortDescriptors:sortDescriptions];
    [req setPredicate:predicate];
    NSError *error = nil;
    items = [self.context executeFetchRequest:req error:&error];
    if (error) {
        NSLog(@"%s, error:%@", __FUNCTION__, [error localizedDescription]);
    }
    [req release];
    
	return items;
}

- (NSArray *) fetchItemsByEntityDescriptionName:(NSString *)entityName usingPredicate:(NSPredicate *)predicate usingSortDescriptions:(NSArray *)sortDescriptions fromOffset:(NSUInteger)aOffset LimitedBy:(NSUInteger)aLimited
{
    NSArray *items = nil;
    
    NSFetchRequest *req = [[NSFetchRequest alloc] init];
    NSEntityDescription * entityDescritpion = [self entityDescriptionByName:entityName];
    [req setEntity:entityDescritpion];
    [req setSortDescriptors:sortDescriptions];
    [req setPredicate:predicate];
    [req setFetchOffset:aOffset];
    [req setFetchLimit:aLimited];
    
    NSError *error = nil;
    
    items = [self.context executeFetchRequest:req error:&error];
    
    if (error) {
        NSLog(@"%s, error:%@", __FUNCTION__, [error localizedDescription]);
    }
    [req release];
    
	return items;
}

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

- (BOOL) deleteDataItem:(NSManagedObject *)aItem
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

- (BOOL)saveDataBase
{
    BOOL bResult = NO;
    if (![self.context hasChanges]) {
        return YES;
    }
    
    [self.storeCoordinator lock];
	NSError *error = nil;
    
    bResult = [self.context save:&error];
    
    if (!bResult) {
        if (error != nil) {
            NSLog(@"%s, error:%@", __FUNCTION__, error);
        }
        //Do we need rollback?
        //[context rollback];
    }
    [self.storeCoordinator unlock];
    NSLog(@"%s", __FUNCTION__);
	return bResult;
}

//- (id) autorelease
//{
//	return self;
//}

//- (oneway void) release
//{
//	;
//}

//- (id) retain
//{
//	return self;
//}

//- (id)copy
//{
//    return self;
//}

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

#pragma mark - updateContext
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

- (void)updateContext:(NSNotification *)notification
{
#if DEBUG && CORE_DATA_ENVIR_SHOW_LOG
    NSLog(@"%s %@ ->>> %@", __FUNCTION__, notification.object, self.context);
#endif
    
    [self.storeCoordinator lock];
    @try {
        //After this merge operating, context update it's state 'hasChanges' .
        [self.context mergeChangesFromContextDidSaveNotification:notification];
    }
    @catch (NSException *exception) {
        NSLog(@"exce :%@", exception);
    }
    @finally {
        //NSLog(@"Merge finished!");
    }
    [self.storeCoordinator unlock];
}

/**
 
 this is called via observing "NSManagedObjectContextDidSaveNotification" from our ParseOperation
 
 */
- (void)mergeChanges:(NSNotification *)notification {
#if DEBUG && CORE_DATA_ENVIR_SHOW_LOG
    NSLog(@"%s [%@/%@] %@", __FUNCTION__, self.context, notification.object, [self currentDispatchQueueLabel]);
#endif
    
    if (notification.object == self.context) {
        // main context save, no need to perform the merge
        return;
    }
    
    //[self performSelectorOnMainThread:@selector(updateContext:) withObject:notification waitUntilDone:NO];
    //Note:waitUntilDone:YES will cause method 'saveDatabase' and 'updateContext' fall in dead lock by '[storeCoordinator lock]'
    [self performSelector:@selector(updateContext:) onThread:[NSThread currentThread] withObject:notification waitUntilDone:YES];
}

- (void)sendPendingChanges
{
    if ([NSThread isMainThread] ||
        !self.context) {
        return;
    }
    [self.context processPendingChanges];
}

@end

#pragma mark - --------------------------------    NSObject (Debug_Ext)     --------------------------------

@implementation NSObject (Debug_Ext)

- (NSString *)currentDispatchQueueLabel
{
#if DEBUG
    dispatch_queue_t q = dispatch_get_current_queue();
    return [NSString stringWithCString:dispatch_queue_get_label(q) encoding:NSUTF8StringEncoding];
#else
    return nil;
#endif
}

@end


#pragma mark - --------------------------------    NSManagedObject (CONVENIENT)    --------------------------------
@implementation NSManagedObject(CONVENIENT)

#pragma mark - Operation on main thread.

#pragma mark - insert new record item

+ (id)insertItem
{
    if (![NSThread isMainThread]) {
#if DEBUG
        NSLog(@"Insert item record failed, please run on main thread!");
#endif
        [[NSException exceptionWithName:@"CoreDataEnviroment" reason:@"Insert item record failed, must run on main thread!" userInfo:nil] raise];
        return nil;
    }
    CoreDataEnvir *db = [CoreDataEnvir mainInstance];
    id item = [self insertItemInContext:db];
    return item;
}

+ (id)insertItemWithBlock:(void (^)(id item))settingBlock
{
    id item = [self insertItem];
    settingBlock(item);
    return item;
}

#pragma mark - fetch items

+ (NSArray *)items
{
    if (![NSThread isMainThread]) {
#if DEBUG
        NSLog(@"Fetch all items record failed, please run on main thread!");
#endif
        [[NSException exceptionWithName:@"CoreDataEnviroment" reason:@"Fetch all items record failed, must run on main thread!" userInfo:nil] raise];
        return nil;
    }
    CoreDataEnvir *db = [CoreDataEnvir mainInstance];
    NSArray *items = [db fetchItemsByEntityDescriptionName:NSStringFromClass(self)];

    return items;
}

+ (NSArray *)itemsWithPredicate:(NSPredicate *)predicate
{
    if (![NSThread isMainThread]) {
#if DEBUG
        NSLog(@"Fetch item record failed, please run on main thread!");
#endif
        [[NSException exceptionWithName:@"CoreDataEnviroment" reason:@"Fetch item record failed, must run on main thread!" userInfo:nil] raise];
        return nil;
    }
    CoreDataEnvir *db = [CoreDataEnvir mainInstance];
    NSArray *items = [db fetchItemsByEntityDescriptionName:NSStringFromClass(self) usingPredicate:predicate];
    return items;
}

+ (NSArray *)itemsWithFormat:(NSString *)fmt, ...
{
    va_list args;
    va_start(args, fmt);
    NSPredicate *pred = [NSPredicate predicateWithFormat:fmt arguments:args];
    va_end(args);
    CoreDataEnvir *db = [CoreDataEnvir mainInstance];
    NSArray *items = [db fetchItemsByEntityDescriptionName:NSStringFromClass(self) usingPredicate:pred];
    return items;
}

+ (NSArray *)itemsSortDescriptions:(NSArray *)sortDescriptions withFormat:(NSString *)fmt, ...
{
    va_list args;
    va_start(args, fmt);
    NSPredicate *pred = [NSPredicate predicateWithFormat:fmt arguments:args];
    va_end(args);
    CoreDataEnvir *db = [CoreDataEnvir mainInstance];
    NSArray *items = [db fetchItemsByEntityDescriptionName:NSStringFromClass(self) usingPredicate:pred usingSortDescriptions:sortDescriptions];
    return items;
}

+ (NSArray *)itemsSortDescriptions:(NSArray *)sortDescriptions fromOffset:(NSUInteger)offset limitedBy:(NSUInteger)limtNumber withFormat:(NSString *)fmt, ...
{
    va_list args;
    va_start(args, fmt);
    NSPredicate *pred = [NSPredicate predicateWithFormat:fmt arguments:args];
    va_end(args);
    CoreDataEnvir *db = [CoreDataEnvir mainInstance];
    NSArray *items = [db fetchItemsByEntityDescriptionName:NSStringFromClass(self) usingPredicate:pred usingSortDescriptions:sortDescriptions fromOffset:offset LimitedBy:limtNumber];
    return items;
}

#pragma mark - fetch last item

+ (id)lastItem
{
    if (![NSThread isMainThread]) {
#if DEBUG
        NSLog(@"Fetch last item record failed, please run on main thread!");
#endif
        [[NSException exceptionWithName:@"CoreDataEnviroment" reason:@"Fetch last item record failed, must run on main thread!" userInfo:nil] raise];
        return nil;
    }
    
    return [[self items] lastObject];
}

+ (NSArray *)lastItemWithPredicate:(NSPredicate *)predicate
{
    if (![NSThread isMainThread]) {
#if DEBUG
        NSLog(@"Fetch last item record failed, please run on main thread!");
#endif
        [[NSException exceptionWithName:@"CoreDataEnviroment" reason:@"Fetch last item record failed, must run on main thread!" userInfo:nil] raise];
        return nil;
    }
    
    return [[self itemsInContext:[CoreDataEnvir mainInstance] usingPredicate:predicate] lastObject];
}

+ (id)lastItemWithFormat:(NSString *)fmt, ...
{
    va_list args;
    va_start(args, fmt);
    NSPredicate *pred = [NSPredicate predicateWithFormat:fmt arguments:args];
    va_end(args);
    return [self lastItemWithPredicate:pred];
}

#pragma mark - Operation on other sperate thread.

#pragma mark - Insert item record

+ (id)insertItemInContext:(CoreDataEnvir *)cde
{
#if DEBUG
    NSLog(@"%s thread :%u, %@", __func__, [NSThread isMainThread], [NSString stringWithCString:dispatch_queue_get_label(dispatch_get_current_queue()) encoding:NSUTF8StringEncoding]);
#endif
    id item = nil;
    item = [cde buildManagedObjectByClass:self];
    return item;
}

+ (id)insertItemInContext:(CoreDataEnvir *)cde fillData:(void (^)(id item))settingBlock
{
#if DEBUG
    NSLog(@"%s thread :%u, %@", __func__, [NSThread isMainThread], [NSString stringWithCString:dispatch_queue_get_label(dispatch_get_current_queue()) encoding:NSUTF8StringEncoding]);
#endif
    id item = [self insertItemInContext:cde];
    settingBlock(item);
    return item;
}

#pragma mark - fetch items

+ (NSArray *)itemsInContext:(CoreDataEnvir *)cde
{
    NSArray *items = [cde fetchItemsByEntityDescriptionName:NSStringFromClass(self)];
    return items;
}

+ (NSArray *)itemsInContext:(CoreDataEnvir *)cde usingPredicate:(NSPredicate *)predicate
{
    NSArray *items = [cde fetchItemsByEntityDescriptionName:NSStringFromClass(self) usingPredicate:predicate];
    return items;
}

+ (NSArray *)itemsInContext:(CoreDataEnvir *)cde withFormat:(NSString *)fmt, ...
{
    va_list args;
    va_start(args, fmt);
    NSPredicate *pred = [NSPredicate predicateWithFormat:fmt arguments:args];
    va_end(args);
    
    NSArray *items = [cde fetchItemsByEntityDescriptionName:NSStringFromClass(self) usingPredicate:pred];
    return items;
}

+ (NSArray *)itemsInContext:(CoreDataEnvir *)cde sortDescriptions:(NSArray *)sortDescriptions withFormat:(NSString *)fmt, ...
{
    va_list args;
    va_start(args, fmt);
    NSPredicate *pred = [NSPredicate predicateWithFormat:fmt arguments:args];
    va_end(args);
    NSArray *items = [cde fetchItemsByEntityDescriptionName:NSStringFromClass(self) usingPredicate:pred usingSortDescriptions:sortDescriptions];
    return items;
}

+ (NSArray *)itemsInContext:(CoreDataEnvir *)cde sortDescriptions:(NSArray *)sortDescriptions fromOffset:(NSUInteger)offset limitedBy:(NSUInteger)limtNumber withFormat:(NSString *)fmt, ...
{
    va_list args;
    va_start(args, fmt);
    NSPredicate *pred = [NSPredicate predicateWithFormat:fmt arguments:args];
    va_end(args);
    NSArray *items = [cde fetchItemsByEntityDescriptionName:NSStringFromClass(self) usingPredicate:pred usingSortDescriptions:sortDescriptions fromOffset:offset LimitedBy:limtNumber];
    return items;
}

#pragma mark - fetch last item

+ (id)lastItemInContext:(CoreDataEnvir *)cde
{
    return [[self itemsInContext:cde] lastObject];
}

+ (id)lastItemInContext:(CoreDataEnvir *)cde usingPredicate:(NSPredicate *)predicate
{
    return [[self itemsInContext:cde usingPredicate:predicate] lastObject];
}

+ (id)lastItemInContext:(CoreDataEnvir *)cde withFormat:(NSString *)fmt, ...
{
    va_list args;
    va_start(args, fmt);
    NSPredicate *pred = [NSPredicate predicateWithFormat:fmt arguments:args];
    va_end(args);
    
    return [[self itemsInContext:cde usingPredicate:pred] lastObject];
}

#pragma mark - merge context when update

- (id)update
{
    if ([NSThread isMainThread]) {
        return [[CoreDataEnvir instance] updateDataItem:self];
    }
    return nil;
}

- (id)updateInContext:(CoreDataEnvir *)cde
{
    return [cde updateDataItem:self];
}

- (void)removeFrom:(CoreDataEnvir *)cde
{
    if (!cde) {
        return;
    }
    [cde deleteDataItem:self];
}

- (void)remove
{
    if (![NSThread isMainThread]) {
#if DEBUG
        NSLog(@"Remove data failed, cannot run on non-main thread!");
#endif
        [[NSException exceptionWithName:@"CoreDataEnviroment" reason:@"Remove data failed, must run on main thread!" userInfo:nil] raise];
        return;
    }
    if (![CoreDataEnvir mainInstance]) {
        return;
    }
    [[CoreDataEnvir mainInstance] deleteDataItem:self];
}

- (BOOL)saveTo:(CoreDataEnvir *)cde
{
    if (!cde) {
        return NO;
    }
    
    return [cde saveDataBase];
}

- (BOOL)save
{
    if (![NSThread isMainThread]) {
#if DEBUG
        NSLog(@"Save data failed, cannot run on non-main thread!");
#endif
        [[NSException exceptionWithName:@"CoreDataEnviroment" reason:@"Save data failed, must run on main thread!" userInfo:nil] raise];
        return NO;
    }
    if (![CoreDataEnvir mainInstance]) {
        return NO;
    }
    
    return [[CoreDataEnvir mainInstance] saveDataBase];
}

@end


