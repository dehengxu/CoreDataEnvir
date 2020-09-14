//
//  CoreDataEnvir_Private.h
//  CoreDataEnvirSample
//
//  Created by NicholasXu on 15/8/30.
//  Copyright (c) 2015年 Nicholas.Xu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CoreDataEnvir.h"

extern id<CoreDataRescureDelegate> _Nullable _rescureDelegate;
extern CoreDataEnvir* _Nullable _backgroundInstance;
extern CoreDataEnvir* _Nullable _mainInstance;
//static dispatch_queue_t _backgroundQueue = nil;
static unsigned int _create_counter = 0;

@interface CoreDataEnvir (CDEPrivate)

/**
 Rename database file with new registed name.
 */
+ (void)_renameDatabaseFile;

- (NSFetchRequest * _Nullable)newFetchRequestWithName:(NSString* _Nullable)name error:(NSError* _Nullable * _Nullable)error;

- (NSFetchRequest * _Nullable)newFetchRequestWithClass:(Class _Nullable)clazz error:(NSError * _Nullable * _Nullable)error;

/**
 *  Init coredata enviroment at specified path and with name.
 *
 *  @param path Database file directory
 *  @param dbName Database file name
 */
- (void)_initCoreDataEnvirWithPath:(NSString * _Nonnull) path andFileName:(NSString * _Nonnull) dbName;


/**
 Insert a new record into the table by className.
 */
- (NSManagedObject * _Nullable)buildManagedObjectByName:(NSString * _Nonnull)className;

/**
 *  Insert a new record into the table by Class type.
 *
 *  @param theClass Object class
 *
 *  @return NSManagedObject entity.
 */
- (NSManagedObject * _Nullable)buildManagedObjectByClass:(Class _Nonnull)theClass NS_DEPRECATED_IOS(4.0, 10.0, "Replace with: - (NSManagedObject* _Nullable)buildManagedObjectByClass:(Class _Nullable)theClass error:(NSError* _Nullable * _Nullable)error;");

/// Insert a new record into the table by Class type.
/// @param theClass Object class
/// @param error NSError with failed information.
- (NSManagedObject* _Nullable)buildManagedObjectByClass:(Class _Nonnull)theClass error:(NSError* _Nullable * _Nullable)error;

/// Create entity from a 'Class' object
/// @param clazz Class object
- (NSEntityDescription * _Nullable) entityDescriptionByClass:(Class _Nullable)clazz;

/**
 Get entity descritpion from name string
 */
- (NSEntityDescription * _Nullable) entityDescriptionByName:(NSString *_Nullable)className;

- (NSUInteger)countForFetchRequest:(NSFetchRequest* _Nonnull)fetchRequest error:(NSError* _Nullable * _Nullable)error;

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
