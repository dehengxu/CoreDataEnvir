//
//  CoreDataEnvir.h
//  CoreDataLab
//
//	数据库环境
//	提供了CoreData数据库操作的常用方法的封装
//	
//	构建实体对象
//	同步，异步取回数据
//	设置读取偏移和读取数量
//
//  Created by NicholasXu on 11-5-25.
//  Copyright 2011 NicholasXu. All rights reserved.
//


#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

#define CORE_DATA_ENVIR_SHOW_LOG        0

#define CORE_DATA_SHARE_PERSISTANCE     1

#pragma mark - ------------------------------ CoreDataEnvirDelegate (not be used temporarily) ---------------------------

@protocol CoreDataEnvirDelegate

- (void)didFetchingFinished:(NSArray *) aItems;
- (void)didUpdatedContext:(NSManagedObjectContext *)aContext;

@end

#pragma mark - ------------------------------ CoreDataEnvirement -----------------------

@interface CoreDataEnvir : NSObject <NSFetchedResultsControllerDelegate> {
	NSManagedObjectModel * model;
	NSManagedObjectContext * context;
	NSFetchedResultsController * fetchedResultsCtrl;
	
    NSRecursiveLock *recursiveLock;

	id<CoreDataEnvirDelegate> delegate;
}
@property (nonatomic, retain) NSManagedObjectModel	*model;
@property (nonatomic, readonly) NSManagedObjectContext *context;

#if !CORE_DATA_SHARE_PERSISTANCE
@property (nonatomic, retain) NSPersistentStoreCoordinator *storeCoordinator;
#endif

@property (nonatomic, retain) NSFetchedResultsController * fetchedResultsCtrl;

@property (nonatomic, assign) id<CoreDataEnvirDelegate> delegate;

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
 If current is main thread return single main instance,
 else return an temporary instance.
 */
+ (CoreDataEnvir *)instance;

/**
 Returen a single main instance.
 */
+ (CoreDataEnvir *)sharedInstance;

/**
 Return a new instance.
 */
+ (CoreDataEnvir *)dataBase;

/**
 Release the main instance.
 */
+ (void) deleteInstance;


/**
 Insert a new record into the table of className.
 */
- (NSManagedObject *) buildManagedObjectByName:(NSString *)className;

//synchronous fetching method
- (NSArray *)fetchItemsByEntityDescriptionName:(NSString *)entityName;
- (NSArray *)fetchItemsByEntityDescriptionName:(NSString *)entityName usingPredicate:(NSPredicate *) predicate;
- (NSArray *)fetchItemsByEntityDescriptionName:(NSString *)entityName usingPredicate:(NSPredicate *)predicate usingSortDescriptions:(NSArray *)sortDescriptions;
- (NSArray *)fetchItemsByEntityDescriptionName:(NSString *)entityName usingPredicate:(NSPredicate *) predicate usingSortDescriptions:(NSArray *)sortDescriptions fromOffset:(NSUInteger) aOffset LimitedBy:(NSUInteger)aLimited;

//get entity descritpion from name string
- (NSEntityDescription *) entityDescriptionByName:(NSString *)className;

//operate on NSManagedObject
- (id)dataItemWithID:(NSManagedObjectID *)objectId;
- (id)updateDataItem:(NSManagedObject *)object;
- (BOOL)deleteDataItem:(NSManagedObject *)aItem;
- (BOOL)deleteDataItemSet:(NSSet *)aItemSet;
- (BOOL)deleteDataItems:(NSArray*)items;
- (BOOL)saveDataBase;

- (void)registerObserving;
- (void)unregisterObserving;

- (void)updateContext:(NSNotification *)notification;
- (void)mergeChanges:(NSNotification *)notification;
- (void)handleDidChange:(NSNotification*)notification;

@end

#pragma mark - --------------------------------    NSObject (Debug_Ext)     --------------------------------

/*
 NSObject (Debug_Ext) 
 */
@interface NSObject (Debug_Ext)

- (NSString *)currentDispatchQueueLabel;

@end



