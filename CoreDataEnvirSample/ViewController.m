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
    NSLog(@"tem :%@", self.tem);
    if (self.tem) {
        self.tem.number = @(9999);
    }else {
        self.tem = [Team insertItemWith:self.dbe fillData:^(Team *item) {
           item.name = @"9";
            item.number = @(9999);
        }];
    }
    
    [self.dbe saveDataBase];
    NSLog(@"T %@", self.tem);
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
        _dbe.delegate = self;
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
    int runTimes = 101;
    dispatch_async(queue, ^{
        CoreDataEnvir *db = [CoreDataEnvir instance];
        unsigned int c = counter;
        for (int i = 0; i < runTimes; i++) {
            Team *team = (Team *)[Team lastItemWith:db predicate:[NSPredicate predicateWithFormat:@"name==9"]];

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

//            [db saveDataBase];
        }
//        [db sendPendingChanges];
        [db saveDataBase];
    });
}

- (void)onClick_clear:(id)sender
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        CoreDataEnvir *db = [CoreDataEnvir instance];
        NSArray *items = [Team itemsWith:db predicate:[NSPredicate predicateWithFormat:@"name==9"]];
        NSLog(@"will delete teams :%u", items.count);
        [db deleteDataItems:items];
        [db saveDataBase];
//        [db sendPendingChanges];
    });
}

- (void)onClick_look:(id)sender
{
    self.tem.number;
    NSLog(@"--->>>%@", self.tem);
}

- (void)didUpdateObjects:(NSNotification *)notify
{
    NSLog(@"%s  %@", __FUNCTION__, notify.userInfo);
    NSManagedObjectContext *ctx = notify.object;
    NSLog(@"changed :%u;  insert :%u, delete :%u, update :%u;", ctx.hasChanges, ctx.insertedObjects.count, ctx.deletedObjects.count, ctx.updatedObjects.count);

    self.tem = (Team *)[Team lastItemWith:self.dbe predicate:[NSPredicate predicateWithFormat:@"name==9"]];
}

@end
