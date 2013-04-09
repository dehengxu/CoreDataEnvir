//
//  CoreDataEnvir.h
//  CoreDataLab
//
//	CoreData enviroment.
//	Support CoreData operating methods.
//	
//	Create record item.
//	Support concurrency operating.
//
//  Created by NicholasXu on 11-5-25.
//  Copyright 2011 NicholasXu. All rights reserved.
//


#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

#define CORE_DATA_ENVIR_SHOW_LOG        1

#define CORE_DATA_SHARE_PERSISTANCE     1

#pragma mark - ------------------------------ CoreDataEnvirDelegate (not be used temporarily) ---------------------------

@protocol CoreDataEnvirDelegate

@optional
- (void)didFetchingFinished:(NSArray *) aItems;
- (void)didUpdatedContext:(NSManagedObjectContext *)aContext;
//- (void)didDeleteObjects:(NSSet *)deletedObjects;
//- (void)didInsertObjects:(NSSet *)insertedObjects;
- (void)didUpdateObjects:(NSNotification *)notify;

@end

#pragma mark - ------------------------------ CoreDataEnvirement -----------------------

@interface CoreDataEnvir : NSObject <NSFetchedResultsControllerDelegate> {
	NSManagedObjectModel * model;
	NSManagedObjectContext * context;
	NSFetchedResultsController * fetchedResultsCtrl;
	
    NSRecursiveLock *recursiveLock;
}
@property (nonatomic, retain) NSManagedObjectModel	*model;
@property (nonatomic, readonly) NSManagedObjectContext *context;

#if !CORE_DATA_SHARE_PERSISTANCE
@property (nonatomic, retain) NSPersistentStoreCoordinator *storeCoordinator;
#endif

@property (nonatomic, retain) NSFetchedResultsController * fetchedResultsCtrl;

@property (nonatomic, assign) NSObject<CoreDataEnvirDelegate> *delegate;

/**
 Regist the specific model file name.
 */
+ (void)registModelFileName:(NSString *)name;

/**
 Regist the specific database file name.
 */
+ (void)registDatabaseFileName:(NSString *)name;

/**
 Rename database file with new registed name.
 */
+ (void)renameDatabaseFile;

/**
 Get model file name.(Name likes: xxxx.mmod in sandbox.)
 */
+ (NSString *)modelFileName;

/**
 Get data base file name.
 */
+ (NSString *)databaseFileName;

/*
 Creating instance conditionally. 
 If current thread is main thread return single main instance,else return an temporary new instance.
 */
+ (CoreDataEnvir *)instance;

/**
 Only returen a single instance belongs to main thread.
 */
+ (CoreDataEnvir *)sharedInstance;

/**
 Force creating a new instance.
 */
+ (CoreDataEnvir *)dataBase;

/**
 Release the main instance.
 */
+ (void) deleteInstance;

/**
 Insert a new record into the table by className.
 */
- (NSManagedObject *)buildManagedObjectByName:(NSString *)className;
- (NSManagedObject *)buildManagedObjectByClass:(Class)theClass;

//Fetching record item.
- (NSArray *)fetchItemsByEntityDescriptionName:(NSString *)entityName;
- (NSArray *)fetchItemsByEntityDescriptionName:(NSString *)entityName usingPredicate:(NSPredicate *) predicate;
- (NSArray *)fetchItemsByEntityDescriptionName:(NSString *)entityName usingPredicate:(NSPredicate *)predicate usingSortDescriptions:(NSArray *)sortDescriptions;
- (NSArray *)fetchItemsByEntityDescriptionName:(NSString *)entityName usingPredicate:(NSPredicate *) predicate usingSortDescriptions:(NSArray *)sortDescriptions fromOffset:(NSUInteger) aOffset LimitedBy:(NSUInteger)aLimited;

//Get entity descritpion from name string
- (NSEntityDescription *) entityDescriptionByName:(NSString *)className;

//Operating on NSManagedObject
- (id)dataItemWithID:(NSManagedObjectID *)objectId;
- (id)updateDataItem:(NSManagedObject *)object;
- (BOOL)deleteDataItem:(NSManagedObject *)aItem;
- (BOOL)deleteDataItemSet:(NSSet *)aItemSet;
- (BOOL)deleteDataItems:(NSArray*)items;
- (BOOL)saveDataBase;

//Add observing for concurrency.
- (void)registerObserving;
- (void)unregisterObserving;

- (void)updateContext:(NSNotification *)notification;
- (void)mergeChanges:(NSNotification *)notification;
- (void)handleDidChange:(NSNotification*)notification;

/*
 Send processPendingChanges message on non-main thread.
 You should call this method after cluster of actions.
 */
- (void)sendPendingChanges;

@end

#pragma mark -  NSObject (Debug_Ext)

/*
 NSObject (Debug_Ext) 
 */
@interface NSObject (Debug_Ext)

- (NSString *)currentDispatchQueueLabel;

@end

#pragma mark - NSmanagedObject convinent methods.

@interface NSManagedObject (EASY_WAY)

#pragma mark - insert record item.
//Creating managed object on main thread.
+ (id)insertItem;
+ (id)insertItemWithBlock:(void(^)(id item))settingBlock;

//Creating managed object on background thread.
+ (id)insertItemWith:(CoreDataEnvir *)cde;
+ (id)insertItemWith:(CoreDataEnvir *)cde fillData:(void (^)(id item))settingBlock;

#pragma mark - fetching record items.
//Just fetching record items by the predicate on main thread.
+ (NSArray *)itemsWith:(NSPredicate *)predicate;
+ (id)lastItemWith:(NSPredicate *)predicate;

//Fetching record items by the predicate on background thread.
+ (NSArray *)itemsWith:(CoreDataEnvir *)cde predicate:(NSPredicate *)predicate;
+ (id)lastItemWith:(CoreDataEnvir *)cde predicate:(NSPredicate *)predicate;

- (void)removeFrom:(CoreDataEnvir *)cde;
- (void)remove;

@end



