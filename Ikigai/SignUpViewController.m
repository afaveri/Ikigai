//
//  SignUpViewController.m
//  Ikigai
//
//  Created by Alexandre Perozim de Faveri on 7/10/15.
//  Copyright (c) 2015 Team Ikigai. All rights reserved.
//

#import "SignUpViewController.h"

@implementation SignUpViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.signUpView setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"goldens.png"]]];
    [self.signUpView setLogo:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"rsz_6logo.png"]]];
    
    [self.signUpView.signUpButton setBackgroundImage:[UIImage imageNamed:@"signUpButton.png"] forState:UIControlStateNormal];
    [self.signUpView.signUpButton setAlpha:0.5];
    
    [self.signUpView.usernameField setBackgroundColor:[UIColor grayColor]];
    [self.signUpView.passwordField setBackgroundColor:[UIColor grayColor]];
    [self.signUpView.emailField setBackgroundColor:[UIColor grayColor]];
    
    [self.signUpView.usernameField setTextColor:[UIColor whiteColor]];
    [self.signUpView.passwordField setTextColor:[UIColor whiteColor]];
    [self.signUpView.emailField setTextColor:[UIColor whiteColor]];
    
    [self.signUpView.emailField setAlpha:0.5];
    [self.signUpView.usernameField setAlpha:0.5];
    [self.signUpView.passwordField setAlpha:0.5];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    // Set frame for elements
    [self.signUpView.logo setFrame:CGRectMake(40.0f, 100.0f, 300.0f, 120.0f)];
}

@end
