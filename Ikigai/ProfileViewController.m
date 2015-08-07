//
//  ProfileViewController.m
//  Ikigai
//
//  Created by Alexandre Perozim de Faveri on 7/6/15.
//  Copyright (c) 2015 Team Ikigai. All rights reserved.
//

#import <Parse/Parse.h>
#import "ProfileViewController.h"
#import "ProfileEditViewController.h"
#import "SettingsTableViewController.h"
#import "UserTableViewController.h"
#import "FeedTableViewController.h"
#import "ProfileNavigationController.h"

@interface ProfileViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *profilePicture;
@property (weak, nonatomic) IBOutlet UIImageView *activityData;
@property (weak, nonatomic) IBOutlet UIImageView *activityDataDivisor;
@property (weak, nonatomic) IBOutlet UIImageView *coverPhoto;

@property (weak, nonatomic) IBOutlet UILabel *name;
@property (weak, nonatomic) IBOutlet UILabel *username;
@property (weak, nonatomic) IBOutlet UILabel *email;
@property (weak, nonatomic) IBOutlet UILabel *age;
@property (weak, nonatomic) IBOutlet UILabel *gender;
@property (weak, nonatomic) IBOutlet UILabel *race;
@property (weak, nonatomic) IBOutlet UILabel *sexualOrientation;
@property (weak, nonatomic) IBOutlet UILabel *country;
@property (weak, nonatomic) IBOutlet UILabel *city;
@property (weak, nonatomic) IBOutlet UILabel *education;
@property (weak, nonatomic) IBOutlet UILabel *occupation;
@property (weak, nonatomic) IBOutlet UILabel *religion;
@property (weak, nonatomic) IBOutlet UILabel *birthDate;
@property (weak, nonatomic) IBOutlet UILabel *relationshipStatus;
@property (weak, nonatomic) IBOutlet UILabel *politicalViews;
@property (weak, nonatomic) IBOutlet UILabel *followers;
@property (weak, nonatomic) IBOutlet UILabel *following;
@property (weak, nonatomic) IBOutlet UILabel *posts;

@property (strong, nonatomic) IBOutlet UIView *profileView;

@end

@implementation ProfileViewController

- (IBAction)openFollowersPage:(id)sender
{
    PFQuery *query = [PFQuery queryWithClassName:@"Follow"];
    [query whereKey:@"to" equalTo:[PFUser currentUser]];
    UserTableViewController *utvc = [[UserTableViewController alloc] initWithStyle:UITableViewStylePlain
                                                                             query:query
                                                                              user:[PFUser currentUser]
                                                                           context:@"Followers"];
    [self.navigationController pushViewController:utvc animated:YES];
}

- (IBAction)openFollowingPage:(id)sender
{
    PFQuery *query = [PFQuery queryWithClassName:@"Follow"];
    [query whereKey:@"from" equalTo:[PFUser currentUser]];
    UserTableViewController *utvc = [[UserTableViewController alloc] initWithStyle:UITableViewStylePlain
                                                                             query:query
                                                                              user:[PFUser currentUser]
                                                                           context:@"Following"];
    [self.navigationController pushViewController:utvc animated:YES];
}

- (IBAction)openPostsPage:(id)sender
{
    // Query over the current user's posts
    PFRelation *relation = [[PFUser currentUser] relationForKey:@"posts"];
    PFQuery *query = [relation query];
    [query orderByDescending:@"views"]; // Order by number of views
    FeedTableViewController *ftvc = [[FeedTableViewController alloc] initWithStyle:UITableViewStylePlain
                                                                             query:query
                                                                              user:[PFUser currentUser]
                                                                           context:@"Current User"];
    [self.navigationController pushViewController:ftvc animated:YES];
}

- (void)enterEditMode
{
    ProfileEditViewController *pevc = [[ProfileEditViewController alloc] initWithNibName:@"ProfileEditViewController"
                                                                                  bundle:nil];
    pevc.numberOfFollowers = [self.followers.text integerValue];
    pevc.numberOfFollowing = [self.following.text integerValue];
    pevc.numberOfPosts = [self.posts.text integerValue];
    
    // Receive notifications when keyboard appears
    [pevc registerForKeyboardNotifications];
    
    ProfileNavigationController *penc = [[ProfileNavigationController alloc] initWithRootViewController:pevc];
    
    // Present edit screen modally
    [self presentViewController:penc animated:YES completion:nil];

}

- (void)showSettings
{
    SettingsTableViewController *stvc = [[SettingsTableViewController alloc] init];
    
    [self.navigationController pushViewController:stvc animated:YES];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    // Create settings button in navigation bar
    UIBarButtonItem *settingsButton = [[UIBarButtonItem alloc] initWithTitle:@"\u2699" style:UIBarButtonItemStylePlain target:self action:@selector(showSettings)];
    UIFont *customFont = [UIFont fontWithName:@"Helvetica" size:24.0];
    NSDictionary *fontDictionary = @{NSFontAttributeName : customFont};
    [settingsButton setTitleTextAttributes:fontDictionary forState:UIControlStateNormal];
    self.navigationItem.rightBarButtonItem = settingsButton;
    
    // Create Edit button
    UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStylePlain target:self action:@selector(enterEditMode)];
    self.navigationItem.leftBarButtonItem = editButton;
    
    // Get info for the fields
    PFUser *currentUser = [PFUser currentUser];
    [currentUser fetchFromLocalDatastoreInBackgroundWithBlock:^(PFObject *user, NSError *error){
        if (!user) {
            NSLog(@"Error: %@ %@", error, [error userInfo]);
            self.view = self.profileView; // Show profile
        } else {
            self.name.text =                user[@"name"];
            self.username.text =            user[@"username"];
            self.email.text =               user[@"email"];
            
            if ([user[@"age"]  isEqual: @0]) { // Age undefined (do not show)
                self.age.text = @"";
            } else {
                self.age.text = [user[@"age"] stringValue];
            }
            
            self.gender.text =              user[@"gender"];
            self.race.text =                user[@"race"];
            self.sexualOrientation.text =   user[@"sexualOrientation"];
            self.country.text =             user[@"country"];
            self.city.text =                user[@"city"];
            self.education.text =           user[@"education"];
            self.occupation.text =          user[@"occupation"];
            self.religion.text =            user[@"religion"];
            self.birthDate.text =           user[@"birthDate"];
            self.relationshipStatus.text =  user[@"relationshipStatus"];
            self.politicalViews.text =      user[@"politicalViews"];
            
            // Create a title for the navigation bar
            self.navigationItem.title = self.name.text;
            
            [user[@"profilePicture"] getDataInBackgroundWithBlock:^(NSData *imageData, NSError *error) {
                if (!error) {
                    self.profilePicture.image = [UIImage imageWithData:imageData]; // Finish loading image
                    [user[@"coverPhoto"] getDataInBackgroundWithBlock:^(NSData *imageData, NSError *error) {
                        if (!error) {
                            self.coverPhoto.image = [UIImage imageWithData:imageData]; // Finish loading image
                            // Get activity data for fields
                            [self getActivityData];
                        } else {
                            // Error
                            NSLog(@"Error: %@ %@", error, [error userInfo]);
                            // Get activity data for fields
                            [self getActivityData];
                        }
                    }];
                    
                    if (! user[@"coverPhoto"]) {
                        // Get activity data for fields
                        [self getActivityData];
                    }
                } else {
                    // Error
                    NSLog(@"Error: %@ %@", error, [error userInfo]);
                    // Get activity data for fields
                    [self getActivityData];
                }
            }];
            
            if (! user[@"profilePicture"]) {
                [user[@"coverPhoto"] getDataInBackgroundWithBlock:^(NSData *imageData, NSError *error) {
                    if (!error) {
                        self.coverPhoto.image = [UIImage imageWithData:imageData]; // Finish loading image
                        // Get activity data for fields
                        [self getActivityData];
                    } else {
                        // Error
                        NSLog(@"Error: %@ %@", error, [error userInfo]);
                        // Get activity data for fields
                        [self getActivityData];
                    }
                }];
                
                if (! user[@"coverPhoto"]) {
                    // Get activity data for fields
                    [self getActivityData];
                }
            }
        }
    }];
}

- (void)getActivityData
{
    PFUser *currentUser = [PFUser currentUser];
    
    // Get the number of followers of the user
    PFQuery *followersQuery = [PFQuery queryWithClassName:@"Follow"];
    [followersQuery whereKey:@"to" equalTo:currentUser];
    [followersQuery countObjectsInBackgroundWithBlock:^(int count, NSError *error) {
        if (error) {
            NSLog(@"Error: %@", [error localizedDescription]);
            self.view = self.profileView; // Show profile
        } else {
            self.followers.text = [NSString stringWithFormat:@"%d", count];
            
            // Get the number of people the user follows
            PFQuery *followingQuery = [PFQuery queryWithClassName:@"Follow"];
            [followingQuery whereKey:@"from" equalTo:currentUser];
            [followingQuery countObjectsInBackgroundWithBlock:^(int count, NSError *error) {
                if (error) {
                    NSLog(@"Error: %@", [error localizedDescription]);
                    self.view = self.profileView; // Show profile
                } else {
                    self.following.text = [NSString stringWithFormat:@"%d", count];
                    
                    // Get the number of posts of the user
                    PFRelation *posts = [currentUser relationForKey:@"posts"];
                    PFQuery *postsQuery = [posts query];
                    [postsQuery countObjectsInBackgroundWithBlock:^(int count, NSError *error) {
                        if (error) {
                            NSLog(@"Error: %@", [error localizedDescription]);
                            self.view = self.profileView; // Show profile
                        } else {
                            self.posts.text = [NSString stringWithFormat:@"%d", count];
                            
                            self.view = self.profileView; // Show profile when everything loads
                        }
                    }];
                }
            }];
        }
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Show screen with activity indicator while profile view loads
    UIView *loadingView = [[UIView alloc] initWithFrame:self.view.bounds];
    loadingView.backgroundColor = [UIColor whiteColor];
    UIActivityIndicatorView *loading = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    loading.color = [UIColor blackColor];
    [loading startAnimating];
    loading.center = loadingView.center;
    [loadingView addSubview:loading];
    self.view = loadingView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    self.profilePicture.layer.cornerRadius = 8.0;
    [self.profilePicture.layer setBorderColor: [[UIColor blackColor] CGColor]];
    [self.profilePicture.layer setBorderWidth: 2.0];
    
    self.activityData.layer.cornerRadius = 8.0;
    [self.activityData.layer setBorderColor:[[UIColor blackColor] CGColor]];
    [self.activityData.layer setBorderWidth:2.0];
    
    [self.activityDataDivisor.layer setBorderColor: [[UIColor blackColor] CGColor]];
    [self.activityDataDivisor.layer setBorderWidth: 2.0];
}

@end
