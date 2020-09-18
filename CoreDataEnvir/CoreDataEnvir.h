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

#define CORE_DATA_ENVIR_SHOW_LOG        0

//! Project version number for CoreDataEnvir.
FOUNDATION_EXPORT double CoreDataEnvirVersionNumber;

//! Project version string for CoreDataEnvir.
FOUNDATION_EXPORT const unsigned char CoreDataEnvirVersionString[];

NS_ASSUME_NONNULL_BEGIN

@class CoreDataEnvir;

#pragma mark - CoreDataEnvirObserver (Not be used temporarily)

@protocol CoreDataEnvirObserver

@optional
- (void)didFetchingFinished:(NSArray *) aItems;
- (void)didUpdateContext:(id)sender;
- (void)didDeleteObjects:(id)sender;
- (void)didInsertObjects:(id)sender;
- (void)didUpdateObjects:(id)sender;

@end


#pragma mark - CoreDataRescureDelegate

/**
 CoreData rescure delegate.
 While core data envirement init fails occured.
 */
@protocol CoreDataRescureDelegate <NSObject>

@optional

/**
 Reture if need rescure or abort directly.
 */
- (BOOL)shouldRescureCoreData;

/**
 Return if abort while rescure failed.
 */
- (BOOL)shouldAbortWhileRescureFailed;

/**
 Did start rescure core data.
 
 @param cde A CoreDataEnvir instance.
 */
- (void)didStartRescureCoreData:(CoreDataEnvir *)cde;

/**
 Did finished rescuring work.
 
 @param cde A CoreDataEnvir instance.
 */
- (void)didFinishedRescuringCoreData:(CoreDataEnvir *)cde;

/**
 Rescure failed.
 
 @param cde A CoreDataEnvir instance.
 */
- (void)rescureFailed:(CoreDataEnvir *)cde;

@end


#pragma mark - CoreDataEnvirement

typedef enum
{
    CDEErrorInstanceCreateTooMutch = 1000,
	CDEErrorModelFileNotFound = 1001
}CoreDataEnvirError;

extern NSString* CDE_ERROR_DOMAIN;

@interface CoreDataEnvir : NSObject {
    NSRecursiveLock *__recursiveLock;
@public
    dispatch_queue_t _currentQueue;
}

/**
 A model object.
 */
@property (nonatomic, readonly) NSManagedObjectModel	*model;

/**
 A context object.
 */
@property (nonatomic, readonly) NSManagedObjectContext *context;

/**
 A persistance coordinator object.
 */
@property (nonatomic, readonly) NSPersistentStoreCoordinator *storeCoordinator;

/**
 A NSFetchedResultsController object, not be used by now.
 */
@property (nonatomic, retain) NSFetchedResultsController * fetchedResultsCtrl;

/**
 Model file name. It normally be name.momd
 */
@property (nonatomic, copy, setter = registerModelFileName:, getter = modelFileName) NSString *modelFileName;


///
/// modelFilePath = "Bundle path" + modelFileName
///
@property (nonatomic, class, copy, setter = registerModelFilePath:, getter = modelFilePath) NSString* modelFilePath;

/**
 Data base file name. It can be whatever you want.
 */
@property (nonatomic, copy, setter = registerDatabaseFileName:, getter = databaseFileName) NSString *databaseFileName;

/**
 Data file root path.
 */
@property (nonatomic, copy, setter = registerDataFileRootPath:, getter = dataRootPath) NSString *dataRootPath;

/**
 Data rescure when CoreData envirement init occurs error.
 */
//@property (nonatomic, assign) id<CoreDataRescureDelegate> rescureDelegate;

/**
 Triggle to enable persistance shared.
 
 If you wanna create another db file storage, you should
 set this flag to YES or set to NO.
 
 Commonly , you should set this flag to YES.
 
 YES: Multi context shared same persistence file.
 NO: Every context has own persistence file.

 If share persistence coordinator.
 Default is YES;
 
 */
@property (nonatomic) BOOL sharePersistence;

/**
 Register the specified model file name exclude extension.
 Default: "Model"
 @prarm name    xcdatamodeld file name.(Exclude file extension.)
 */
+ (void)registerDefaultModelFileName:(NSString *)name;

/// Register
/// @param fielPath absolute file path for out of main bundle
+ (void)registerModelFilePath:(NSString *)fielPath;

/**
 Register the specified data file name.
 Default: "db.sqlite"
 @param name    Data file name.(Exclude path name.)
 */
+ (void)registerDefaultDataFileName:(NSString *)name;

/**
 Register the specified path as data file root.
 
 @param path    Data file root path.
 */
+ (void)registerDefaultDataFileRootPath:(NSString *)path;

/**
 Register resucrer, recommend using UIApplicationDelegate instance.
 
 @param delegate    Rescure delegate
 */
+ (void)registerRescureDelegate:(id<CoreDataRescureDelegate>)delegate;

/**
 Get model file name.(Name likes: xxxx.momd in sandbox.)
 */
+ (NSString *)defaultModelFileName;

/// Get model file path with extension ".momd"
+ (NSString *)defaultModelFilePath;

/**
 Get data base file name.
 */
+ (NSString *)defaultDatabaseFileName;

/**
 Creating instance conditionally.
 If current thread is main thread return single main instance,else return an temporary new instance.
 */
+ (CoreDataEnvir *)instance;

/**
 Create an CoreDataEnvir instance by specified db file name and momd file name.
 The momd file name is a middle file generated by XCode handle xcdatamodeld file.
 
 @param databaseFileName    A specified db file name.
 @param modelFileName       A specified momd file name.
 */
+ (CoreDataEnvir *)createInstanceWithDatabaseFileName:(NSString *)databaseFileName modelFileName:(NSString *)modelFileName;

/**
 Creating a new instance by default db, momd file name.
 */
+ (CoreDataEnvir *)createInstance;

+ (CoreDataEnvir *)createInstanceShareingPersistence:(BOOL)isSharePersistence;

/**
 Return data root path
 */
+ (NSString *)dataRootPath;

/**
 Init instance with specified db , model file name.
 
 @param databaseFileName    db file name.
 @param modelFileName       Model mapping file name.
 @return CoreDataEnvir instance.
 */
- (id)initWithDatabaseFileName:(NSString *)databaseFileName modelFileName:(NSString *)modelFileName;

/**
 Init instance with specified db , model file name.
 
 @param databaseFileName    db file name.
 @param modelFileName       Model mapping file name.
 @param isSharePersistence  Share persistence or not.
 @return CoreDataEnvir instance.
 */
- (id)initWithDatabaseFileName:(NSString *)databaseFileName modelFileName:(NSString *)modelFileName sharingPersistence:(BOOL)isSharePersistence;

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

- (dispatch_queue_t)currentQueue;

- (void)asyncInBlock:(void(^)(CoreDataEnvir *db))CoreDataBlock;
- (void)syncInBlock:(void(^)(CoreDataEnvir *db))CoreDataBlock;

+ (void)asyncMainInBlock:(void(^)(CoreDataEnvir *db))CoreDataBlock;
+ (void)asyncBackgroundInBlock:(void(^)(CoreDataEnvir *db))CoreDataBlock;

@end

NS_ASSUME_NONNULL_END
