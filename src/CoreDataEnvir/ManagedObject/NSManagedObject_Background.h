//
//  NSManagedObject_Background.h
//  CoreDataEnvirSample
//
//  Created by NicholasXu on 15/8/30.
//  Copyright (c) 2015年 Nicholas.Xu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSManagedObject (CDEBackground)

/**
 Creating managed object on main thread.
 */
+ (instancetype)insertItemOnBackground;

/**
 Creating managed object in main context by filling 'block'
 */
+ (instancetype)insertItemOnBackgroundWithFillingBlock:(void(^)(id item))fillingBlock;

/**
 Just fetching record items by the predicate in main context.
 */
+ (NSArray *)itemsOnBackground;

/**
 Fetch record items in main context by predicate.
 */
+ (NSArray *)itemsOnBackgroundWithPredicate:(NSPredicate *)predicate;

/**
 Fetch record items in main context by formated string.
 */
+ (NSArray *)itemsOnBackgroundWithFormat:(NSString *)fmt,...;

/**
 *  Fetch record items in main context by predicate format string more simpler.
 *
 *  @param sortDescriptions SortDescriptions
 *  @param fmt              Predicate format string.
 *
 *  @return Array of items match the condition.
 */
+ (NSArray *)itemsOnBackgroundSortDescriptions:(NSArray *)sortDescriptions withFormat:(NSString *)fmt,...;

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
+ (NSArray *)itemsOnBackgroundSortDescriptions:(NSArray *)sortDescriptions fromOffset:(NSUInteger)offset limitedBy:(NSUInteger)limitNumber withFormat:(NSString *)fmt,...;

/**
 * Fetching last record item.
 */
+ (instancetype)lastItemOnBackground;

/**
 *  Fetch record item by predicate in main context.
 *
 *  @param predicate Predicate object.s
 *
 *  @return Last item of the managed object in context.
 */
+ (instancetype)lastItemOnBackgroundWithPredicate:(NSPredicate *)predicate;

/**
 
 */
/**
 *  Fetch record item by formated string in main context.
 *
 *  @param fmt Predicate format.
 *
 *  @return Last item of the managed object in context.
 */
+ (instancetype)lastItemOnBackgroundWithFormat:(NSString *)fmt,...;

@end

NS_ASSUME_NONNULL_END
