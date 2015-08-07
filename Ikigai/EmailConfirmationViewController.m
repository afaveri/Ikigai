//
//  EmailConfirmationViewController.m
//  Ikigai
//
//  Created by Alexandre Perozim de Faveri on 7/10/15.
//  Copyright (c) 2015 Team Ikigai. All rights reserved.
//

#import <Parse/Parse.h>
#import "EmailConfirmationViewController.h"
#import "RootViewController.h"

@implementation EmailConfirmationViewController

static const CGFloat kRefreshButtonLeftFromCenter = -80.0;
static const CGFloat kRefreshButtonTopFromCenter = -30.0;
static const CGFloat kRefreshButtonWidth = 160.0;
static const CGFloat kRefreshButtonHeight = 40.0;

static const CGFloat kBackButtonLeftFromCenter =  -80.0;
static const CGFloat kBackButtonTopFromCenter = 30.0;
static const CGFloat kBackButtonWidth = 160.0;
static const CGFloat kBackButtonHeight = 40.0;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Email Confirmation"
                                                    message:@"Please authenticate your account in the link that was sent to your email and click refresh."
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
    
    // Refresh button
    UIButton *refresh = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [refresh addTarget:self
               action:@selector(verifyEmail:)
     forControlEvents:UIControlEventTouchUpInside];
    [refresh setTitle:@"Refresh" forState:UIControlStateNormal];
    refresh.frame = CGRectMake(self.view.center.x + kRefreshButtonLeftFromCenter,
                               self.view.center.y + kRefreshButtonTopFromCenter,
                               kRefreshButtonWidth, kRefreshButtonHeight);
    [self.view addSubview:refresh];
    
    // Back button
    UIButton *back = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [back addTarget:self
                action:@selector(backToLogin:)
      forControlEvents:UIControlEventTouchUpInside];
    [back setTitle:@"Back to Login" forState:UIControlStateNormal];
    back.frame = CGRectMake(self.view.center.x + kBackButtonLeftFromCenter,
                            self.view.center.y + kBackButtonTopFromCenter,
                            kBackButtonWidth, kBackButtonHeight);
    [self.view addSubview:back];
}

- (IBAction)backToLogin:(id)sender
{
    [PFUser logOutInBackgroundWithBlock:^(NSError *error){
        if (!error) {
            [self dismissViewControllerAnimated:YES completion:nil];
        } else {
            NSLog(@"Error: %@ %@", error, [error userInfo]);
        }
    }];
    
}

- (IBAction)verifyEmail:(id)sender
{
    PFUser *currentUser = [PFUser currentUser];
    
    [currentUser fetchInBackgroundWithBlock:^void(PFObject *user, NSError *error){
        if (!user) {
            // Error
            NSLog(@"Error: %@ %@", error, [error userInfo]);
        } else if ([user[@"emailVerified"]  boolValue]) {
            // Use the app!
            [self dismissViewControllerAnimated:YES completion:nil];
        } else {
            UIAlertView *failure = [[UIAlertView alloc] initWithTitle:@"Email Not Verified"
                                                            message:@"Please authenticate your account in the link that was sent to your email and click refresh."
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [failure show];
        }
    }];
}

@end
