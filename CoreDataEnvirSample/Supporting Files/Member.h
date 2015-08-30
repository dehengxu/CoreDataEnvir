//
//  Member.h
//  CoreDataEnvirSample
//
//  Created by Deheng.Xu on 13-9-26.
//  Copyright (c) 2013年 Nicholas.Xu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Team;

@interface Member : NSManagedObject

@property (nonatomic, retain) NSNumber * age;
@property (nonatomic, retain) NSDate * birthday;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * phonenum;
@property (nonatomic, retain) Team *belongedTeam;

@end
