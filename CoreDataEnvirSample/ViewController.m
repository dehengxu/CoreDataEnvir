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

#define THREAD_LOOP_NUMBER  101

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewWillAppear:(BOOL)animated
{
}

- (void)viewWillDisappear:(BOOL)animated
{
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


int runs_forever = THREAD_LOOP_NUMBER;
- (void)updateDatabaseOnMainThread
{
    dispatch_async(dispatch_get_main_queue(), ^{
        CoreDataEnvir *db = [CoreDataEnvir instance];
        long testCounter = 0;
        while (runs_forever && testCounter >= 0) {
            Team *team = [Team itemsInContext:db usingPredicate:[NSPredicate predicateWithFormat:@"name==com.cyblion"]];
            team.number = @(testCounter);
            testCounter ++;
        }
    });
    
}

int counter = 0;
- (void)onClick_test:(id)sender
{
    [self updateDatabaseOnMainThread];
    
    for (int i = 0; i < 20; i++) {
        dispatch_queue_t q1 = NULL;
#if 0
        //Start 21 thread for testing, every thread runs CRUD operation 101 times seperately.
        q1 = dispatch_queue_create([[NSString stringWithFormat:@"com.cyblion.%d", ++counter] cStringUsingEncoding:NSUTF8StringEncoding], NULL);
#else
        //Start 20 thread for testing, every thread runs CRUD operation 101 times on Name "com.cyblion".
        q1 = dispatch_queue_create([[NSString stringWithFormat:@"com.cyblion"] cStringUsingEncoding:NSUTF8StringEncoding], NULL);
#endif
        if (q1) {
            [self runTest:q1 withTimes:THREAD_LOOP_NUMBER];
            dispatch_release(q1);
        }
    }
}

- (void)runTest:(dispatch_queue_t)queue withTimes:(unsigned int)times
{
    //Every thread runs 101 times CRUD operation.
    int runTimes = times;
    dispatch_async(queue, ^{
        CoreDataEnvir *db = [CoreDataEnvir instance];
        unsigned int c = counter;
        NSString *queueLabel = [NSString stringWithCString:dispatch_queue_get_label(queue) encoding:NSUTF8StringEncoding];
        
        for (int i = 0; i < runTimes; i++) {
            Team *team = (Team *)[Team lastItemInContext:db usingPredicate:[NSPredicate predicateWithFormat:@"name==%@", queueLabel]];
            
            //Delete item.
            if (team) {
                //[team removeFrom:db];
                //team.number = @(0 + c * 10000);
                NSLog(@"queue :%@; team :%@", queueLabel, team.number);
            }
            else {
                //Inset item.
                [Team insertItemInContext:db fillData:^(Team *item) {
                    item.name = queueLabel;
                    item.number = @(0 + c * 10000);
                }];
            }
            [db saveDataBase];
        }
        
        runs_forever--;
    });
}

- (void)onClick_clear:(id)sender
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        CoreDataEnvir *db = [CoreDataEnvir instance];
        NSLog(@"delete %@", db.context);
        NSArray *items = [Team itemsInContext:db];
        NSLog(@"will delete teams :%u", items.count);
        [db deleteDataItems:items];
        [db saveDataBase];
    });
}

- (void)onClick_look:(id)sender
{
    //self.tem.number;
    NSLog(@"--->>>%@", self.tem);
}

@end
