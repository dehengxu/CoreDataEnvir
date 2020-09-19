//
//  NSManagedObject_Convient.m
//  CoreDataEnvirSample
//
//  Created by NicholasXu on 15/8/30.
//  Copyright (c) 2015年 Nicholas.Xu. All rights reserved.
//

#import "NSManagedObject_Convenient.h"
#import "CoreDataEnvir_Private.h"
#import "CoreDataEnvir_Main.h"
#import "CoreDataEnvir_Background.h"

@implementation NSManagedObject (CDEConevient)

+ (NSUInteger)totalCountInContext:(CoreDataEnvir *)db forConfiguration:(NSString *)name {
	NSFetchRequest* req = [self newFetchRequestInContext:db];
	if (name.length) {
		NSPersistentStore* store = [db persistentStoreForConfiguration:name];
		req.affectedStores = @[store];
	}
	return [db countForFetchRequest:req error:nil];
}

+ (NSFetchRequest*)newFetchRequestInContext:(CoreDataEnvir*)db {
	NSFetchRequest *req = [[NSFetchRequest alloc] init];
	NSString* name = NSStringFromClass(self.class);
	NSAssert(name.length, @"class name not found.");
	NSEntityDescription *entity = [NSEntityDescription entityForName:name inManagedObjectContext:db.context];
	[req setEntity:entity];
	return req;
}

#pragma mark - Insert item record

+ (instancetype)insertItemInContext:(CoreDataEnvir *)cde
{
    id item = nil;
	NSError* err = nil;
    item = [cde buildManagedObjectByClass:self error:&err];
    return item;
}

+ (instancetype)insertItemInContext:(CoreDataEnvir *)cde fillData:(void (^)(id item))fillingBlock
{
    id item = [self insertItemInContext:cde];
    fillingBlock(item);
    return item;
}

#pragma mark - fetch items

+ (NSArray *)itemsInContext:(CoreDataEnvir *)cde
{
    NSArray *items = [cde fetchItemsByEntityDescriptionName:NSStringFromClass(self)];
    return items;
}

+ (NSArray *)itemsInContext:(CoreDataEnvir *)cde usingPredicate:(NSPredicate *)predicate
{
    NSArray *items = [cde fetchItemsByEntityDescriptionName:NSStringFromClass(self) usingPredicate:predicate];
    return items;
}

+ (NSArray *)itemsInContext:(CoreDataEnvir *)cde withFormat:(NSString *)fmt, ...
{
    va_list args;
    va_start(args, fmt);
    NSPredicate *pred = [NSPredicate predicateWithFormat:fmt arguments:args];
    va_end(args);
    
    NSArray *items = [cde fetchItemsByEntityDescriptionName:NSStringFromClass(self) usingPredicate:pred];
    return items;
}

+ (NSArray *)itemsInContext:(CoreDataEnvir *)cde sortDescriptions:(NSArray *)sortDescriptions withFormat:(NSString *)fmt, ...
{
    va_list args;
    va_start(args, fmt);
    NSPredicate *pred = [NSPredicate predicateWithFormat:fmt arguments:args];
    va_end(args);
    NSArray *items = [cde fetchItemsByEntityDescriptionName:NSStringFromClass(self) usingPredicate:pred usingSortDescriptions:sortDescriptions];
    return items;
}

+ (NSArray *)itemsInContext:(CoreDataEnvir *)cde sortDescriptions:(NSArray *)sortDescriptions fromOffset:(NSUInteger)offset limitedBy:(NSUInteger)limitNumber withFormat:(NSString *)fmt, ...
{
    va_list args;
    va_start(args, fmt);
    NSPredicate *pred = [NSPredicate predicateWithFormat:fmt arguments:args];
    va_end(args);
    NSArray *items = [cde fetchItemsByEntityDescriptionName:NSStringFromClass(self) usingPredicate:pred usingSortDescriptions:sortDescriptions fromOffset:offset LimitedBy:limitNumber];
    return items;
}

#pragma mark - fetch last item

+ (instancetype)lastItemInContext:(CoreDataEnvir *)cde
{
    return [[self itemsInContext:cde] lastObject];
}

+ (instancetype)lastItemInContext:(CoreDataEnvir *)cde usingPredicate:(NSPredicate *)predicate
{
    return [[self itemsInContext:cde usingPredicate:predicate] lastObject];
}

+ (instancetype)lastItemInContext:(CoreDataEnvir *)cde withFormat:(NSString *)fmt, ...
{
    va_list args;
    va_start(args, fmt);
    NSPredicate *pred = [NSPredicate predicateWithFormat:fmt arguments:args];
    va_end(args);
    
    return [[self itemsInContext:cde usingPredicate:pred] lastObject];
}

#pragma mark - merge context when update

- (instancetype)update
{
    if ([NSThread isMainThread]) {
        return [[CoreDataEnvir instance] updateDataItem:self];
    }
    return nil;
}

- (instancetype)updateInContext:(CoreDataEnvir *)cde
{
    return [cde updateDataItem:self];
}

- (void)removeFrom:(CoreDataEnvir *)cde
{
    if (!cde) {
        return;
    }
    [cde deleteDataItem:self];
}

- (void)remove
{
    if (![NSThread isMainThread]) {
#if DEBUG
        NSLog(@"Remove data failed, cannot run on non-main thread!");
#endif
        [[NSException exceptionWithName:@"CoreDataEnviroment" reason:@"Remove data failed, must run on main thread!" userInfo:nil] raise];
        return;
    }
    if (![CoreDataEnvir mainInstance]) {
        return;
    }
    [[CoreDataEnvir mainInstance] deleteDataItem:self];
}

- (BOOL)saveTo:(CoreDataEnvir *)cde
{
    if (!cde) {
        return NO;
    }
    
    return [cde saveDataBase];
}

- (BOOL)save
{
    if (![NSThread isMainThread]) {
#if DEBUG
        NSLog(@"Save data failed, cannot run on non-main thread!");
#endif
        [[NSException exceptionWithName:@"CoreDataEnviroment" reason:@"Save data failed, must run on main thread!" userInfo:nil] raise];
        return NO;
    }
    if (![CoreDataEnvir mainInstance]) {
        return NO;
    }
    
    return [[CoreDataEnvir mainInstance] saveDataBase];
}

- (BOOL)saveTo:(CoreDataEnvir *)cde forConfiguration:(NSString *)name {
	NSPersistentStore* store = [cde persistentStoreForConfiguration:name];
	[cde.context assignObject:self toPersistentStore:store];
	[cde saveDataBase];
	return NO;
}

@end
