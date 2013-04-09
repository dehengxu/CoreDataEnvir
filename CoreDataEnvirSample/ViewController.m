//
//  ViewController.m
//  CoreDataEnvirSample
//
//  Created by Deheng.Xu on 13-4-7.
//  Copyright (c) 2013年 Nicholas.Xu. All rights reserved.
//

#import "ViewController.h"
#import "CoreDataEnvir.h"
#import "Team.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.tem = (Team *)[Team lastItemWith:self.dbe predicate:[NSPredicate predicateWithFormat:@"name==9"]];
//    NSLog(@"first load data :%@", self.tem);
//    if (self.tem) {
//        self.tem.number = @(9999);
//    }
//    NSLog(@"first load data :%@", self.tem);
//    
//    [self.dbe saveDataBase];
//    [self.dbe sendPendingChanges];
//    NSLog(@"first load data :%@", self.tem);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (CoreDataEnvir *)dbe
{
    if (nil == _dbe) {
        _dbe = [[CoreDataEnvir instance] retain];
    }
    return _dbe;
}

int counter = 0;
- (void)onClick_test:(id)sender
{
    dispatch_queue_t q1 = dispatch_queue_create([[NSString stringWithFormat:@"com.cyblion.%d", ++counter] cStringUsingEncoding:NSUTF8StringEncoding], NULL);
    [self runTest:q1];
    dispatch_release(q1);
}

- (void)runTest:(dispatch_queue_t)queue
{
    int runTimes = 1;
    dispatch_async(queue, ^{
        CoreDataEnvir *db = [CoreDataEnvir instance];
        unsigned int c = counter;
        for (int i = 0; i < runTimes; i++) {
            Team *team = (Team *)[Team lastItemWith:db predicate:[NSPredicate predicateWithFormat:@"name==9"]];

            NSLog(@"isFault :%u", team.isFault);
            NSLog(@"team :%@", team);
            NSLog(@"name :%@", team.name);
            NSLog(@"team :%@", team);
            if (team) {
                //[team removeFrom:db];
                team.number = @(0 + c * 10000);
            }
            else {
                [Team insertItemWith:db fillData:^(Team *item) {
                    item.name = @"9";
                    item.number = @(0 + c * 10000);
                }];
            }
//            self.tem = team;
            NSLog(@"B team :%@", team);
            
            [db saveDataBase];
        }
        [db sendPendingChanges];
    });
}

- (void)onClick_clear:(id)sender
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        CoreDataEnvir *db = [CoreDataEnvir instance];
        Team *team = (Team *)[Team lastItemWith:db predicate:[NSPredicate predicateWithFormat:@"name==9"]];
        NSLog(@"will delete team :%@", team);
//        [team removeFrom:db];
//        [db saveDataBase];
//        [db sendPendingChanges];
    });
}

- (void)onClick_cancel:(id)sender
{
    //NSLog(@"%@  number :%@; %u %u", self.tem, self.tem.number, self.tem.isFault, [self.dbe.context hasChanges]);
    
    if (!self.tem) {
        self.tem = (Team *)[Team lastItemWith:self.dbe predicate:[NSPredicate predicateWithFormat:@"name==9"]];
    }
    
    if (self.tem.isFault) {
        NSLog(@"Need update data item!");
        self.tem = [self.dbe updateDataItem:self.tem];
    }
    
    @try {
        [self.dbe saveDataBase];
    }
    @catch (NSException *exception) {
        NSLog(@"exce :%@", [exception description]);
    }
    @finally {
        
    }

    NSLog(@"%@  ", self.tem);
    
}

@end
