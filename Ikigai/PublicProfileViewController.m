//
//  PublicProfileViewController.m
//  Ikigai
//
//  Created by Alexandre Perozim de Faveri on 7/13/15.
//  Copyright (c) 2015 Team Ikigai. All rights reserved.
//

#import <Parse/Parse.h>
#import "PublicProfileViewController.h"
#import "UserTableViewController.h"
#import "FeedTableViewController.h"

@interface PublicProfileViewController ()

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
@property (weak, nonatomic) IBOutlet UIButton *followButton;

@property (strong, nonatomic) PFUser *user;

@end

@implementation PublicProfileViewController

static BOOL isFollowing;

- (IBAction)follow:(id)sender
{
    // Disable button until action completes
    [(UIButton *)sender setEnabled:NO];
    
    PFUser *currentUser = [PFUser currentUser];
    
    if (!isFollowing) {
        // Start following this user
        PFObject *follow = [PFObject objectWithClassName:@"Follow"];
        [follow setObject:currentUser  forKey:@"from"];
        [follow setObject:self.user forKey:@"to"];
        [follow setObject:[NSDate date] forKey:@"date"];
        [follow saveInBackgroundWithBlock:^(BOOL success, NSError *error) {
            if (success) {
                // Change text in button
                [(UIButton *)sender setTitle:@"Unfollow" forState:UIControlStateNormal];
                // Started following!
                isFollowing = YES;
                // Reload activity data
                [self getActivityData];
            } else {
                NSLog(@"Error: %@", [error localizedDescription]);
            }
            // Activate button
            [(UIButton *)sender setEnabled:YES];
        }];
    } else {
        // Stop following this user
        PFQuery *query = [PFQuery queryWithClassName:@"Follow"];
        [query whereKey:@"to" equalTo:self.user];
        [query whereKey:@"from" equalTo:currentUser];
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (error) {
                NSLog(@"Error: %@", [error localizedDescription]);
                // Activate button
                [(UIButton *)sender setEnabled:YES];
            } else if (objects.count != 1) { // Wrong number of Follows was found
                NSLog(@"Error: Internal inconsistency - currupted database.");
                // Activate button
                [(UIButton *)sender setEnabled:YES];
            } else {
                // Delete follow
                [objects[0] deleteInBackgroundWithBlock:^(BOOL success, NSError *error) {
                    if (success) {
                        // Change button title
                        [(UIButton *)sender setTitle:@"Follow" forState:UIControlStateNormal];
                        // Not following anymore!
                        isFollowing = NO;
                        // Reload activity data
                        [self getActivityData];
                    } else {
                        NSLog(@"Error: %@", [error localizedDescription]);
                    }
                    // Activate button
                    [(UIButton *)sender setEnabled:YES];
                }];
            }
        }];
    }
}

- (IBAction)openFollowersPage:(id)sender
{
    PFQuery *query = [PFQuery queryWithClassName:@"Follow"];
    [query whereKey:@"to" equalTo:self.user];
    UserTableViewController *utvc = [[UserTableViewController alloc] initWithStyle:UITableViewStylePlain
                                                                             query:query
                                                                              user:self.user
                                                                           context:@"Followers"];
    [self.navigationController pushViewController:utvc animated:YES];
}

- (IBAction)openFollowingPage:(id)sender
{
    PFQuery *query = [PFQuery queryWithClassName:@"Follow"];
    [query whereKey:@"from" equalTo:self.user];
    UserTableViewController *utvc = [[UserTableViewController alloc] initWithStyle:UITableViewStylePlain
                                                                             query:query
                                                                              user:self.user
                                                                           context:@"Following"];
    [self.navigationController pushViewController:utvc animated:YES];
}

- (IBAction)openPostsPage:(id)sender
{
    // Query over the user's posts
    PFRelation *relation = [self.user relationForKey:@"posts"];
    PFQuery *query = [relation query];
    [query orderByDescending:@"views"]; // Order by number of views
    FeedTableViewController *ftvc = [[FeedTableViewController alloc] initWithStyle:UITableViewStylePlain
                                                                             query:query
                                                                              user:self.user
                                                                           context:@"User"];
    [self.navigationController pushViewController:ftvc animated:YES];
}

- (instancetype)initWithUser:(PFUser *)user
{
    self = [super init];
    if (self) {
        _user = user; // Pass reference to user (avoid another query)
    }
    return self;
}

- (IBAction)backToSearch:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Create back button
    UIBarButtonItem *back = [[UIBarButtonItem alloc] initWithTitle:@"Back"
                                                             style:UIBarButtonItemStylePlain
                                                            target:self
                                                            action:@selector(backToSearch:)];
    
    self.navigationItem.leftBarButtonItem = back;
    
    // Get info for the fields (avoid retention cycle)
    __weak __typeof(self) weakSelf = self;
    [self.user fetchInBackgroundWithBlock:^(PFObject *user, NSError *error){
        [weakSelf didFetchUser:user error:error];
    }];
}

- (void) didFetchUser:(PFObject *)user error:(NSError *)error
{
    if (!user) {
        NSLog(@"Could not find user");
        self.view = self.profileView; // Show profile
    } else { // The find succeeded
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
}

- (void)getActivityData
{
    // Get the number of followers of the user
    PFQuery *followersQuery = [PFQuery queryWithClassName:@"Follow"];
    [followersQuery whereKey:@"to" equalTo:self.user];
    [followersQuery countObjectsInBackgroundWithBlock:^(int count, NSError *error) {
        if (error) {
            NSLog(@"Error: %@", [error localizedDescription]);
            self.view = self.profileView; // Show profile
        } else {
            self.followers.text = [NSString stringWithFormat:@"%d", count];
            
            // Get the number of people the user follows
            PFQuery *followingQuery = [PFQuery queryWithClassName:@"Follow"];
            [followingQuery whereKey:@"from" equalTo:self.user];
            [followingQuery countObjectsInBackgroundWithBlock:^(int count, NSError *error) {
                if (error) {
                    NSLog(@"Error: %@", [error localizedDescription]);
                    self.view = self.profileView; // Show profile
                } else {
                    self.following.text = [NSString stringWithFormat:@"%d", count];
                    
                    // Get the number of posts of the user
                    PFRelation *posts = [self.user relationForKey:@"posts"];
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
    [self.activityData.layer setBorderColor: [[UIColor blackColor] CGColor]];
    [self.activityData.layer setBorderWidth: 2.0];
    
    [self.activityDataDivisor.layer setBorderColor: [[UIColor blackColor] CGColor]];
    [self.activityDataDivisor.layer setBorderWidth: 2.0];
    
    [self.followButton.layer setCornerRadius:8.0];
    [self.followButton.layer setBorderColor:[[UIColor blackColor] CGColor]];
    [self.followButton.layer setBorderWidth: 2.0];
    
    if ([PFUser currentUser] != self.user) { // Allow following
        // Check if current user is following this user
        PFQuery *query = [PFQuery queryWithClassName:@"Follow"];
        [query whereKey:@"to" equalTo:self.user];
        [query whereKey:@"from" equalTo:[PFUser currentUser]];
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (error) {
                NSLog(@"Error: %@", [error localizedDescription]);
            } else if (objects.count == 0) { // Not following
                isFollowing = NO;
            } else if (objects.count == 1) { // Following
                isFollowing = YES;
                // Change button title
                [self.followButton setTitle:@"Unfollow" forState:UIControlStateNormal];
            } else { // Wrong number of Follows was found
                NSLog(@"Error: Internal inconsistency - currupted database.");
            }
        }];
    } else { // This is my profile! Disallow following
        [self.followButton setHidden:YES];
    }
}

@end
