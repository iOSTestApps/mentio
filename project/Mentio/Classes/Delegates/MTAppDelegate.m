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
#import "SVProgressHUD.h"
#import "MTNotificationConstants.h"

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
        [self handleDatabaseRestoreRequest:url];
        
    } else {
        // Handle custom URL scheme
    }
    
    return YES;
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

#pragma mark - Helper

- (void)handleDatabaseRestoreRequest:(NSURL *)databaseURL {
    UIAlertController *controller = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"databaseimport.alert.title", @"import") message:NSLocalizedString(@"databaseimport.alert.text", @"text") preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"databaseimport.alert.no", @"no") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        return;
    }];
    
    UIAlertAction *yesAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"databaseimport.alert.yes", @"yes") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [SVProgressHUD show];
        [MTDatabaseManager restoreFromMentioFileAtURL:databaseURL success:^{
            //success
            [SVProgressHUD dismiss];
            [[NSNotificationCenter defaultCenter] postNotificationName:MTDatabaseGotImportedNotification object:nil];
        } rollback:^{
            //failure
            [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"databaseimport.alert.error", @"error")];
        }];
        return;
    }];
    
    [controller addAction:cancelAction];
    [controller addAction:yesAction];
    
    [self.window.rootViewController presentViewController:controller animated:YES completion:nil];
}

@end
