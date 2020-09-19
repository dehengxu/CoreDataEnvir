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

#ifndef __CoreDataEnvir__
#define __CoreDataEnvir__

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

extern NSString* CDE_DOMAIN;

@interface CoreDataEnvir : NSObject {
    NSRecursiveLock *__recursiveLock;
}

/// Current work queue
@property (nonatomic, readonly) dispatch_queue_t currentQueue;

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

#pragma mark - Configuration

///Get name of model, which is compiled from name.xcdatamodeld to name.momd
@property (class, readonly) NSString* defaultModelName;

/// db file name
@property (class, readonly) NSString* defaultDatabaseDir;

/// db directory
@property (class, readonly) NSString* defaultDatabaseFileName;

/**
 Register resucrer, recommend using UIApplicationDelegate instance.
 */
@property (class, nonatomic, weak) id<CoreDataRescureDelegate> rescureDelegate;

/// A name of `.xcdatamodeld` file without extension
@property (nonatomic, copy) NSString* modelName;

/**
 Data base file name with extension.
 */
@property (nonatomic, copy) NSString *databaseFileName;


#pragma mark - Initialization

/**
 Creating main instance if current thread is main thread else return an background instance.
 */
+ (CoreDataEnvir *)instance;

/**
 Creating a new instance by default db, momd file name.
 */
+ (CoreDataEnvir *)createInstance;

/**
 Initialize instance with specified db , model file name and default persistent store configuration
 
 @param databaseFileName    db file name.
 @param modelName       Model mapping file name.
 @return CoreDataEnvir instance.
 */
- (id)initWithDatabaseFileName:(NSString * _Nullable)databaseFileName modelFileName:(NSString * _Nullable)modelName;

/**
 Init instance with specified db , model file name.

 Auto create work queue bind to currentQueue
 
 @param databaseFileName    db file name.
 @param modelName       Model mapping file name.
 @param names  NSArray: name list of configuration
 @return CoreDataEnvir instance.
 */
- (id)initWithDatabaseFileName:(NSString * _Nullable)databaseFileName modelFileName:(NSString * _Nullable)modelName forConfigurations:(NSArray<NSString*> * _Nullable)names;

/**
 *  Init coredata enviroment at specified path and with name.
 *
 *  @param fileURL Database file path
 */
- (void)initCoreDataEnvirWithDatabaseFileURL:(NSURL * _Nonnull)fileURL;

#pragma mark - Handle data store

/**
 Save
 */
- (BOOL)saveDataBase;

/**
 Operating on NSManagedObject
 */
- (id)dataItemWithID:(NSManagedObjectID *)objectId;
- (id)updateDataItem:(NSManagedObject *)object;
- (BOOL)deleteDataItem:(NSManagedObject *)aItem;
- (BOOL)deleteDataItemSet:(NSSet *)aItemSet;
- (BOOL)deleteDataItems:(NSArray*)items;

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
- (instancetype)setupPersistentStoreWithURL:(NSURL*)fileURL forConfiguration:(NSString*)name;

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

#endif

