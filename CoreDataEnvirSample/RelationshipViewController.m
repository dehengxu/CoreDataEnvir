//
//  RelationshipViewController.m
//  CoreDataEnvirSample
//
//  Created by Deheng.Xu on 13-9-26.
//  Copyright (c) 2013年 Nicholas.Xu. All rights reserved.
//

#import "RelationshipViewController.h"

#import "CoreDataEnvir.h"
#import "Team.h"
#import "Member.h"

#define BUTTONS_NUMBER  5

@interface RelationshipViewController ()

@end

@implementation RelationshipViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor lightGrayColor];
    
    NSString * actions[BUTTONS_NUMBER] = {@"onClick_init:", @"onClick_load:", @"onClick_clearAll:", @"onClick_clearTeams:", @"onClick_clearMembers:"};
    NSString * titles[BUTTONS_NUMBER] = {@"Init", @"Watch", @"Clear All", @"Clear Teams", @"Cleaer Members"};
    
    CGSize buttonSize = CGSizeMake(180, 60);

    for (int i = 0; i < BUTTONS_NUMBER; i++) {
        
        UIButton *btn = [[[UIButton alloc] initWithFrame:CGRectZero] autorelease];
        btn.frame = CGRectMake(20, 20 + self.navigationController.navigationBar.frame.size.height + i * buttonSize.height, buttonSize.width, buttonSize.height);
        [btn addTarget:self action:NSSelectorFromString(actions[i]) forControlEvents:UIControlEventTouchUpInside];
        [btn setTitle:titles[i] forState:UIControlStateNormal];
        [self.view addSubview:btn];

    }
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)onClick_init:(id)sender
{
    Team *team1 = [Team insertItem];
    for (int i = 0; i < 20; i ++) {
        Member *mem = [Member insertItemWithBlock:^(Member *item) {
            item.name = [NSString stringWithFormat:@"T1_M%d", i];
            item.belongedTeam = team1;
        }];
        [team1 addMembersObject:mem];
        [mem save];
    }
    
    Team *team2 = [Team insertItem];
    for (int i = 0; i < 20; i ++) {
        Member *mem = [Member insertItemWithBlock:^(Member *item) {
            item.name = [NSString stringWithFormat:@"T2_M%d", i];
            item.belongedTeam = team2;
        }];
        [team2 addMembersObject:mem];
        [mem save];
    }
}

- (void)onClick_load:(id)sender
{
    CoreDataEnvir *db = [CoreDataEnvir instance];
    NSArray *teams = [Team itemsInContext:db];
    NSArray *members = [Member itemsInContext:db];
    
    int members_c = 0;
    for (Team *t in teams) {
        members_c += [t.members count];
    }
    NSString *message = [NSString stringWithFormat:@"teams %d\nmembers of teams :%d\ntotal members :%d.", [teams count], members_c, [members count]];
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"" message:message delegate:Nil cancelButtonTitle:@"Close" otherButtonTitles: nil] autorelease];
    [alert show];

}

- (void)onClick_clearAll:(id)sender
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        CoreDataEnvir *db = [CoreDataEnvir instance];

        NSArray *members = [Member itemsInContext:db];
        [members makeObjectsPerformSelector:@selector(removeFrom:) withObject:db];

        NSArray *teams = [Team itemsInContext:db];
        [teams makeObjectsPerformSelector:@selector(removeFrom:) withObject:db];
        
        
        [db saveDataBase];
    });

}

- (void)onClick_clearTeams:(id)sender
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        CoreDataEnvir *db = [CoreDataEnvir instance];
        
        NSArray *teams = [Team itemsInContext:db];
        [teams makeObjectsPerformSelector:@selector(removeFrom:) withObject:db];
        for (Team *t in teams) {
            t.members = nil;
            [t removeFrom:db];
        }
        
        [db saveDataBase];
    });
    
}

- (void)onClick_clearMembers:(id)sender
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        CoreDataEnvir *db = [CoreDataEnvir instance];
        
        NSArray *members = [Member itemsInContext:db];
        for (Member *m in members) {
            m.belongedTeam = nil;
            [m removeFrom:db];
        }
        
        [db saveDataBase];
    });
    
}

@end
