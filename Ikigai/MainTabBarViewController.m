//
//  MainTabBarViewController.m
//  Ikigai
//
//  Created by Alexandre Perozim de Faveri on 7/21/15.
//  Copyright (c) 2015 Team Ikigai. All rights reserved.
//

#import <Parse/Parse.h>
#import <AudioToolbox/AudioToolbox.h>
#import "MainTabBarViewController.h"
#import "ProfileViewController.h"
#import "FeedTableViewController.h"
#import "RecorderViewController.h"
#import "FeedCellViewController.h"
#import "ProfileNavigationController.h"

@interface MainTabBarViewController ()

@property (strong, nonatomic) RecorderViewController *recorderViewController;

@end

@implementation MainTabBarViewController

static const NSInteger kProfileButtonIndex = 0;
static const NSInteger kCameraButtonIndex = 1;
static const NSInteger kFeedButtonIndex = 2;

- (void)viewDidLoad
{
    [UITabBarItem.appearance setTitleTextAttributes:@{
                                                      NSForegroundColorAttributeName : [UIColor blackColor] } forState:UIControlStateNormal];
    
    [UITabBarItem.appearance setTitleTextAttributes:@{
                                                      NSForegroundColorAttributeName : [UIColor redColor] }     forState:UIControlStateSelected];
    
    [UITabBarItem.appearance setTitleTextAttributes:@{
                                                      NSFontAttributeName : [UIFont fontWithName:@"Quicksand" size:11.0f] } forState:UIControlStateNormal];
    // Create profile tab
    ProfileViewController *pvc = [[ProfileViewController alloc] initWithNibName:@"ProfileViewController"
                                                                         bundle:nil];
    ProfileNavigationController *pnc = [[ProfileNavigationController alloc] initWithRootViewController:pvc];
    UITabBarItem *profileItem = [[UITabBarItem alloc] initWithTitle:@"Profile" image:[UIImage imageNamed:@"user-32.png"] tag:kProfileButtonIndex];
    pnc.tabBarItem = profileItem;
    
    // Create decoy tab for the camera
    UIViewController *decoy = [[UIViewController alloc] init];
    decoy.navigationItem.title = @"Camera";
    UINavigationController *dnc = [[UINavigationController alloc] initWithRootViewController:decoy];
    UITabBarItem *cameraItem = [[UITabBarItem alloc] initWithTitle:@"Camera" image:[UIImage imageNamed:@"Camera-32.png"] tag:kCameraButtonIndex];
    dnc.tabBarItem = cameraItem;
    
    // Create feed query
    PFQuery *query = [PFQuery queryWithClassName:@"Post"];
    [query orderByDescending:@"views"]; // Order by number of views
    
    // Create feed tab
    FeedTableViewController *ftvc = [[FeedTableViewController alloc] initWithStyle:UITableViewStylePlain
                                                                             query:query
                                                                              user:nil
                                                                           context:@"Feed"];
    UINavigationController *fnc = [[UINavigationController alloc] initWithRootViewController:ftvc];
    UITabBarItem *feedItem = [[UITabBarItem alloc] initWithTitle:@"Feed" image:[UIImage imageNamed:@"Film-32.png"] tag:kFeedButtonIndex];
    fnc.tabBarItem = feedItem;
    
    NSArray *controllers = [[NSArray alloc] initWithObjects:pnc, dnc, fnc, nil];
    self.viewControllers = controllers;
    [[UITabBar appearance] setTintColor:[UIColor redColor]];
}

- (NSUInteger)supportedInterfaceOrientations
{
    if (self.selectedViewController) { // Delegate decision to each view controller
        return [self.selectedViewController supportedInterfaceOrientations];
    }
    
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotate
{
    // Autorotation is generally on (Profile tab turns it off)
    return YES;
}

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
    if (item.tag == kCameraButtonIndex) { // Show the camera in full screen
        // Restrict media to video
        NSArray *mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
        NSArray *videoMediaTypesOnly = [mediaTypes filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(SELF contains %@)", @"movie"]];
        
        // Check if system supports this image picker controller
        if ([videoMediaTypesOnly count] == 0) { // No movie recording
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Video Recording Not Available"
                                                            message:@"Sorry but your device does not support video recording."
                                                           delegate:nil
                                                  cancelButtonTitle:@"Ok"
                                                  otherButtonTitles:nil];
            [alert show];
            return;
        }
        
        if (! [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) { // Camera not available
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Camera Not Available"
                                                            message:@"Sorry but your device does not have a camera."
                                                           delegate:nil
                                                  cancelButtonTitle:@"Ok"
                                                  otherButtonTitles:nil];
            [alert show];
            return;
        }
        
        // If control reaches this statement, it is safe to present the recorder view controller
        RecorderViewController *rvc = [[RecorderViewController alloc] initWithSourceType:UIImagePickerControllerSourceTypeCamera];
        self.recorderViewController = rvc;
        [self presentViewController:rvc animated:YES completion:nil];
    }
}


// Shake Gesture Implemented
- (BOOL)canBecomeFirstResponder
{
    return YES;
}

// Become first responder whenever the view appears
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self becomeFirstResponder];
}

// Resign first responder whenever the view disappears
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self resignFirstResponder];
}

// Shake Motion Event logs and sounds
- (void)motionBegan:(UIEventSubtype)motion
          withEvent:(UIEvent *)event
{
    if (motion != UIEventSubtypeMotionShake) {
        return;
    }
    
    // Query for a random video for the user
    PFQuery *query = [PFQuery queryWithClassName:@"Post"];
    [query orderByDescending:@"index"];
    query.limit = 1;
    [query getFirstObjectInBackgroundWithBlock:^(PFObject *maxIndexVideo, NSError *error) {
        if (!error) {
            NSInteger maxIndex = [(NSNumber *)maxIndexVideo[@"index"] integerValue];
            PFQuery *postQuery = [PFQuery queryWithClassName:@"Post"];
            do {
                NSInteger randomIndex = arc4random_uniform((int)maxIndex + 1);
                [postQuery whereKey:@"index" equalTo:[NSNumber numberWithInteger:randomIndex]];
                [postQuery getFirstObjectInBackgroundWithBlock:^(PFObject *post, NSError *error){
                    if (!error) {
                        [post[@"video"] getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
                            if (!error) {
                                NSString *fileName = [NSString stringWithFormat:@"%@.mp4", post.objectId];
                                NSURL *fileURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:fileName]];
                                
                                // Save video
                                [data writeToURL:fileURL atomically:YES];
                                
                                // Create view controller
                                FeedCellViewController *fcvc = [[FeedCellViewController alloc] init];
                                UINavigationController *fcnc = [[UINavigationController alloc] initWithRootViewController:fcvc];
                                
                                [self presentViewController:fcnc animated:YES completion:^{
                                    // Change post
                                    fcvc.post = post;
                                }];
                            } else {
                                NSLog(@"Error: %@", [error localizedDescription]);
                            }
                        }];
                    } else {
                        NSLog(@"Error: %@", [error localizedDescription]);
                    }
                }];
            } while ([postQuery whereKeyDoesNotExist:@"objectID"]);
        } else {
            NSLog(@"Error: %@", [error localizedDescription]);
        }
    }];
}

@end
