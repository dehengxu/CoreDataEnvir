//
//  CoreDataEnvir.h
//  CoreDataLab
//
//	CoreData enviroment light wrapper.
//	Support CoreData operating methods.
//
//	Create record item.
//	Support concurrency operating.
//
//  Created by NicholasXu on 11-5-25.
//
//  mailto:dehengxu@outlook.com
//
//  Copyright 2011 NicholasXu. All rights reserved.
//


#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

//#ifndef __CoreDataEnvir__
//#define __CoreDataEnvir__

#define CORE_DATA_ENVIR_SHOW_LOG        0

@protocol CoreDataRescureDelegate;

//! Project version number for CoreDataEnvir.
FOUNDATION_EXPORT double CoreDataEnvirVersionNumber;

//! Project version string for CoreDataEnvir.
FOUNDATION_EXPORT const unsigned char CoreDataEnvirVersionString[];

NS_ASSUME_NONNULL_BEGIN

#pragma mark - CoreDataEnvirement

typedef enum
{
    CDEErrorInstanceCreateTooMutch = 1000,
	CDEErrorModelFileNotFound = 1001
}CoreDataEnvirError;

extern NSString* const CDE_DOMAIN;

@interface CoreDataEnvir : NSObject {
    NSRecursiveLock *__recursiveLock;
}

/// Current work queue
#if OS_OBJECT_USE_OBJC
@property (nonatomic, strong) dispatch_queue_t currentQueue;
#else
@property (nonatomic, assign) dispatch_queue_t currentQueue;
#endif

/**
 A model object.
 */
@property (nonatomic, readonly) NSManagedObjectModel *model;

/**
 A context object.
 */
@property (nonatomic, readonly) NSManagedObjectContext *context;

/**
 A persistance coordinator object.
 */
@property (nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;

/**
 A NSFetchedResultsController object, not be used by now.
 */
@property (nonatomic, strong) NSFetchedResultsController * fetchedResultsCtrl;

/**
 Register resucrer, recommend using UIApplicationDelegate instance.
 */
@property (class, nonatomic, weak) id<CoreDataRescureDelegate> rescureDelegate;

#pragma mark - Initialization

/**
 Creating main instance if current thread is main thread else return an background instance.
 */
+ (CoreDataEnvir *)instance;

/**
 Creating a new instance by default db, momd file name.
 */
+ (CoreDataEnvir *)createInstance;

#pragma mark - Handle data store

/**
 Save
 */
- (BOOL)saveDataBase;

- (BOOL)saveForConfiguration:(NSString*)name;

/**
 Operating on NSManagedObject
 */
- (id)dataItemWithID:(NSManagedObjectID *)objectId;
- (id)updateDataItem:(NSManagedObject *)object;
- (BOOL)deleteDataItem:(NSManagedObject *)aItem;
- (BOOL)deleteDataItemSet:(NSSet *)aItemSet;
- (BOOL)deleteDataItems:(NSArray*)items;
- (BOOL)deleteDataIDs:(NSArray *)IDs API_AVAILABLE(macosx(10.11), ios(9.0));
- (BOOL)insertDataIntoEntity:(NSEntityDescription *)entity withItems:(NSArray<NSDictionary<NSString*, id> *> *)items API_AVAILABLE(macosx(10.15),ios(13.0),tvos(13.0),watchos(6.0));

#pragma mark - Observing context

/**
 Add observing for concurrency.
 */
- (void)registerObserving;

/**
 *  Remove observer.
 */
- (void)unregisterObserving;


#pragma mark - Work queue relevant

/// run block asynchronously without saving context
/// @param CoreDataBlock A block passing CoreDataEnvir instance
- (void)asyncWithBlock:(void(^)(CoreDataEnvir *db))CoreDataBlock;

/// run block synchronously without saving context
/// @param CoreDataBlock A block passing CoreDataEnvir instance
- (void)syncWithBlock:(void(^)(CoreDataEnvir *db))CoreDataBlock;

#pragma mark - NewAPIs initialization

typedef void(^CoreDataEnvirBlock)(CoreDataEnvir* _Nonnull);

/// Create instance with private work queue
+ (instancetype)create;

/// Create instance and bind work queue with main queue
+ (instancetype)createMain;

#pragma mark - NewAPIs setup CoreData requires

/// Setup CoreData with reusable block
/// @param config Block
- (instancetype)setupWithBlock:(CoreDataEnvirBlock _Nonnull)config;

/// Setup model and context
/// @param fileURL model path
- (instancetype)setupModelWithURL:(NSURL*)fileURL;

/// Setup persistent with default configuration
/// @param fileURL Store file path
- (instancetype)setupDefaultPersistentStoreWithURL:(NSURL*)fileURL;

/// Setup persistent for configuration
/// @param fileURL Store file path
/// @param name Configuration
- (instancetype)setupPersistentStoreWithURL:(NSURL*)fileURL forConfiguration:(NSString* _Nullable)name;

/// Return persistent store from persistent store coordinator
/// @param fileURL Persistent store location
- (NSPersistentStore*)persistentStoreForURL:(NSURL*)fileURL;

/// Return persistent store from persistent store coordinator
/// @param name Configuration
- (NSPersistentStore*)persistentStoreForConfiguration:(NSString*)name;

@end

#pragma mark - NSPersistentStoreCoordinator

@interface NSPersistentStoreCoordinator (CoreDataEnvir)

/// Return persistent store from persistent store coordinator
/// @param name Configuration
- (NSPersistentStore *)persistentStoreForConfiguration:(NSString *)name;

@end

NS_ASSUME_NONNULL_END

//#endif

