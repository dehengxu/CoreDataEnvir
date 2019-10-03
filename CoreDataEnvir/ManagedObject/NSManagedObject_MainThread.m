//
//  NSManagedObject_MainThread.m
//  CoreDataEnvirSample
//
//  Created by NicholasXu on 15/8/30.
//  Copyright (c) 2015年 Nicholas.Xu. All rights reserved.
//

#import "NSManagedObject_MainThread.h"
#import "CoreDataEnvir_Private.h"
#import "CoreDataEnvir.h"
#import "CoreDataEnvir_Main.h"

@implementation NSManagedObject (MainThread)

/**
 *  Insert an item.
 *
 *  @return
 */
+ (instancetype)insertItem
{
    if (![NSThread isMainThread]) {
#if DEBUG
        NSLog(@"Insert item record failed, please run on main thread!");
#endif
        [[NSException exceptionWithName:@"CoreDataEnviroment" reason:@"Insert item record failed, must run on main thread!" userInfo:nil] raise];
        return nil;
    }
    CoreDataEnvir *db = [CoreDataEnvir mainInstance];
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
+ (instancetype)insertItemWithFillingBlock:(void (^)(id item))fillingBlock
{
    id item = [self insertItem];
    fillingBlock(item);
    return item;
}

+ (NSArray *)items
{
    if (![NSThread isMainThread]) {
#if DEBUG
        NSLog(@"Fetch all items record failed, please run on main thread!");
#endif
        [[NSException exceptionWithName:@"CoreDataEnviroment" reason:@"Fetch all items record failed, must run on main thread!" userInfo:nil] raise];
        return nil;
    }
    CoreDataEnvir *db = [CoreDataEnvir mainInstance];
    NSArray *items = [db fetchItemsByEntityDescriptionName:NSStringFromClass(self)];
    
    return items;
}

+ (NSArray *)itemsWithPredicate:(NSPredicate *)predicate
{
    if (![NSThread isMainThread]) {
#if DEBUG
        NSLog(@"Fetch item record failed, please run on main thread!");
#endif
        [[NSException exceptionWithName:@"CoreDataEnviroment" reason:@"Fetch item record failed, must run on main thread!" userInfo:nil] raise];
        return nil;
    }
    CoreDataEnvir *db = [CoreDataEnvir mainInstance];
    NSArray *items = [db fetchItemsByEntityDescriptionName:NSStringFromClass(self) usingPredicate:predicate];
    return items;
}

+ (NSArray *)itemsWithFormat:(NSString *)fmt, ...
{
    if (![NSThread isMainThread]) {
#if DEBUG
        NSLog(@"Fetch item record failed, please run on main thread!");
#endif
        [[NSException exceptionWithName:@"CoreDataEnviroment" reason:@"Fetch item record failed, must run on main thread!" userInfo:nil] raise];
        return nil;
    }
    
    va_list args;
    va_start(args, fmt);
    NSPredicate *pred = [NSPredicate predicateWithFormat:fmt arguments:args];
    va_end(args);
    CoreDataEnvir *db = [CoreDataEnvir mainInstance];
    NSArray *items = [db fetchItemsByEntityDescriptionName:NSStringFromClass(self) usingPredicate:pred];
    return items;
}

+ (NSArray *)itemsSortDescriptions:(NSArray *)sortDescriptions withFormat:(NSString *)fmt, ...
{
    if (![NSThread isMainThread]) {
#if DEBUG
        NSLog(@"Fetch item record failed, please run on main thread!");
#endif
        [[NSException exceptionWithName:@"CoreDataEnviroment" reason:@"Fetch item record failed, must run on main thread!" userInfo:nil] raise];
        return nil;
    }

    va_list args;
    va_start(args, fmt);
    NSPredicate *pred = [NSPredicate predicateWithFormat:fmt arguments:args];
    va_end(args);
    CoreDataEnvir *db = [CoreDataEnvir mainInstance];
    NSArray *items = [db fetchItemsByEntityDescriptionName:NSStringFromClass(self) usingPredicate:pred usingSortDescriptions:sortDescriptions];
    return items;
}

+ (NSArray *)itemsSortDescriptions:(NSArray *)sortDescriptions fromOffset:(NSUInteger)offset limitedBy:(NSUInteger)limitNumber withFormat:(NSString *)fmt, ...
{
    if (![NSThread isMainThread]) {
#if DEBUG
        NSLog(@"Fetch item record failed, please run on main thread!");
#endif
        [[NSException exceptionWithName:@"CoreDataEnviroment" reason:@"Fetch item record failed, must run on main thread!" userInfo:nil] raise];
        return nil;
    }

    va_list args;
    va_start(args, fmt);
    NSPredicate *pred = [NSPredicate predicateWithFormat:fmt arguments:args];
    va_end(args);
    CoreDataEnvir *db = [CoreDataEnvir mainInstance];
    NSArray *items = [db fetchItemsByEntityDescriptionName:NSStringFromClass(self) usingPredicate:pred usingSortDescriptions:sortDescriptions fromOffset:offset LimitedBy:limitNumber];
    return items;
}

+ (instancetype)lastItem
{
    if (![NSThread isMainThread]) {
#if DEBUG
        NSLog(@"Fetch last item record failed, please run on main thread!");
#endif
        [[NSException exceptionWithName:@"CoreDataEnviroment" reason:@"Fetch last item record failed, must run on main thread!" userInfo:nil] raise];
        return nil;
    }
    
    return [[self items] lastObject];
}

+ (NSArray *)lastItemWithPredicate:(NSPredicate *)predicate
{
    if (![NSThread isMainThread]) {
#if DEBUG
        NSLog(@"Fetch last item record failed, please run on main thread!");
#endif
        [[NSException exceptionWithName:@"CoreDataEnviroment" reason:@"Fetch last item record failed, must run on main thread!" userInfo:nil] raise];
        return nil;
    }
    
    return [[self itemsInContext:[CoreDataEnvir mainInstance] usingPredicate:predicate] lastObject];
}

+ (instancetype)lastItemWithFormat:(NSString *)fmt, ...
{
    va_list args;
    va_start(args, fmt);
    NSPredicate *pred = [NSPredicate predicateWithFormat:fmt arguments:args];
    va_end(args);
    return [self lastItemWithPredicate:pred];
}

@end
