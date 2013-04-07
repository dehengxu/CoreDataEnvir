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
#define CONTEXT_LOCK_BEGIN  ;//do {\
BOOL _isLocked = [context tryLock];\
if (_isLocked) {\

//    NSLog(@"context lock succed! %@, context :%@", [self currentDispatchQueueLabel], context);

#define CONTEXT_LOCK_END    ;//[context unlock];\
break;\
}\
} while(0);

#define LOCK_BEGIN  ;
//[recursiveLock lock];
#define LOCK_END    ;
//[recursiveLock unlock];

#pragma mark - ----------------------------- private methods ------------------------

@interface CoreDataEnvir ()

- (void)initCoreDataEnvir;
- (void)initCoreDataEnvirWithPath:(NSString *) path andFileName:(NSString *) dbName;
- (void)initCoreDataEnvirWithSubthread;

@end

#pragma mark - ------------------------------ CoreDataEnvirement -----------------------

static CoreDataEnvir * _coreDataEnvir = nil;
//Not be used.
static NSOperationQueue * _mainQueue = nil;
static NSString *_model_name = nil;
static NSString *_database_name = nil;
//static dispatch_queue_t _background_queue_;

#if CORE_DATA_SHARE_PERSISTANCE
static NSPersistentStoreCoordinator * storeCoordinator = nil;
#endif

@implementation CoreDataEnvir

@synthesize model, context,
#if !CORE_DATA_SHARE_PERSISTANCE
storeCoordinator,
#endif
fetchedResultsCtrl, delegate;

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
        printf("checkName :%s;    ext :%s\n", CharFromString(checkName), CharFromString(name.pathExtension));
        BOOL isDir = NO;
        if ([fm fileExistsAtPath:checkName isDirectory:&isDir] && !isDir, [[name pathExtension] isEqualToString:@"sqlite"]) {
            [fm moveItemAtPath:checkName toPath:[NSString stringWithFormat:@"%@/%@", path, [self databaseFileName]] error:nil];
            NSLog(@"Rename sqlite database from %@ to %@ finished!", name, [self databaseFileName]);
            printf("Rename sqlite database from %s to %s finished!\n", CharFromString(name), CharFromString([self databaseFileName]));
            break;
        }
    }
    NSLog(@"No sqlite database finished!");
    printf("No sqlite database finished!\n");
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
    [cde initCoreDataEnvirWithSubthread];
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

- (void) initCoreDataEnvirWithSubthread
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
        
        context = [[NSManagedObjectContext alloc] init];
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

- (NSManagedObject *) buildManagedObjectByName:(NSString *)className
{
    NSManagedObject *_object = nil;
    LOCK_BEGIN
    CONTEXT_LOCK_BEGIN
    _object = [NSEntityDescription insertNewObjectForEntityForName:className inManagedObjectContext:self.context];
    CONTEXT_LOCK_END
    LOCK_END
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
    
    LOCK_BEGIN
    CONTEXT_LOCK_BEGIN
    NSFetchRequest *req = [[NSFetchRequest alloc] init];
    [req setEntity:[self entityDescriptionByName:entityName]];

    NSError *error = nil;
    items = [self.context executeFetchRequest:req error:&error];
    if (error) {
        NSLog(@"%s, error:%@, entityName:%@", __FUNCTION__, error, entityName);
    }
    [req release];
    CONTEXT_LOCK_END
    LOCK_END

	return items;
}

- (NSArray *) fetchItemsByEntityDescriptionName:(NSString *)entityName usingPredicate:(NSPredicate *)predicate
{
    NSArray *items = nil;
    
    LOCK_BEGIN
    CONTEXT_LOCK_BEGIN

    NSFetchRequest *req = [[NSFetchRequest alloc] init];
    [req setEntity:[self entityDescriptionByName:entityName]];
    [req setPredicate:predicate];
    
    NSError *error = nil;
    items = [self.context executeFetchRequest:req error:&error];
    if (error) {
        NSLog(@"%s, error:%@, entityName:%@", __FUNCTION__, [error localizedDescription], entityName);
    }
    [req release];

    
    CONTEXT_LOCK_END
    LOCK_END

	return items;
}

- (NSArray *) fetchItemsByEntityDescriptionName:(NSString *)entityName usingPredicate:(NSPredicate *)predicate usingSortDescriptions:(NSArray *)sortDescriptions
{
    NSArray *items = nil;
    
    LOCK_BEGIN
    CONTEXT_LOCK_BEGIN
    
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
    
    CONTEXT_LOCK_END
    LOCK_END
	return items;
}

- (NSArray *) fetchItemsByEntityDescriptionName:(NSString *)entityName usingPredicate:(NSPredicate *)predicate usingSortDescriptions:(NSArray *)sortDescriptions fromOffset:(NSUInteger)aOffset LimitedBy:(NSUInteger)aLimited
{
    LOCK_BEGIN
    NSArray *items = nil;
    
    NSFetchRequest *req = [[NSFetchRequest alloc] init];
    NSEntityDescription * entityDescritpion = [self entityDescriptionByName:entityName];
    [req setEntity:entityDescritpion];
    [req setSortDescriptors:sortDescriptions];
    [req setPredicate:predicate];
    [req setFetchOffset:aOffset];
    [req setFetchLimit:aLimited];
    
    NSError *error = nil;
    CONTEXT_LOCK_BEGIN
    items = [self.context executeFetchRequest:req error:&error];
    CONTEXT_LOCK_END
    if (error) {
        NSLog(@"%s, error:%@", __FUNCTION__, [error localizedDescription]);
    }
    [req release];
    
	return items;
}

- (id)dataItemWithID:(NSManagedObjectID *)objectId
{
    if (objectId && self.context) {
        return [self.context objectWithID:objectId];
    }
    return nil;
}

- (id)updateDataItem:(NSManagedObject *)object
{
    if (object) {
        return [self dataItemWithID:object.objectID];
    }
    return object;
}

- (BOOL) deleteDataItem:(NSManagedObject *)aItem
{
    if (!aItem) {
        return NO;
    }
    
    TRY_BEGIN
    NSManagedObject *getObject = [self dataItemWithID:aItem.objectID];
    
#if DEBUG && CORE_DATA_ENVIR_SHOW_LOG
    NSLog(@"%s  objectID :%@; getObject :%@;", __FUNCTION__, aItem.objectID, getObject);
#endif

    if (getObject) {
        [self.context deleteObject:getObject];
    }
#if DEBUG && CORE_DATA_ENVIR_SHOW_LOG
    NSLog(@" delete finished!");
#endif
    
    TRY_CATCH
	return YES;
}

- (BOOL) deleteDataItemSet:(NSSet *)aItemSet
{
    LOCK_BEGIN
    CONTEXT_LOCK_BEGIN
    for (NSManagedObject *obj in aItemSet) {
        [self deleteDataItem:obj];
    }
    CONTEXT_LOCK_END
    LOCK_END
	return YES;
}

- (BOOL)deleteDataItems:(NSArray *)items
{
    LOCK_BEGIN
    CONTEXT_LOCK_BEGIN
    
    [items retain];
    
    for (NSManagedObject *obj in items) {
        [self deleteDataItem:obj];
    }
    
    [items release];
    
    CONTEXT_LOCK_END
    LOCK_END
	return YES;
}

- (BOOL)saveDataBase
{
    //NSString *label = [self currentDispatchQueueLabel];
#if DEBUG && CORE_DATA_ENVIR_SHOW_LOG
    NSLog(@"saving start! %@", label);
#endif
    
    BOOL bResult = NO;
    
    //LOCK_BEGIN
//    CONTEXT_LOCK_BEGIN
    
    [storeCoordinator lock];
	NSError *error = nil;
    
    TRY_BEGIN
    bResult = [self.context save:&error];
    TRY_CATCH
    
    if (!bResult) {
        if (error != nil) {
            NSLog(@"%s, error:%@", __FUNCTION__, error);
        }
        //Do we need rollback?
        //[context rollback];
    }
    [storeCoordinator unlock];
//    CONTEXT_LOCK_END
    //LOCK_END
#if DEBUG && CORE_DATA_ENVIR_SHOW_LOG
    NSLog(@"saved OK! %@", label);
#endif
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

    [recursiveLock release];
	delegate = nil;
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mergeChanges:) name:NSManagedObjectContextDidSaveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDidChange:) name:NSManagedObjectContextObjectsDidChangeNotification object:nil];
}

- (void)unregisterObserving
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextDidSaveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextObjectsDidChangeNotification object:nil];
}

- (void)updateContext:(NSNotification *)notification
{
#if DEBUG && CORE_DATA_ENVIR_SHOW_LOG
    NSLog(@"%s, %@", __FUNCTION__, [self currentDispatchQueueLabel]);
#endif
    
    //LOCK_BEGIN
    //CONTEXT_LOCK_BEGIN
    [storeCoordinator lock];
    @try {
        [self.context mergeChangesFromContextDidSaveNotification:notification];
    }
    @catch (NSException *exception) {
        NSLog(@"exce :%@", exception);
    }
    @finally {
        //NSLog(@"Merge finished!");
    }
    [storeCoordinator unlock];
    //CONTEXT_LOCK_END
    //LOCK_END

//    if (delegate && [delegate respondsToSelector:@selector(didUpdatedContext:)]) {
//        [delegate didUpdatedContext:notification.object];
//    }
}

/**
 
 this is called via observing "NSManagedObjectContextDidSaveNotification" from our ParseOperation
 
 */
- (void)mergeChanges:(NSNotification *)notification {
#if DEBUG && CORE_DATA_ENVIR_SHOW_LOG
    NSLog(@"%s %@", __FUNCTION__, [self currentDispatchQueueLabel]);
#endif
    
    LOCK_BEGIN
    
    if (notification.object == self.context) {
        // main context save, no need to perform the merge
        
#if DEBUG && CORE_DATA_ENVIR_SHOW_LOG
        NSLog(@"    be same context!");
#endif
        LOCK_END
        return;
    }
    
    //[self performSelectorOnMainThread:@selector(updateContext:) withObject:notification waitUntilDone:NO];
    [self performSelector:@selector(updateContext:) onThread:[NSThread currentThread] withObject:notification waitUntilDone:YES];

    LOCK_END
    
}

- (void)handleDidChange:(NSNotification *)notification
{
    LOCK_BEGIN
#if DEBUG && CORE_DATA_ENVIR_SHOW_LOG
    NSLog(@"%s %@ ->>> %@", __FUNCTION__, notification.object, self.context);
#endif
    
    BOOL sameContext = NO;
    sameContext = (notification.object == self.context);
    
    if (sameContext) {
#if DEBUG && CORE_DATA_ENVIR_SHOW_LOG
        NSLog(@"    be same context!");
#endif
        LOCK_END
        return;
    }
    
    //NSLog(@"haha %@ ::%@,  %@", [self currentDispatchQueueLabel], notification.userInfo, notification.object);
    
    if (!sameContext && ![NSThread isMainThread]) {
        //CONTEXT_LOCK_BEGIN
        [self.context processPendingChanges];
        //CONTEXT_LOCK_END
    }
    LOCK_END
}

#pragma mark - 被废弃的方法
+ (CoreDataEnvir *) instance
{
    @synchronized(self) {
        if ([[NSThread currentThread] isMainThread]) {
#if DEBUG && CORE_DATA_ENVIR_SHOW_LOG
         NSLog(@"CoreDataEnvir on main thread!");
            PrintCallStackSymbols(3);
#endif
            return [self sharedInstance];
        }else {
#if DEBUG && CORE_DATA_ENVIR_SHOW_LOG
            NSLog(@"CoreDataEnvir on other thread!");
            PrintCallStackSymbols(3);
#endif
            return [self dataBase];
        }
    }
	return nil;
}

@end

#pragma mark - --------------------------------    NSObject (Debug_Ext)     --------------------------------

@implementation NSObject (Debug_Ext)

- (NSString *)currentDispatchQueueLabel
{
    return [NSString stringWithCString:dispatch_queue_get_label(dispatch_get_current_queue()) encoding:NSUTF8StringEncoding];
}

@end


