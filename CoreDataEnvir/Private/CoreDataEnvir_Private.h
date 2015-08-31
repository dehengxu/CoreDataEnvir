//
//  CoreDataEnvir_Private.h
//  CoreDataEnvirSample
//
//  Created by NicholasXu on 15/8/30.
//  Copyright (c) 2015年 Nicholas.Xu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CoreDataEnvir.h"

static id<CoreDataRescureDelegate> _rescureDelegate = nil;
static CoreDataEnvir *_backgroundInstance = nil;
static CoreDataEnvir *_coreDataEnvir = nil;
//static dispatch_queue_t _backgroundQueue = nil;
static unsigned int _create_counter = 0;

@interface CoreDataEnvir (Private)

/**
 Rename database file with new registed name.
 */
+ (void)_renameDatabaseFile;

/**
 *  Init coredata enviroment at specified path and with name.
 *
 *  @param path
 *  @param dbName
 */
- (void)_initCoreDataEnvirWithPath:(NSString *) path andFileName:(NSString *) dbName;


/**
 Insert a new record into the table by className.
 */
- (NSManagedObject *)buildManagedObjectByName:(NSString *)className;

/**
 *  Insert a new record into the table by Class type.
 *
 *  @param theClass
 *
 *  @return
 */
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

/**
 *  Remove observer.
 */
- (void)unregisterObserving;

/**
 *  Update context while data changes.
 *
 *  @param notification
 */
- (void)updateContext:(NSNotification *)notification;

/**
 *  Merge context data while other context occur data changing.
 *
 *  @param notification 
 */
- (void)mergeChanges:(NSNotification *)notification;

/**
 Send processPendingChanges message on non-main thread.
 You should call this method after cluster of actions.
 */
- (void)sendPendingChanges;



@end
