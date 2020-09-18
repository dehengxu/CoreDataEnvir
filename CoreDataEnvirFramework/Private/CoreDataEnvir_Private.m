//
//  CoreDataEnvir_Private.m
//  CoreDataEnvirSample
//
//  Created by NicholasXu on 15/8/30.
//  Copyright (c) 2015年 Nicholas.Xu. All rights reserved.
//

#import "CoreDataEnvir_Private.h"
#import "CoreDataEnvir_Main.h"

id<CoreDataRescureDelegate> _rescureDelegate;
CoreDataEnvir *_backgroundInstance = nil;
CoreDataEnvir *_mainInstance = nil;

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

- (NSFetchRequest *)newFetchRequestWithName:(NSString *)name error:(NSError **)error {
	NSEntityDescription *entity = [NSEntityDescription entityForName:name inManagedObjectContext:self.context];
	if (!entity) {
		*error = [NSError errorWithDomain:@"CoreDataEnvir: entity create failed" code:0 userInfo:nil];
        return nil;
	}
    NSFetchRequest *req = [[NSFetchRequest alloc] init];
	[req setEntity:entity];
	return req;
}

- (NSFetchRequest *)newFetchRequestWithClass:(Class)clazz error:(NSError **)error {
	if (!clazz) {
		*error = [NSError errorWithDomain:@"CoreDataEnvir: class is nil." code:0 userInfo:nil];
		return nil;
	}
	NSString* name = NSStringFromClass(clazz);
	NSFetchRequest *req = [self newFetchRequestWithName:name error:error];
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
    
    if (self.persistentStoreCoordinator == nil) {
		NSString *momdPath = nil;
		//Use modelFilePath
		if (CoreDataEnvir.modelFilePath.length) {
			momdPath = CoreDataEnvir.modelFilePath;
		}

		//Or search from main bundle
		if (!momdPath.length) {
#if DEBUG
			NSLog(@"");
#endif
			momdPath = [NSBundle.mainBundle pathForResource:[self modelFileName] ofType:@"momd"];
		}

		if (!momdPath.length) {
			NSException *exce = [NSException exceptionWithName:[NSString stringWithFormat:@"CoreDataEnvir exception %d", CDEErrorModelFileNotFound] reason:@"Model file momd " userInfo:@{@"error": [NSError errorWithDomain:CDE_ERROR_DOMAIN code:CDEErrorModelFileNotFound userInfo:nil]}];
			[exce raise];
			return;
		}
        NSURL *momdURL = [NSURL fileURLWithPath:momdPath];
        
        self.model = [[NSManagedObjectModel alloc] initWithContentsOfURL:momdURL];
        if (!self.model) {
            NSString* msg = [NSString stringWithFormat:@"CoreData model is nil. model file: %@", momdPath];
            NSError* err = [NSError errorWithDomain:@"com.cyblion.CoreDataEnvir" code:CDEErrorInstanceCreateTooMutch userInfo:nil];
            NSLog(@"%@", msg);
            NSException *exce = [NSException exceptionWithName:[NSString stringWithFormat:@"CoreDataEnvir exception %d", CDEErrorInstanceCreateTooMutch] reason:msg userInfo:@{@"error": err}];
            [exce raise];
            return;
        }
        
        self.persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.model];
        
        NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                                 [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption,
                                 nil];
        
        NSError *error;
        
        if (![self.persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:fileUrl options:options error:&error]) {
            NSLog(@"%s Failed! %@", __FUNCTION__, error);
            if (_rescureDelegate &&
                [_rescureDelegate respondsToSelector:@selector(shouldRescureCoreData)] &&
                [_rescureDelegate shouldRescureCoreData]) {
                
                if (_rescureDelegate && [_rescureDelegate respondsToSelector:@selector(didStartRescureCoreData:)]) {
                    [_rescureDelegate didStartRescureCoreData:self];
                }
                
                //Create new store coordinator.
                self.persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.model];
                
                
                if (![self.persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:fileUrl options:options error:&error]) {
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
                    [self.context setPersistentStoreCoordinator:self.persistentStoreCoordinator];
                    if (_rescureDelegate && [_rescureDelegate respondsToSelector:@selector(didFinishedRescuringCoreData:)]) {
                        [_rescureDelegate didFinishedRescuringCoreData:self];
                    }
                }
            }else {
                abort();
            }
        }else {
            [self.context setPersistentStoreCoordinator:self.persistentStoreCoordinator];
        }
        
    }else {
        [self.context setPersistentStoreCoordinator:self.persistentStoreCoordinator];
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
	NSString* className = NSStringFromClass(theClass);
    _object = [NSEntityDescription insertNewObjectForEntityForName:className inManagedObjectContext:self.context];
	if (!_object) {
		NSLog(@"Error: build managed object by class:%@ failed", className);
	}
    return _object;
}

- (NSManagedObject *)buildManagedObjectByClass:(Class)theClass error:(NSError **)error {
	NSManagedObject *_object = nil;
	NSString* className = NSStringFromClass(theClass);
	if (!className) {
        if (*error) {
            *error = [NSError errorWithDomain:[NSString stringWithFormat:@"CoreDataEnvir: class:(%@) name not found.", className] code:0 userInfo:0];
        }
		return nil;
	}

	_object = [NSEntityDescription insertNewObjectForEntityForName:className inManagedObjectContext:self.context];

	if (!_object) {
        if (*error) {
            *error = [NSError errorWithDomain:[NSString stringWithFormat:@"CoreDataEnvir: Insert object of class:(%@) failed", className] code:0 userInfo:0];
        }
		return nil;
	}
	return _object;
}

- (NSEntityDescription *)entityDescriptionByClass:(Class)clazz {
	NSString* name = NSStringFromClass(clazz);
	return [self entityDescriptionByName:name];
}

- (NSEntityDescription *) entityDescriptionByName:(NSString *)className
{
    return [NSEntityDescription entityForName:className inManagedObjectContext:self.context];
}

- (NSUInteger)countForFetchRequest:(NSFetchRequest *)fetchRequest error:(NSError **)error {
	return [self.context countForFetchRequest:fetchRequest error:error];
}

- (NSArray *) fetchItemsByEntityDescriptionName:(NSString *)entityName
{
    NSArray *items = nil;
    
    NSEntityDescription* entity = [self entityDescriptionByName:entityName];
    if (!entity) {
        return nil;
    }

    NSFetchRequest *req = [[NSFetchRequest alloc] init];
    [req setEntity:entity];
    
    NSError *error = nil;
    items = [self.context executeFetchRequest:req error:&error];
    if (error) {
        NSLog(@"%s, error:%@, entityName:%@", __FUNCTION__, error, entityName);
    }
    
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
        [self.persistentStoreCoordinator performBlockAndWait:doWork];
    }else {
        [self.persistentStoreCoordinator lock];
        doWork();
        [self.persistentStoreCoordinator unlock];
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
