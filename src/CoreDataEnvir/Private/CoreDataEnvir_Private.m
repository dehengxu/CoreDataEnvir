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
long _create_counter = 0;

@implementation CoreDataEnvir (CDEPrivate)

//+ (void)_renameDatabaseFile
//{
//    NSFileManager *fm = [NSFileManager defaultManager];
//    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
//    NSString *checkName = nil;
//    
//    NSArray *contents = [fm contentsOfDirectoryAtPath:path error:nil];
//    
//    for (NSString *name in contents) {
//        if ([name rangeOfString:@"."].location == 0) {
//            continue;
//        }
//        if ([name isEqualToString:[[self mainInstance] databaseFileName]]) {
//            break;
//        }
//        checkName = [NSString stringWithFormat:@"%@/%@", path, name];
//        
//        BOOL isDir = NO;
//        if ([fm fileExistsAtPath:checkName isDirectory:&isDir] && !isDir && [[name pathExtension] isEqualToString:@"sqlite"]) {
//            [fm moveItemAtPath:checkName toPath:[NSString stringWithFormat:@"%@/%@", path, [[self mainInstance] databaseFileName]] error:nil];
//            NSLog(@"Rename sqlite database from %@ to %@ finished!", name, [[self mainInstance] databaseFileName]);
//            break;
//        }
//    }
//    NSLog(@"No sqlite database be renamed!");
//}

- (NSDictionary *)defaultPersistentOptions {
    NSDictionary *options = @{
        NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES
    };
    return options;
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

- (NSManagedObject *) buildManagedObjectByName:(NSString *)className error:(NSError *__autoreleasing  _Nullable * _Nullable)error
{
    NSManagedObject *_object = nil;
    _object = [NSEntityDescription insertNewObjectForEntityForName:className inManagedObjectContext:self.context];
	if (!_object) {
		NSString* msg = [NSString stringWithFormat:@"Error(%@): Insert object of class:(%@) failed", CDE_DOMAIN, className];
		if (*error) {
			*error = [NSError errorWithDomain:msg code:0 userInfo:nil];
		}
		NSAssert(false, msg);
		return nil;
	}

    return _object;
}

- (NSManagedObject *)buildManagedObjectByClass:(Class)theClass error:(NSError **)error {
	NSManagedObject *_object = nil;
	NSString* className = NSStringFromClass(theClass);
	if (!className) {
		NSString* msg = [NSString stringWithFormat:@"Error(%@): class: \"%@\" name not found.", CDE_DOMAIN, className];
        if (*error) {
            *error = [NSError errorWithDomain:msg code:0 userInfo:0];
        }
		NSAssert(false, msg);
		return nil;
	}

	_object = [self buildManagedObjectByName:className error:error];
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
