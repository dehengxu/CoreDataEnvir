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

#define CORE_DATA_ENVIR_SHOW_LOG        0

#define CORE_DATA_SHARE_PERSISTANCE     1

#pragma mark - ------------------------------ CoreDataEnvirObserver (not be used temporarily) ---------------------------

@protocol CoreDataEnvirObserver

@optional
- (void)didFetchingFinished:(NSArray *) aItems;
- (void)didUpdateContext:(id)sender;
- (void)didDeleteObjects:(id)sender;
- (void)didInsertObjects:(id)sender;
- (void)didUpdateObjects:(id)sender;

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

/*
 Regist the specific model file name.
 */
+ (void)registModelFileName:(NSString *)name;

/*
 Regist the specific database file name.
 */
+ (void)registDatabaseFileName:(NSString *)name;

/*
 Get model file name.(Name likes: xxxx.mmod in sandbox.)
 */
+ (NSString *)modelFileName;

/*
 Get data base file name.
 */
+ (NSString *)databaseFileName;

/*
 Creating instance conditionally.
 If current thread is main thread return single main instance,else return an temporary new instance.
 */
+ (CoreDataEnvir *)instance;

/*
 Only returen a single instance runs on main thread.
 */
+ (CoreDataEnvir *)mainInstance;

/*
 Creating a new instance.
 */
+ (CoreDataEnvir *)createInstance;

/*
 Release the main instance.
 */
+ (void) deleteInstance;

/*
 Operating on NSManagedObject
 */
- (id)dataItemWithID:(NSManagedObjectID *)objectId;
- (id)updateDataItem:(NSManagedObject *)object;
- (BOOL)deleteDataItem:(NSManagedObject *)aItem;
- (BOOL)deleteDataItemSet:(NSSet *)aItemSet;
- (BOOL)deleteDataItems:(NSArray*)items;
- (BOOL)saveDataBase;

@end

#pragma mark -  NSObject (Debug_Ext)

/*
 NSObject (Debug_Ext)
 */
@interface NSObject (Debug_Ext)

- (NSString *)currentDispatchQueueLabel;

@end

#pragma mark - NSmanagedObject convinent methods.

@interface NSManagedObject (CONVENIENT)

#pragma mark - Operation on main thread.
/*
 Creating managed object on main thread.
 */
+ (id)insertItem;
+ (id)insertItemWithBlock:(void(^)(id item))settingBlock;

/*
 Just fetching record items by the predicate on main thread.
 */
+ (NSArray *)items;
+ (NSArray *)itemsWithPredicate:(NSPredicate *)predicate;
+ (id)lastItem;
+ (id)lastItemWithPredicate:(NSPredicate *)predicate;

/*
 Remove item.
 */
- (void)remove;

/*
 Save db on main thread.
 */
- (BOOL)save;


#pragma mark - Operation on other sperate thread.

/*
 Creating managed object on background thread.
 */
+ (id)insertItemInContext:(CoreDataEnvir *)cde;
+ (id)insertItemInContext:(CoreDataEnvir *)cde fillData:(void (^)(id item))settingBlock;

/*
 Fetching record items by the predicate on background thread.
 */
+ (NSArray *)itemsInContext:(CoreDataEnvir *)cde;
+ (NSArray *)itemsInContext:(CoreDataEnvir *)cde usingPredicate:(NSPredicate *)predicate;
+ (id)lastItemInContext:(CoreDataEnvir *)cde;
+ (id)lastItemInContext:(CoreDataEnvir *)cde usingPredicate:(NSPredicate *)predicate;

/*
 Remove item.
 */
- (void)removeFrom:(CoreDataEnvir *)cde;

/*
 Save db on main thread.
 */
- (BOOL)saveTo:(CoreDataEnvir *)cde;

@end



