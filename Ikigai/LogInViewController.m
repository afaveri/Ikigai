//
//  LogInViewController.m
//  Ikigai
//
//  Created by Alexandre Perozim de Faveri on 7/10/15.
//  Copyright (c) 2015 Team Ikigai. All rights reserved.
//

#import <ParseFacebookUtilsV4/PFFacebookUtils.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <Parse/Parse.h>
#import "LogInViewController.h"

@implementation LogInViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //set the background image and Logo
    [self.view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"goldens.png"]]];
    [self.logInView setLogo:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"rsz_6logo.png"]]];
    
    //set Facebook button appearances
    [self.logInView.facebookButton setBackgroundImage:nil forState:UIControlStateNormal];
    [self.logInView.facebookButton setBackgroundImage:[UIImage imageNamed:@"fbButton2.png"] forState:UIControlStateNormal];
    [self.logInView.facebookButton setAlpha:0.8];
    
    //set Twitter button appearances
    [self.logInView.twitterButton setBackgroundImage:[UIImage imageNamed:@"twitterButton2.png"] forState:UIControlStateNormal];
    [self.logInView.twitterButton setAlpha:0.8];
    [self.logInView.twitterButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    
    [self.logInView.signUpButton setBackgroundImage:[UIImage imageNamed:@"signUpButton.png"] forState:UIControlStateNormal];
    
    [self.logInView.passwordForgottenButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.logInView.usernameField setBackgroundColor:[UIColor grayColor]];
    [self.logInView.passwordField setBackgroundColor:[UIColor grayColor]];
    [self.logInView.usernameField setTextColor:[UIColor whiteColor]];
    [self.logInView.passwordField setTextColor:[UIColor whiteColor]];
    [self.logInView.logInButton setBackgroundColor:[UIColor whiteColor]];
    
    [self.logInView.logInButton setAlpha:0.9];
    [self.logInView.usernameField setAlpha:0.5];
    [self.logInView.passwordField setAlpha:0.5];
    [self.logInView.signUpButton setAlpha:0.5];
}

- (void)_loginWithFacebook
{
    // Set permissions required from the facebook user account
    NSArray *permissionsArray = @[@"public_profile", @"email"];
    
    // Login PFUser using Facebook
    [PFFacebookUtils logInInBackgroundWithReadPermissions:permissionsArray block:^(PFUser *user, NSError *error) {
        if (error) {
            NSLog(@"Error: %@", [error localizedDescription]);
            [self dismissViewControllerAnimated:YES completion:nil];
        } else if (user.isNew) {
            [self _loadData];
        } else {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    // Set frame for elements
    [self.logInView.logo setFrame:CGRectMake(40.0f, 100.0f, 300.0f, 120.0f)];
}

- (void)_loadData
{
    FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:@"me"
                                                                   parameters:@{@"fields": @"name, gender, picture, cover"}];
    [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
        if (!error) {
            // Dictionary with the user's Facebook data
            NSDictionary *userData = (NSDictionary *)result;
            PFUser *currentUser = [PFUser currentUser];
            
            //Get name
            currentUser[@"name"] = userData[@"name"];
            
            // Get gender
            if ([userData[@"gender"] isEqualToString:@"male"]) {
                currentUser[@"gender"] = @"Male";
            } else if ([userData[@"gender"] isEqualToString:@"female"]) {
                currentUser[@"gender"] = @"Female";
            } else {
                currentUser[@"gender"] = @"";
            }
            
            // Store lowercase version of username for search
            currentUser[@"canonicalUsername"] = [currentUser.username lowercaseString];
            
            // Initialize all fields
            currentUser[@"canonicalName"] =        [userData[@"name"] lowercaseString];
            currentUser[@"age"] =                  @0;
            currentUser[@"race"] =                 @"";
            currentUser[@"sexualOrientation"] =    @"";
            currentUser[@"country"] =              @"";
            currentUser[@"city"] =                 @"";
            currentUser[@"canonicalCity"] =        @"";
            currentUser[@"education"] =            @"";
            currentUser[@"canonicalEducation"] =   @"";
            currentUser[@"occupation"] =           @"";
            currentUser[@"canonicalOccupation"] =  @"";
            currentUser[@"religion"] =             @"";
            currentUser[@"birthDate"] =            @"";
            currentUser[@"relationshipStatus"] =   @"";
            currentUser[@"politicalViews"] =       @"";
            
            NSString *facebookID = userData[@"id"];
            NSURL *pictureURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large&return_ssl_resources=1", facebookID]];
            
            NSURLRequest *urlRequest = [NSURLRequest requestWithURL:pictureURL];
            
            // Run network request asynchronously
            [NSURLConnection sendAsynchronousRequest:urlRequest
                                               queue:[NSOperationQueue mainQueue]
                                   completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                                       if (connectionError == nil && data != nil) {
                                           PFFile *profilePicture = [PFFile fileWithData:data];
                                           [profilePicture saveInBackgroundWithBlock:^(BOOL success, NSError *error) {
                                               if (! success) {
                                                   NSLog(@"Error: %@", [error localizedDescription]);
                                               } else {
                                                   // Get profile picture
                                                   currentUser[@"profilePicture"] = profilePicture;
                                                   
                                                   NSURL *coverURL = [NSURL URLWithString:userData[@"cover"][@"source"]];
                                                   NSURLRequest *secondURLRequest = [NSURLRequest requestWithURL:coverURL];
                                                   
                                                   // Run network request asynchronously
                                                   [NSURLConnection sendAsynchronousRequest:secondURLRequest
                                                                                      queue:[NSOperationQueue mainQueue]
                                                                          completionHandler:^(NSURLResponse *secondResponse, NSData *coverData, NSError *secondConnectionError) {
                                                                              if (secondConnectionError == nil && coverData != nil) {
                                                                                  PFFile *coverPhoto = [PFFile fileWithData:coverData];
                                                                                  [coverPhoto saveInBackgroundWithBlock:^(BOOL success, NSError *error) {
                                                                                      if (! success) {
                                                                                          NSLog(@"Error: %@", [error localizedDescription]);
                                                                                      } else {
                                                                                          // Get cover photo
                                                                                          currentUser[@"coverPhoto"] = coverPhoto;
                                                                                          [currentUser saveInBackgroundWithBlock:^(BOOL success, NSError *error) {
                                                                                              if (! success) {
                                                                                                  NSLog(@"Error: %@", [error localizedDescription]);
                                                                                              } else {
                                                                                                  [self dismissViewControllerAnimated:YES completion:nil];
                                                                                              }
                                                                                          }];
                                                                                      }
                                                                                  }];
                                                                              } else {
                                                                                  NSLog(@"Error: %@", [error localizedDescription]);
                                                                              }
                                                                          }];
                                               }
                                           }];
                                       } else {
                                           NSLog(@"Error: %@", [error localizedDescription]);
                                       }
                                   }];
        } else {
            NSLog(@"Error: %@", [error localizedDescription]);
        }
    }];
}

@end
