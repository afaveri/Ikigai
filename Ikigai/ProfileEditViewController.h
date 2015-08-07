//
//  ProfileEditViewController.h
//  Ikigai
//
//  Created by Alexandre Perozim de Faveri on 7/6/15.
//  Copyright (c) 2015 Team Ikigai. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ProfileEditViewController;
@class ProfileViewController;

@interface ProfileEditViewController : UIViewController <UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIAlertViewDelegate, UIPickerViewDataSource, UIPickerViewDelegate>

@property (assign, nonatomic) NSInteger numberOfPosts;
@property (assign, nonatomic) NSInteger numberOfFollowers;
@property (assign, nonatomic) NSInteger numberOfFollowing;

- (void)registerForKeyboardNotifications;

@end
