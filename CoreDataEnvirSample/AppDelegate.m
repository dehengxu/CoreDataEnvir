//
//  AppDelegate.m
//  CoreDataEnvirSample
//
//  Created by Deheng.Xu on 13-4-7.
//  Copyright (c) 2013年 Nicholas.Xu. All rights reserved.
//

#import "AppDelegate.h"

#import "ViewController.h"

#import "CoreDataEnvir.h"
#import "Team.h"
#import "Member.h"
#import <CoreDataEnvir/CoreDataEnvirHeader.h>

_Bool checkEnv(const char* name) {
    const char* env  = getenv(name);
    return (env != 0 && strcmp(env, "1") == 0);
}

@implementation AppDelegate

- (void)dealloc
{
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    if (!checkEnv("debug")) {
        exit(0);
    }
    if (!checkEnv("demo")) {
        self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        self.window.rootViewController = [UIViewController new];
        self.window.rootViewController.view.backgroundColor = UIColor.blackColor;
        [self.window makeKeyAndVisible];
#if true // test legacy
		[CoreDataEnvir.backgroundInstance asyncWithBlock:^(CoreDataEnvir * _Nonnull db) {
			[Team insertItemInContext:db fillData:^(Team*  _Nonnull item) {
				item.name = @"CybLion";
			}];
			[db saveDataBase];
		}];
//		[Team insertItemOnBackgroundWithFillingBlock:^(Team*  _Nonnull item) {
//			item.name = @"Lion";
//		}];

//        [Team insertItemWithFillingBlock:^(Team* item) {
//            item.name = @"Lion";
//            [item save];
//        }];
        printf("Team total count: %lu\n", Team.totalCount);
#else
        NSURL* modelURL = [NSBundle.mainBundle URLForResource:@"SampleModel" withExtension:@"momd"];
        CoreDataEnvirBlock initBlock = ^(CoreDataEnvir* db) {
            [db setupModelWithURL:modelURL];
            
            NSString* searchedPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true) lastObject];
            NSLog(@"search path: %@", searchedPath);
            NSURL* dbURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/db.sqlite", searchedPath]];
            NSLog(@"dbURL: %@", dbURL);
            if (dbURL) {
                [db setupDefaultPersistentStoreWithURL:dbURL];
            }
        };
        CoreDataEnvir* db = [CoreDataEnvir create];
        [db setupWithBlock:initBlock];
        CoreDataEnvir* db2 = [CoreDataEnvir create];
        [db2 setupWithBlock:initBlock];
        
        [db syncInBlock:^(CoreDataEnvir * _Nonnull db) {
            Team* obj = [Team insertItemInContext:db];
            obj.name = @"new pattern";
            [db saveDataBase];
            
            NSFetchRequest* req = [Team newFetchRequestInContext:db];
            NSError* err = nil;
            NSUInteger count = [db.context countForFetchRequest:req error:&err];
            printf("Team total count: %lu\n", count);
        }];
        
#endif
        return true;
    }
	NSLog(@"CoreDataEnvirVersionString: %s", CoreDataEnvirVersionString);
	NSLog(@"CoreDataEnvirVersionNumber: %f", CoreDataEnvirVersionNumber);
    //Set db file name and model file name.
//    [CoreDataEnvir registerDefaultDataFileName:@"db.sqlite"];
//    [CoreDataEnvir registerDefaultModelFileName:@"SampleModel"];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.viewController = [[ViewController alloc] initWithNibName:nil bundle:nil];
    self.navigationController = [[UINavigationController alloc] initWithRootViewController:self.viewController];
    
    //NSLog(@"ver: %f", CoreDataEnvirVersionNumber);
    
    self.window.rootViewController = self.navigationController;
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
