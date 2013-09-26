//
//  ViewController.h
//  CoreDataEnvirSample
//
//  Created by Deheng.Xu on 13-4-7.
//  Copyright (c) 2013年 Nicholas.Xu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoreDataEnvir.h"

@interface ViewController : UIViewController
<
UITableViewDelegate, UITableViewDataSource
>
{
}
@property (nonatomic, readonly, retain) NSArray *demonNames;
@property (nonatomic, retain) UITableView *tableView;

@end
