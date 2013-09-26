//
//  ViewController.m
//  CoreDataEnvirSample
//
//  Created by Deheng.Xu on 13-4-7.
//  Copyright (c) 2013年 Nicholas.Xu. All rights reserved.
//

#import "ViewController.h"
//#import "CoreDataEnvir.h"
//#import "Team.h"

#define THREAD_NUMBER  20
#define LOOP_NUMBER_PER_THREAD  101
#define TESTING_A 1
#define TESTING_B 2
#define testing_case TESTING_A

@interface ViewController ()

@end

@implementation ViewController

@synthesize demonNames = _demonNames;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.frame = self.view.bounds;
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.tableView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - lazy loading

- (NSArray *)demonNames
{
    if (!_demonNames) {
        _demonNames = [[NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"demo" ofType:@"plist"]] retain];
    }
    return _demonNames;
}

- (UITableView *)tableView
{
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    }
    return _tableView;
}

#pragma mark - table view delegate & data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.demonNames count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier = @"_table_view_cell_identifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier] autorelease];
    }
    
    if (cell) {
        //Todo:Config cell object.
        
        cell.textLabel.text = [self.demonNames objectAtIndex:indexPath.row];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIViewController *vc = [[[NSClassFromString([NSString stringWithFormat:@"%@ViewController", [self.demonNames objectAtIndex:indexPath.row]]) alloc] init] autorelease];
    if (vc) {
        [self.navigationController pushViewController:vc animated:YES];
    }
    [[self.tableView cellForRowAtIndexPath:indexPath] setSelected:NO animated:YES];
}


@end
