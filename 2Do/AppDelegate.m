//
//  AppDelegate.m
//  2Do
//
//  Created by Robin Crorie on 14/05/2014.
//  Copyright (c) 2014 Robin Crorie. All rights reserved.
//

#import "AppDelegate.h"
#import "Synchroniser/Synchroniser.h"

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

@implementation AppDelegate
{
	NSTimer * syncTimer;
}

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	[[UINavigationBar appearance] setBarTintColor:UIColorFromRGB(0x067AB5)];
	[[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
	[[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"NavBarBackground"] forBarMetrics:UIBarMetricsDefault];
	[[UINavigationBar appearance] setBackIndicatorImage:[UIImage imageNamed:@"BackButton"]];
    [[UINavigationBar appearance] setBackIndicatorTransitionMaskImage:[UIImage imageNamed:@"BackButton"]];
	[[UINavigationBar appearance] setShadowImage:[UIImage imageNamed:@"NavBarShadow"]];
	
	[[UITabBar appearance] setBarTintColor:[UIColor darkGrayColor]];
	[[UITabBar appearance] setTintColor:[UIColor whiteColor]];
	
	NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.4];
    shadow.shadowOffset = CGSizeMake(1, 1);
    [[UINavigationBar appearance] setTitleTextAttributes: [NSDictionary dictionaryWithObjectsAndKeys:
                                                           [UIColor colorWithRed:255.0/255.0 green:255.0/255.0 blue:255.0/255.0 alpha:1.0], NSForegroundColorAttributeName,
                                                           shadow, NSShadowAttributeName,
                                                           [UIFont fontWithName:@"HelveticaNeue-CondensedBlack" size:21.0], NSFontAttributeName, nil]];

	syncTimer = [NSTimer scheduledTimerWithTimeInterval:60.0
												 target:self
											   selector:@selector(synData)
											   userInfo:nil
												repeats:YES];
	
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
	
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	[syncTimer invalidate];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	syncTimer = [NSTimer scheduledTimerWithTimeInterval:60.0
												 target:self
											   selector:@selector(synData)
											   userInfo:nil
												repeats:YES];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	[syncTimer invalidate];
	[self saveContext];
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        } 
    }
}

#pragma mark - Core Data stack

- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"_Do" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"_Do.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }    
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (void)synData
{
	NSError * error = nil;
	[Synchroniser syncTasks:&error];
	if (error) {
		NSLog(@"Sync Error: %@", error.localizedDescription);
	}
}

@end
