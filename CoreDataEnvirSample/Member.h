//
//  Member.h
//  CoreDataEnvirSample
//
//  Created by Deheng.Xu on 13-4-7.
//  Copyright (c) 2013年 Nicholas.Xu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Member : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * phonenum;
@property (nonatomic, retain) NSNumber * age;
@property (nonatomic, retain) NSDate * birthday;

@end
