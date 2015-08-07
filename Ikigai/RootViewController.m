//
//  RootViewController.m
//  Ikigai
//
//  Created by Alexandre Perozim de Faveri on 7/8/15.
//  Copyright (c) 2015 Team Ikigai. All rights reserved.
//

#import <Parse/Parse.h>
#import <ParseUI/ParseUI.h>
#import "RootViewController.h"
#import "LogInViewController.h"
#import "SignUpViewController.h"
#import "EmailConfirmationViewController.h"
#import "MainTabBarViewController.h"
#import <ParseFacebookUtilsV4/PFFacebookUtils.h>
#import <TwitterKit/TwitterKit.h>


@implementation RootViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
}

- (void)viewDidAppear:(BOOL)animated
{
    PFUser *currentUser = [PFUser currentUser];
    BOOL isLinkedToTwitter = [PFTwitterUtils isLinkedWithUser:currentUser];
    BOOL isLinkedToFacebook = [PFFacebookUtils isLinkedWithUser:currentUser];
    
    if (!currentUser) { // User not set up
        // Create the log in view controller
        LogInViewController *logInViewController = [[LogInViewController alloc] init];
        [logInViewController setDelegate:self]; // Set ourselves as the delegate
        [logInViewController setFields: PFLogInFieldsUsernameAndPassword
                                        | PFLogInFieldsLogInButton
                                        | PFLogInFieldsSignUpButton
                                        | PFLogInFieldsPasswordForgotten
                                        | PFLogInFieldsTwitter
                                        | PFLogInFieldsFacebook];
        
        // Create the sign up view controller
        SignUpViewController *signUpViewController = [[SignUpViewController alloc] init];
        signUpViewController.fields = (PFSignUpFieldsDefault);
        [signUpViewController setDelegate:self]; // Set ourselves as the delegate
        
        // Assign our sign up controller to be displayed from the login controller
        [logInViewController setSignUpController:signUpViewController];
        
        // Present the log in view controller
        [self presentViewController:logInViewController animated:YES completion:NULL];
        // If user logs in with Facebook, that user is saved to Parse
    } else {
        if (isLinkedToFacebook) { // Logged in with FB
            [self enterTheApp];
        } else if (isLinkedToTwitter) { // Logged in with Twitter
            if (currentUser[@"name"] == nil) { // Fields not yet initialized
                // Store lowercase version of username for search
                currentUser[@"canonicalUsername"] = [currentUser.username lowercaseString];
                
                // Initialize all fields
                currentUser[@"name"] =                 @"";
                currentUser[@"canonicalName"] =        @"";
                currentUser[@"age"] =                  @0;
                currentUser[@"gender"] =               @"";
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
                
                [currentUser saveEventually];
            }
            
            [self enterTheApp];
        } else if (![currentUser[@"emailVerified"] boolValue]) { // Email not verified
            // Ask user to verify email
            EmailConfirmationViewController *ecvc = [[EmailConfirmationViewController alloc] init];
            [self presentViewController:ecvc animated:YES completion:nil];
        } else { // User is logged in
            if (currentUser[@"name"] == nil) { // Fields not yet initialized
                // Store lowercase version of username for search
                currentUser[@"canonicalUsername"] = [currentUser.username lowercaseString];
                
                // Initialize all fields
                currentUser[@"name"] =                 @"";
                currentUser[@"canonicalName"] =        @"";
                currentUser[@"age"] =                  @0;
                currentUser[@"gender"] =               @"";
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
                
                [currentUser saveEventually];
            }
            
            // Use the app!
            [self enterTheApp];
        }

    }
}

#pragma mark - PFLogInViewController delegate


// Sent to the delegate to determine whether the log in request should be submitted to the server.
- (BOOL)logInViewController:(PFLogInViewController *)logInController shouldBeginLogInWithUsername:(NSString *)username password:(NSString *)password
{
    // Check if both fields are completed
    if (username && password && username.length != 0 && password.length != 0) {
        return YES; // Begin login process
    }
    
    [[[UIAlertView alloc] initWithTitle:@"Missing Information"
                                message:@"Make sure you fill out all of the information!"
                               delegate:nil
                      cancelButtonTitle:@"Ok"
                      otherButtonTitles:nil] show];
    return NO; // Interrupt login process
}

// Sent to the delegate when a PFUser is logged in.
- (void)logInViewController:(PFLogInViewController *)logInController didLogInUser:(PFUser *)user
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - PFSignUpViewController delegate

// Sent to the delegate to determine whether the sign up request should be submitted to the server.
- (BOOL)signUpViewController:(PFSignUpViewController *)signUpController shouldBeginSignUp:(NSDictionary *)info
{
    BOOL informationComplete = YES;
    
    // Loop through all of the submitted data
    for (id key in info) {
        NSString *field = info[key];
        if (!field || field.length == 0) { // Check completion
            informationComplete = NO;
            break;
        }
    }
    
    // Display an alert if a field wasn't completed
    if (!informationComplete) {
        [[[UIAlertView alloc] initWithTitle:@"Missing Information"
                                    message:@"Make sure you fill out all of the information!"
                                   delegate:nil
                          cancelButtonTitle:@"Ok"
                          otherButtonTitles:nil] show];
    }
    
    return informationComplete;
}

// Sent to the delegate when a PFUser is signed up.
- (void)signUpViewController:(PFSignUpViewController *)signUpController didSignUpUser:(PFUser *)user
{
    // Dismiss sign up view controller
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)enterTheApp
{
    MainTabBarViewController *tabBarController = [[MainTabBarViewController alloc] init];
    [self presentViewController:tabBarController animated:YES completion:nil];
}

@end
