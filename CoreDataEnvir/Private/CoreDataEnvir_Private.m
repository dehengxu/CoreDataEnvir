//
//  CoreDataEnvir_Private.m
//  CoreDataEnvirSample
//
//  Created by NicholasXu on 15/8/30.
//  Copyright (c) 2015年 Nicholas.Xu. All rights reserved.
//

#import "CoreDataEnvir_Private.h"
#import "CoreDataEnvir_Main.h"

CoreDataEnvir *_backgroundInstance = nil;
CoreDataEnvir *_coreDataEnvir = nil;

@implementation CoreDataEnvir (CDEPrivate)

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
        if ([name isEqualToString:[[self mainInstance] databaseFileName]]) {
            break;
        }
        checkName = [NSString stringWithFormat:@"%@/%@", path, name];
        
        BOOL isDir = NO;
        if ([fm fileExistsAtPath:checkName isDirectory:&isDir] && !isDir && [[name pathExtension] isEqualToString:@"sqlite"]) {
            [fm moveItemAtPath:checkName toPath:[NSString stringWithFormat:@"%@/%@", path, [[self mainInstance] databaseFileName]] error:nil];
            NSLog(@"Rename sqlite database from %@ to %@ finished!", name, [[self mainInstance] databaseFileName]);
            break;
        }
    }
    NSLog(@"No sqlite database be renamed!");
}

- (NSFetchRequest *)newFetchRequest {
	NSFetchRequest *req = [[NSFetchRequest alloc] init];
	[req setEntity:[NSEntityDescription entityForName:NSStringFromClass(self.class) inManagedObjectContext:self.context]];
	return req;
}

- (void) _initCoreDataEnvirWithPath:(NSString *)path andFileName:(NSString *) dbName
{
#if DEBGU && CORE_DATA_ENVIR_SHOW_LOG
    NSLog(@"%s   %@  /  %@", __FUNCTION__,path, dbName);
#endif

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

- (NSUInteger)fetchRequestCount {

	NSFetchRequest *req = [self newFetchRequest];
	NSUInteger rtn = [self.context countForFetchRequest:req error:nil];
	return rtn;
}

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

    void (^doWork)(void) = ^ {
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
    };
    #pragma clang push
    #pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if ([[UIDevice currentDevice] systemVersion].floatValue >= 8.0) {
        [self.storeCoordinator performBlockAndWait:doWork];
    }else {
        [self.storeCoordinator lock];
        doWork();
        [self.storeCoordinator unlock];
    }
    #pragma clang pop

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
