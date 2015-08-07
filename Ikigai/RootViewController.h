//
//  RootViewController.h
//  Ikigai
//
//  Created by Alexandre Perozim de Faveri on 7/8/15.
//  Copyright (c) 2015 Team Ikigai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ParseUI/ParseUI.h>

@interface RootViewController : UIViewController <PFLogInViewControllerDelegate, PFSignUpViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

- (void)enterTheApp;

@end
