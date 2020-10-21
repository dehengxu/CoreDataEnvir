//
//  NSManagedObject_MainThread.h
//  CoreDataEnvirSample
//
//  Created by NicholasXu on 15/8/30.
//  Copyright (c) 2015年 Nicholas.Xu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSManagedObject (CDEMainThread)

#pragma mark - Inserting operations.

/**
 Creating managed object on main thread.
 */
+ (instancetype _Nullable)insertItem;

/**
 Creating managed object in main context by filling 'block'
 */
+ (instancetype _Nullable)insertItemWithFillingBlock:(void(^)(NSManagedObject* _Nullable item))fillingBlock;

+ (NSUInteger)totalCount;

/**
 Just fetching record items by the predicate in main context.
 */
+ (NSArray * _Nullable)items;

+ (NSArray * _Nullable)itemsOffset:(NSUInteger)offset withLimit:(NSUInteger)limitNumber;

/**
 Fetch record items in main context by predicate.
 */
+ (NSArray * _Nullable)itemsWithPredicate:(NSPredicate *)predicate;

/**
 Fetch record items in main context by formated string.
 */
+ (NSArray * _Nullable)itemsWithFormat:(NSString *)fmt,...;

/**
 *  Fetch record items in main context by predicate format string more simpler.
 *
 *  @param sortDescriptions SortDescriptions
 *  @param fmt              Predicate format string.
 *
 *  @return Array of items match the condition.
 */
+ (NSArray * _Nullable)itemsSortDescriptions:(NSArray *)sortDescriptions withFormat:(NSString *)fmt,...;

/**
 *  Fetch record items in main context by predicate format string more simpler.
 *
 *  @param sortDescriptions SortDescriptions
 *  @param offset           offset
 *  @param limitNumber       limit number
 *  @param fmt              predicate format string.
 *
 *  @return Array of items match the condition.
 */
+ (NSArray * _Nullable)itemsSortDescriptions:(NSArray *)sortDescriptions fromOffset:(NSUInteger)offset limitedBy:(NSUInteger)limitNumber withFormat:(NSString *)fmt,...;

+ (NSArray * _Nullable)itemsWithSortDescriptions:(NSArray * _Nullable)sortDescriptions fromOffset:(NSUInteger)offset limitedBy:(NSUInteger)limitNumber andPredicate:(NSPredicate* _Nullable)predicate;

/**
 * Fetching last record item.
 */
+ (instancetype _Nullable)lastItem;

/**
 *  Fetch record item by predicate in main context.
 *
 *  @param predicate Predicate object.s
 *
 *  @return Last item of the managed object in context.
 */
+ (instancetype _Nullable)lastItemWithPredicate:(NSPredicate *)predicate;

/**
 
 */
/**
 *  Fetch record item by formated string in main context.
 *
 *  @param fmt Predicate format.
 *
 *  @return Last item of the managed object in context.
 */
+ (instancetype _Nullable)lastItemWithFormat:(NSString *)fmt,...;

@end

NS_ASSUME_NONNULL_END
