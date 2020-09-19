//
//  CoreDataEnvirObserver.h
//  CoreDataEnvirFramework
//
//  Created by Deheng Xu on 2020/9/18.
//  Copyright © 2020 Nicholas.Xu. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - CoreDataEnvirObserver (Not be used temporarily)

@protocol CoreDataEnvirObserver

@optional
- (void)didFetchingFinished:(NSArray *) aItems;
- (void)didUpdateContext:(id)sender;
- (void)didDeleteObjects:(id)sender;
- (void)didInsertObjects:(id)sender;
- (void)didUpdateObjects:(id)sender;

@end



NS_ASSUME_NONNULL_END
