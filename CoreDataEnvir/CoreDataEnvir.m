//
//  CoreDataEnvir.m
//  CoreDataLab
//
//  Created by NicholasXu on 11-5-25.
//  Copyright 2011 NicholasXu. All rights reserved.
//

#import "CoreDataEnvir.h"

/*
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

- (void)initCoreDataEnvir;
- (void)initCoreDataEnvirWithPath:(NSString *) path andFileName:(NSString *) dbName;

@end

#pragma mark - ---------------------- CoreDataEnvirement -----------------------

static CoreDataEnvir * _coreDataEnvir = nil;
//Not be used.
static NSOperationQueue * _mainQueue = nil;
static NSString *_model_name = nil;
static NSString *_database_name = nil;

#if CORE_DATA_SHARE_PERSISTANCE
static NSPersistentStoreCoordinator * storeCoordinator = nil;
#endif

@implementation CoreDataEnvir

@synthesize model, context = _context,

#if !CORE_DATA_SHARE_PERSISTANCE
storeCoordinator,
#endif

fetchedResultsCtrl;

+ (void)initialize
{
	if (!_mainQueue) {
		_mainQueue = [NSOperationQueue new];
        _model_name = @"ModelName";
        _database_name = @"db.sqlite";
		[_mainQueue setMaxConcurrentOperationCount:1];
	}
}

+ (void)registModelFileName:(NSString *)name
{
    if (_model_name) {
        [_model_name release];
        _model_name = nil;
    }
    _model_name = [name copy];
}

+ (void)registDatabaseFileName:(NSString *)name
{
    if (_database_name) {
        [_database_name release];
        _database_name = nil;
    }
    _database_name = [name copy];
}

+ (void)renameDatabaseFile
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *checkName = nil;
    
    NSArray *contents = [fm contentsOfDirectoryAtPath:path error:nil];
    
    for (NSString *name in contents) {
        if ([name rangeOfString:@"."].location == 0) {
            continue;
        }
        if ([name isEqualToString:_database_name]) {
            break;
        }
        checkName = [NSString stringWithFormat:@"%@/%@", path, name];
        
        BOOL isDir = NO;
        if ([fm fileExistsAtPath:checkName isDirectory:&isDir] && !isDir, [[name pathExtension] isEqualToString:@"sqlite"]) {
            [fm moveItemAtPath:checkName toPath:[NSString stringWithFormat:@"%@/%@", path, [self databaseFileName]] error:nil];
            NSLog(@"Rename sqlite database from %@ to %@ finished!", name, [self databaseFileName]);
            break;
        }
    }
    NSLog(@"No sqlite database be renamed!");
}

+ (NSString *)modelFileName
{
    return [[_model_name copy] autorelease];
}

+ (NSString *)databaseFileName
{
    return [[_database_name copy] autorelease];
}

+ (CoreDataEnvir *)sharedInstance
{
    @synchronized(self) {
        if (_coreDataEnvir == nil) {
            _coreDataEnvir = [CoreDataEnvir new];
            [_coreDataEnvir initCoreDataEnvir];
        }
        return _coreDataEnvir;
    }
	return nil;
}

+ (CoreDataEnvir *)dataBase
{
    id cde = nil;
    cde = [self new];
    [cde initCoreDataEnvir];
    return [cde autorelease];
}

+ (void) deleteInstance
{
	if (_coreDataEnvir) {
		[_coreDataEnvir dealloc];
        _coreDataEnvir = nil;
	}
}

- (id)init
{
    self = [super init];
    if (self) {
        recursiveLock = [[NSRecursiveLock alloc] init];
        [self.class renameDatabaseFile];
    }
    return self;
}

- (void) initCoreDataEnvir
{
    LOCK_BEGIN
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    [self initCoreDataEnvirWithPath:path andFileName:[NSString stringWithFormat:@"%@", [self.class databaseFileName]]];
    LOCK_END
}

- (void) initCoreDataEnvirWithPath:(NSString *)path andFileName:(NSString *) dbName
{
    
    //Scan all of momd directory.
    //NSArray *momdPaths = [[NSBundle mainBundle] pathsForResourcesOfType:@"momd" inDirectory:nil];
    NSURL *fileUrl = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@", path, dbName]];
    
    [self.context setRetainsRegisteredObjects:NO];
    [self.context setPropagatesDeletesAtEndOfEvent:NO];
    [self.context setMergePolicy:NSOverwriteMergePolicy];
    
    if (storeCoordinator == nil) {
        //model = [[NSManagedObjectModel mergedModelFromBundles:nil] retain];
        NSString *momdPath = [[NSBundle mainBundle] pathForResource:[self.class modelFileName] ofType:@"momd"];
        NSURL *momdURL = [NSURL fileURLWithPath:momdPath];
        model = [[NSManagedObjectModel alloc] initWithContentsOfURL:momdURL];
        
        storeCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
        
        NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                                 [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption,
                                 nil];
        
        NSError *error;
        LOCK_BEGIN
        if (![storeCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:fileUrl options:options error:&error]) {
            NSLog(@"%s Failed! %@", __FUNCTION__, error);
            abort();
        }else {
            [self.context setPersistentStoreCoordinator:storeCoordinator];
        }
        
        LOCK_END
    }else {
        [self.context setPersistentStoreCoordinator:storeCoordinator];
    }
    
    [self registerObserving];
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
    
    [storeCoordinator lock];
	NSError *error = nil;
    
    bResult = [self.context save:&error];
    
    if (!bResult) {
        if (error != nil) {
            NSLog(@"%s, error:%@", __FUNCTION__, error);
        }
        //Do we need rollback?
        //[context rollback];
    }
    [storeCoordinator unlock];
    
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
    [self unregisterObserving];
    [self.context reset];
    
    [recursiveLock release];
	[model release];
    [context release];
	[fetchedResultsCtrl release];
#if !CORE_DATA_SHARE_PERSISTANCE
    [storeCoordinator release];
    storeCoordinator = nil;
#endif
    
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
    
    [storeCoordinator lock];
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
    [storeCoordinator unlock];
}

/**
 
 this is called via observing "NSManagedObjectContextDidSaveNotification" from our ParseOperation
 
 */
- (void)mergeChanges:(NSNotification *)notification {
#if DEBUG && CORE_DATA_ENVIR_SHOW_LOG
    NSLog(@"%s %@", __FUNCTION__, [self currentDispatchQueueLabel]);
#endif
    
    if (notification.object == self.context) {
        // main context save, no need to perform the merge
        return;
    }
    
    //[self performSelectorOnMainThread:@selector(updateContext:) withObject:notification waitUntilDone:NO];
    [self performSelector:@selector(updateContext:) onThread:[NSThread currentThread] withObject:notification waitUntilDone:YES];
}

#pragma mark - creating
+ (CoreDataEnvir *) instance
{
    @synchronized(self) {
        if ([[NSThread currentThread] isMainThread]) {
#if DEBUG && CORE_DATA_ENVIR_SHOW_LOG
            NSLog(@"CoreDataEnvir on main thread!");
#endif
            return [self sharedInstance];
        }else {
#if DEBUG && CORE_DATA_ENVIR_SHOW_LOG
            NSLog(@"CoreDataEnvir on other thread!");
#endif
            return [self dataBase];
        }
    }
	return nil;
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

@implementation NSManagedObject(EASY_MODE)

+ (id)insertItem
{
    if (![NSThread isMainThread]) {
#if DEBUG
        NSLog(@"Insert item record failed, please run on main thread!");
#endif
        [[NSException exceptionWithName:@"CoreDataEnviroment" reason:@"Insert item record failed, must run on main thread!" userInfo:nil] raise];
        return nil;
    }
    CoreDataEnvir *db = [CoreDataEnvir sharedInstance];
    id item = [self insertItemInContext:db];
    return item;
}

+ (id)insertItemWithBlock:(void (^)(id item))settingBlock
{
    id item = [self insertItem];
    settingBlock(item);
    return item;
}

+ (id)insertItemInContext:(CoreDataEnvir *)cde
{
#if DEBUG
    NSLog(@"thread :%u, %@", [NSThread isMainThread], [NSString stringWithCString:dispatch_queue_get_label(dispatch_get_current_queue()) encoding:NSUTF8StringEncoding]);
#endif
    id item = nil;
    item = [cde buildManagedObjectByClass:self];
    return item;
}

+ (id)insertItemInContext:(CoreDataEnvir *)cde fillData:(void (^)(id item))settingBlock
{
    id item = [self insertItemInContext:cde];
    settingBlock(item);
    return item;
}

+ (NSArray *)items
{
    if (![NSThread isMainThread]) {
#if DEBUG
        NSLog(@"Fetch all items record failed, please run on main thread!");
#endif
        [[NSException exceptionWithName:@"CoreDataEnviroment" reason:@"Fetch all items record failed, must run on main thread!" userInfo:nil] raise];
        return nil;
    }
    CoreDataEnvir *db = [CoreDataEnvir sharedInstance];
    NSArray *items = [self itemsInContext:db usingPredicate:nil];
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
    CoreDataEnvir *db = [CoreDataEnvir sharedInstance];
    NSArray *items = [self itemsInContext:db usingPredicate:predicate];
    return items;
}

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

+ (id)lastItemInContext:(CoreDataEnvir *)cde
{
    return [[self itemsInContext:cde] lastObject];
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
    
    return [self lastItemInContext:[CoreDataEnvir sharedInstance] usingPredicate:predicate];
}

+ (NSArray *)itemsInContext:(CoreDataEnvir *)cde usingPredicate:(NSPredicate *)predicate
{
    NSArray *items = [cde fetchItemsByEntityDescriptionName:NSStringFromClass(self) usingPredicate:predicate];
    return items;
}

+ (id)lastItemInContext:(CoreDataEnvir *)cde usingPredicate:(NSPredicate *)predicate
{
    return [[self itemsInContext:cde usingPredicate:predicate] lastObject];
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
    if (![CoreDataEnvir sharedInstance]) {
        return;
    }
    [[CoreDataEnvir sharedInstance] deleteDataItem:self];
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
    if (![CoreDataEnvir sharedInstance]) {
        return NO;
    }
    
    return [[CoreDataEnvir sharedInstance] saveDataBase];
}

@end


