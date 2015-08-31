//
//  NSManagedObject_Background.m
//  CoreDataEnvirSample
//
//  Created by NicholasXu on 15/8/30.
//  Copyright (c) 2015年 Nicholas.Xu. All rights reserved.
//

#import "NSManagedObject_Background.h"
#import "CoreDataEnvir_Background.h"
#import "CoreDataEnvir_Private.h"
#import "NSManagedObject_Convient.h"

@implementation NSManagedObject (Background)

/**
 *  Insert an item.
 *
 *  @return
 */
+ (id)insertItemOnBackground
{
    CoreDataEnvir *db = [CoreDataEnvir backgroundInstance];
    id item = [self insertItemInContext:db];
    return item;
}

/**
 *  Insert an item by block
 *
 *  @param settingBlock
 *
 *  @return
 */
+ (id)insertItemOnBackgroundWithFillingBlock:(void (^)(id item))fillingBlock
{
    id item = [self insertItemOnBackground];
    fillingBlock(item);
    return item;
}

+ (NSArray *)itemsOnBackground
{
    CoreDataEnvir *db = [CoreDataEnvir backgroundInstance];
    NSArray *items = [db fetchItemsByEntityDescriptionName:NSStringFromClass(self)];
    
    return items;
}

+ (NSArray *)itemsOnBackgroundWithPredicate:(NSPredicate *)predicate
{
    CoreDataEnvir *db = [CoreDataEnvir backgroundInstance];
    NSArray *items = [db fetchItemsByEntityDescriptionName:NSStringFromClass(self) usingPredicate:predicate];
    return items;
}

+ (NSArray *)itemsOnBackgroundWithFormat:(NSString *)fmt, ...
{
    va_list args;
    va_start(args, fmt);
    NSPredicate *pred = [NSPredicate predicateWithFormat:fmt arguments:args];
    va_end(args);
    CoreDataEnvir *db = [CoreDataEnvir backgroundInstance];
    NSArray *items = [db fetchItemsByEntityDescriptionName:NSStringFromClass(self) usingPredicate:pred];
    return items;
}

+ (NSArray *)itemsOnBackgroundSortDescriptions:(NSArray *)sortDescriptions withFormat:(NSString *)fmt, ...
{
    va_list args;
    va_start(args, fmt);
    NSPredicate *pred = [NSPredicate predicateWithFormat:fmt arguments:args];
    va_end(args);
    CoreDataEnvir *db = [CoreDataEnvir backgroundInstance];
    NSArray *items = [db fetchItemsByEntityDescriptionName:NSStringFromClass(self) usingPredicate:pred usingSortDescriptions:sortDescriptions];
    return items;
}

+ (NSArray *)itemsOnBackgroundSortDescriptions:(NSArray *)sortDescriptions fromOffset:(NSUInteger)offset limitedBy:(NSUInteger)limitNumber withFormat:(NSString *)fmt, ...
{
    va_list args;
    va_start(args, fmt);
    NSPredicate *pred = [NSPredicate predicateWithFormat:fmt arguments:args];
    va_end(args);
    CoreDataEnvir *db = [CoreDataEnvir backgroundInstance];
    NSArray *items = [db fetchItemsByEntityDescriptionName:NSStringFromClass(self) usingPredicate:pred usingSortDescriptions:sortDescriptions fromOffset:offset LimitedBy:limitNumber];
    return items;
}

+ (id)lastItemOnBackground
{
    return [[self itemsOnBackground] lastObject];
}

+ (NSArray *)lastItemOnBackgroundWithPredicate:(NSPredicate *)predicate
{
    return [[self itemsInContext:[CoreDataEnvir backgroundInstance] usingPredicate:predicate] lastObject];
}

+ (id)lastItemOnBackgroundWithFormat:(NSString *)fmt, ...
{
    va_list args;
    va_start(args, fmt);
    NSPredicate *pred = [NSPredicate predicateWithFormat:fmt arguments:args];
    va_end(args);
    return [self lastItemOnBackgroundWithPredicate:pred];
}

@end
