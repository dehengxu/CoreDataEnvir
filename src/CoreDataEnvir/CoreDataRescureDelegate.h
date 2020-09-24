//
//  CoreDataRescureDelegate.h
//  CoreDataEnvirFramework
//
//  Created by Deheng Xu on 2020/9/18.
//  Copyright © 2020 Nicholas.Xu. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CoreDataEnvir;

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



NS_ASSUME_NONNULL_END
