//
//  ConcurrencyViewController.h
//  CoreDataEnvirSample
//
//  Created by Deheng.Xu on 13-9-26.
//  Copyright (c) 2013年 Nicholas.Xu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoreDataEnvir.h"

@class Team;
@class Member;

@interface ConcurrencyViewController : UIViewController
<
CoreDataRescureDelegate
>
{
    dispatch_semaphore_t __runs_sema;
}

@property (nonatomic, strong) Team *teamOnMainThread;
@property (nonatomic, strong) Team *teamOnBackground;

- (IBAction)onClick_test:(id)sender;
- (IBAction)onClick_clearAll:(id)sender;
- (IBAction)onClick_look:(id)sender;

@end
