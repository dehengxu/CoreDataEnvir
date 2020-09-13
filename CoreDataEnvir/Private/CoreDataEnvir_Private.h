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
extern CoreDataEnvir *_backgroundInstance;
extern CoreDataEnvir *_coreDataEnvir;
//static dispatch_queue_t _backgroundQueue = nil;
static unsigned int _create_counter = 0;

@interface CoreDataEnvir (CDEPrivate)

/**
 Rename database file with new registed name.
 */
+ (void)_renameDatabaseFile;

- (NSFetchRequest*)newFetchRequest;

/**
 *  Init coredata enviroment at specified path and with name.
 *
 *  @param path Database file directory
 *  @param dbName Database file name
 */
- (void)_initCoreDataEnvirWithPath:(NSString *) path andFileName:(NSString *) dbName;


/**
 Insert a new record into the table by className.
 */
- (NSManagedObject *)buildManagedObjectByName:(NSString *)className;

/**
 *  Insert a new record into the table by Class type.
 *
 *  @param theClass Object class
 *
 *  @return NSManagedObject entity.
 */
- (NSManagedObject *)buildManagedObjectByClass:(Class)theClass;


/**
 Get entity descritpion from name string
 */
- (NSEntityDescription *) entityDescriptionByName:(NSString *)className;

- (NSUInteger)fetchRequestCount;

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
 *  @param notification NSNotification object.
 */
- (void)updateContext:(NSNotification *)notification;

/**
 *  Merge context data while other context occur data changing.
 *
 *  @param notification NSNotification object.
 */
- (void)mergeChanges:(NSNotification *)notification;

/**
 Send processPendingChanges message on non-main thread.
 You should call this method after cluster of actions.
 */
- (void)sendPendingChanges;



@end
