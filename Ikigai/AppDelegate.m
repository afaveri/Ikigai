//
//  AppDelegate.m
//  Ikigai
//
//  Created by Alexandre Perozim de Faveri on 7/6/15.
//  Copyright (c) 2015 Team Ikigai. All rights reserved.
//

#import "AppDelegate.h"
#import "RootViewController.h"
#import <Parse/Parse.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <ParseFacebookUtilsV4/PFFacebookUtils.h>

@import GoogleMaps;

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [GMSServices provideAPIKey:@"AIzaSyAVCc1YR-yJmSpQBQ98bDMhvH8JvgFzo6M"];
    
    [Parse enableLocalDatastore];
    
    // Initialize Parse.
    [Parse setApplicationId:@"bpIj7smQjSMnm131IyqVVu5lLoAem2wQQLjPTfUw"
                  clientKey:@"7nVNBwJCv4yU6ncbd8M3vGgdCQnjtDaqbx84eWlf"];
    
    //Initialize Twitter Login
    [PFTwitterUtils initializeWithConsumerKey:@"Y4Znu3VhZXUzV9umwQErr44BV"
                               consumerSecret:@"CrL27sNYummNmIwHEN8d439ROFDVznBL2IatJwc7VGSG5ElJfM"];
    
    //Initialize Facebook Login
    [PFFacebookUtils initializeFacebookWithApplicationLaunchOptions:launchOptions];
    
    // Track statistics around application opens.
    [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    // Pass control to the first view controller
    RootViewController *lvc = [[RootViewController alloc] init];
    self.window.rootViewController = lvc;
    
    [self.window makeKeyAndVisible];
    [[UINavigationBar appearance] setTitleTextAttributes: @{NSFontAttributeName: [UIFont fontWithName:@"Quicksand" size:20.0f]}];
    [[UINavigationBar appearance] setTintColor:[UIColor colorWithRed:255.0/256.0 green:255.0/256.0 blue:255.0/256.0 alpha:1.0]];
    [[UINavigationBar appearance] setBarStyle:UIBarStyleBlack];
    [[UINavigationBar appearance] setBarTintColor:[UIColor colorWithRed:210.0/256.0 green:0.0/256.0 blue:2.0/256.0 alpha:1.0]];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    NSArray* tmpDirectory = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:NSTemporaryDirectory() error:NULL];
    for (NSString *file in tmpDirectory) {
        if (![file isEqualToString:@"MediaCache"] &&
            ![file isEqualToString:@"capture"] &&
            ![file isEqualToString:@"post.mp4"]) {
            [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), file]
                                                       error:NULL];
            NSLog(@"%@", file);
        }
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [FBSDKAppEvents activateApp];
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation
{
    return [[FBSDKApplicationDelegate sharedInstance] application:application
                                                          openURL:url
                                                sourceApplication:sourceApplication
                                                       annotation:annotation];
}



@end
