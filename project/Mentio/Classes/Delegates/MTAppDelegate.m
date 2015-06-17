//
//  MTAppDelegate.m
//  Mentio
//
//  Created by Martin Hartl on 04/10/13.
//  Copyright (c) 2013 Martin Hartl. All rights reserved.
//

#import "MTAppDelegate.h"
#import "FCModel.h"
#import "MTThemer.h"
#import "MTDatabaseManager.h"
#import "Mentio-Swift.h"
#import "MTItunesClient.h"

@interface MTAppDelegate ()

//@property AppStoreReceiptObtainer *obtainer;

@end

@implementation MTAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [MTDatabaseManager setUpFCModel];
    
    [[[MTThemer alloc] init] applyDefaultTheme];
    
    [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    
    [application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeBadge|UIUserNotificationTypeSound categories:nil]];
    
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    
    if ([url isFileURL]) {
        [MTDatabaseManager restoreFromMentioFileAtURL:url];
    } else {
        // Handle custom URL scheme
    }
    
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


#pragma mark - background fetch

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    NSURLSessionConfiguration *backgroundConfiguration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"background"];
    MTItunesClient *client = [[MTItunesClient alloc] initWithSessionConfiguration:backgroundConfiguration];
    
    [client refreshAllMedia:^(NSArray *results, NSError *error) {
        if (error) {
            completionHandler(UIBackgroundFetchResultFailed);
        }
        
        if (results) {
            completionHandler(UIBackgroundFetchResultNewData);
        }
    }];
    
}

@end
