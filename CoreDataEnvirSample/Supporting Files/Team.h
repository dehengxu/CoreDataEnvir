//
//  Team.h
//  CoreDataEnvirSample
//
//  Created by Deheng.Xu on 13-9-26.
//  Copyright (c) 2013年 Nicholas.Xu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Member;

@interface Team : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * number;
@property (nonatomic, retain) NSSet *members;
@end

@interface Team (CoreDataGeneratedAccessors)

- (void)addMembersObject:(Member *)value;
- (void)removeMembersObject:(Member *)value;
- (void)addMembers:(NSSet *)values;
- (void)removeMembers:(NSSet *)values;
@end
