//
//  ProfileEditViewController.m
//  Ikigai
//
//  Created by Alexandre Perozim de Faveri on 7/6/15.
//  Copyright (c) 2015 Team Ikigai. All rights reserved.
//

#import <Parse/Parse.h>
#import "ProfileEditViewController.h"
#import "ProfileViewController.h"
#import "FieldsPickerConstants.h"

@import MobileCoreServices;

@interface ProfileEditViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *profilePicture;
@property (weak, nonatomic) IBOutlet UIImageView *activityData;
@property (weak, nonatomic) IBOutlet UIImageView *activityDataDivisor;
@property (weak, nonatomic) IBOutlet UIImageView *coverPhoto;

@property (weak, nonatomic) IBOutlet UITextField *name;
@property (weak, nonatomic) IBOutlet UITextField *username;
@property (weak, nonatomic) IBOutlet UILabel *email;
@property (weak, nonatomic) IBOutlet UITextField *age;
@property (weak, nonatomic) IBOutlet UITextField *gender;
@property (weak, nonatomic) IBOutlet UITextField *race;
@property (weak, nonatomic) IBOutlet UITextField *sexualOrientation;
@property (weak, nonatomic) IBOutlet UITextField *country;
@property (weak, nonatomic) IBOutlet UITextField *city;
@property (weak, nonatomic) IBOutlet UITextField *education;
@property (weak, nonatomic) IBOutlet UITextField *occupation;
@property (weak, nonatomic) IBOutlet UITextField *religion;
@property (weak, nonatomic) IBOutlet UITextField *birthDate;
@property (weak, nonatomic) IBOutlet UITextField *relationshipStatus;
@property (weak, nonatomic) IBOutlet UITextField *politicalViews;
@property (weak, nonatomic) IBOutlet UILabel *followers;
@property (weak, nonatomic) IBOutlet UILabel *following;
@property (weak, nonatomic) IBOutlet UILabel *posts;

@property (weak, nonatomic) IBOutlet UIButton *changePictureButton;
@property (weak, nonatomic) IBOutlet UIButton *changeCoverPhotoButton;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@end

@implementation ProfileEditViewController
{
    BOOL _changedProfilePicture;
    BOOL _changedCoverPhoto;
}

static const NSInteger kProfilePictureTag = 0;
static const NSInteger kCoverPhotoTag = 1;

#pragma mark - Buttons

- (IBAction)resetPassword:(id)sender
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Reset Password"
                                                    message:@"Are you sure you want to change your password?"
                                                   delegate:self
                                          cancelButtonTitle:@"No"
                                          otherButtonTitles:@"Yes", nil];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) { // Yes
        // Send reset password email
        [PFUser requestPasswordResetForEmailInBackground:self.email.text];
        
        // Alert the user
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Reset Password"
                                                        message:@"Success! You will receive a password reset email soon."
                                                       delegate:nil
                                              cancelButtonTitle:@"Ok"
                                              otherButtonTitles:nil];
        [alert show];
    }
}

- (IBAction)chooseProfilePicture:(id)sender
{
    [self startMediaBrowserFromViewController:self
                                usingDelegate:self
                                      withTag:kProfilePictureTag];
}

- (IBAction)chooseCoverPhoto:(id)sender
{
    [self startMediaBrowserFromViewController:self
                                usingDelegate:self
                                      withTag:kCoverPhotoTag];
}


- (IBAction)exitEditModeWithoutSaving:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)exitEditModeSaving:(id)sender
{
    // Show activity indicator instead of done button
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    activityIndicator.color = [UIColor whiteColor];
    UIBarButtonItem * barButton = [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];
    [self navigationItem].rightBarButtonItem = barButton;
    [activityIndicator startAnimating];
    
    if ([self.age.text integerValue] > 100 || [self.age.text integerValue] < 0) { // Prompt user for wrong age
        // Reactivate done button
        UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                              target:self
                                                                              action:@selector(exitEditModeSaving:)];
        self.navigationItem.rightBarButtonItem = done;
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Age out of bounds"
                                                        message:@"Age should be between 0 and 100. Please fix that field and try again."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    PFQuery *query = [PFUser query];
    [query whereKey:@"username" equalTo:self.username.text];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
        if (!error) {
            PFUser *user = [PFUser currentUser];
            [user fetchFromLocalDatastoreInBackgroundWithBlock:^(PFObject *user, NSError *error) {
                if (!error) {
                    if (objects.count == 0 || [self.username.text isEqualToString:user[@"username"]]) {
                        // Save Changes
                        PFUser *user = [PFUser currentUser];
                        
                        user[@"name"] =                 self.name.text;
                        user[@"username"] =             self.username.text;
                        user[@"canonicalUsername"] =    [self.username.text lowercaseString];
                        user[@"age"] =                  [NSNumber numberWithInteger:[self.age.text integerValue]];
                        user[@"gender"] =               self.gender.text;
                        user[@"race"] =                 self.race.text;
                        user[@"sexualOrientation"] =    self.sexualOrientation.text;
                        user[@"country"] =              self.country.text;
                        user[@"city"] =                 self.city.text;
                        user[@"education"] =            self.education.text;
                        user[@"occupation"] =           self.occupation.text;
                        user[@"religion"] =             self.religion.text;
                        user[@"birthDate"] =            self.birthDate.text;
                        user[@"relationshipStatus"] =   self.relationshipStatus.text;
                        user[@"politicalViews"] =       self.politicalViews.text;
                        
                        // Save lower case fields for search
                        user[@"canonicalName"] =        [self.name.text lowercaseString];
                        user[@"canonicalOccupation"] =  [self.occupation.text lowercaseString];
                        user[@"canonicalEducation"] =   [self.education.text lowercaseString];
                        user[@"canonicalCity"] =        [self.city.text lowercaseString];
                        
                        
                        
                        
                        if (_changedProfilePicture) {
                            // Save the profile picture
                            NSData *profilePictureData = UIImagePNGRepresentation(self.profilePicture.image);
                            PFFile *profilePictureFile = [PFFile fileWithName:@"profilePicture.png" data:profilePictureData];
                            user[@"profilePicture"] = profilePictureFile;
                            [profilePictureFile saveInBackground];
                        }
                        
                        if (_changedCoverPhoto) {
                            // Save the cover photo
                            NSData *coverPhotoData = UIImagePNGRepresentation(self.coverPhoto.image);
                            PFFile *coverPhotoFile = [PFFile fileWithName:@"coverPhoto.png" data:coverPhotoData];
                            user[@"coverPhoto"] = coverPhotoFile;
                            [coverPhotoFile saveInBackground];
                        }
                        
                        [user saveInBackgroundWithBlock:^void(BOOL success, NSError *error) {
                            if (success) {
                                [self dismissViewControllerAnimated:YES completion:nil];
                            } else {
                                // Error
                                NSLog(@"Error: %@ %@", error, [error userInfo]);
                                [user saveEventually];
                                [self dismissViewControllerAnimated:YES completion:nil];
                            }
                        }];
                    } else {
                        // Reactivate done button
                        UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                              target:self
                                                                                              action:@selector(exitEditModeSaving:)];
                        self.navigationItem.rightBarButtonItem = done;
                        
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Username Taken"
                                                                        message:@"Please choose an available username"
                                                                       delegate:nil
                                                              cancelButtonTitle:@"OK"
                                                              otherButtonTitles:nil];
                        [alert show];
                        return;
                    }
                } else {
                    NSLog(@"Error: %@ %@", error, [error userInfo]);
                }
            }];
        } else {
            NSLog(@"Error: %@ %@", error, [error userInfo]);
        }
    }];
}

#pragma mark - Keyboard Actions

// Dismisses keyboard when user presses return
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    
    return YES;
}

// Dismisses keyboard when user taps outside the text field
- (IBAction)hideKeyboard:(id)sender
{
    [self.view endEditing:YES];
}

// Call this method in the view controller setup code.
- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
}

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWasShown:(NSNotification *)aNotification
{
    NSDictionary *info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;

    // Create content insets compatible with the navigation bar
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(self.scrollView.contentInset.top, 0.0, kbSize.height + 20, 0.0);
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification *)aNotification
{
    // Create content insets compatible with the navigation bar
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(self.scrollView.contentInset.top, 0.0, 0.0, 0.0);
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
}


#pragma mark - Image Picker


// Presents a browser that provides access to all the photo albums on the device
- (BOOL)startMediaBrowserFromViewController:(UIViewController *)controller
                              usingDelegate:(id <UIImagePickerControllerDelegate,
                                             UINavigationControllerDelegate>)delegate
                                    withTag:(NSInteger)tag
{
    if (([UIImagePickerController isSourceTypeAvailable:
          UIImagePickerControllerSourceTypePhotoLibrary] == NO)
        || (delegate == nil)
        || (controller == nil))
        return NO;
    
    UIImagePickerController *mediaUI = [[UIImagePickerController alloc] init];
    mediaUI.view.tag = tag;
    
    // Displays saved pictures from the photo library
    mediaUI.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    mediaUI.mediaTypes = [[NSArray alloc] initWithObjects: (NSString *) kUTTypeImage, nil];
    
    // Shows the controls for moving & scaling pictures
    mediaUI.allowsEditing = YES;
    
    mediaUI.delegate = delegate;
    
    [controller presentViewController:mediaUI animated:YES completion:nil];
    
    return YES;
}

// Sets the picked image as the profile picture
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSString *mediaType = [info objectForKey: UIImagePickerControllerMediaType];
    UIImage *editedImage;
    
    // Handle a still image picked from a photo album
    if (CFStringCompare((CFStringRef)mediaType, kUTTypeImage, 0) == kCFCompareEqualTo) {
        editedImage = (UIImage *) [info objectForKey:UIImagePickerControllerEditedImage];
        
        if (picker.view.tag == kProfilePictureTag) {
            // Set this image as the profile picture
            self.profilePicture.image = editedImage;
            _changedProfilePicture = YES;
        } else if (picker.view.tag == kCoverPhotoTag) {
            // Set this image as the profile picture
            self.coverPhoto.image = editedImage;
            _changedCoverPhoto = YES;
        }
    }
    
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Picker View Delegate

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    if (pickerView.tag == kGenderTag) {
        self.gender.text = [self pickerDataForPicker:pickerView][row];
    } else if (pickerView.tag == kRaceTag) {
        self.race.text = [self pickerDataForPicker:pickerView][row];
    } else if (pickerView.tag == kSexualOrientationTag) {
        self.sexualOrientation.text = [self pickerDataForPicker:pickerView][row];
    } else if (pickerView.tag == kCountryTag) {
        self.country.text = [self pickerDataForPicker:pickerView][row];
    } else if (pickerView.tag == kReligionTag) {
        self.religion.text = [self pickerDataForPicker:pickerView][row];
    } else if (pickerView.tag == kRelationshipStatusTag) {
        self.relationshipStatus.text = [self pickerDataForPicker:pickerView][row];
    } else if (pickerView.tag == kPoliticalViewsTag) {
        self.politicalViews.text = [self pickerDataForPicker:pickerView][row];
    } else {
        NSLog(@"Error: tag could not be identified");
    }
}

#pragma mark - Picker View Data source

// The number of columns of data
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

// The number of rows of data
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [self pickerDataForPicker:pickerView].count;
}

// The data to return for the row and component (column) that's being passed in
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [self pickerDataForPicker:pickerView][row];
}

- (NSArray *)pickerDataForPicker:(UIPickerView *)pickerView
{
    if (pickerView.tag == kGenderTag) { // Get list of genders
        return [FieldsPickerConstants getGenders];
    } else if (pickerView.tag == kRaceTag) { // Get list of races
        return [FieldsPickerConstants getRaces];
    } else if (pickerView.tag == kSexualOrientationTag) { // Get list of sexual orientations
        return [FieldsPickerConstants getSexualOrientations];
    } else if (pickerView.tag == kCountryTag) { // Get list of countries
        return [FieldsPickerConstants getCountries];
    } else if (pickerView.tag == kReligionTag) { // Get list of religions
        return [FieldsPickerConstants getReligions];
    } else if (pickerView.tag == kRelationshipStatusTag) { // Get list of relationship statuses
        return [FieldsPickerConstants getRelationshipStatuses];
    } else if (pickerView.tag == kPoliticalViewsTag) { // Get list of political views
        return [FieldsPickerConstants getPoliticalViews];
    } else { // Handle error
        NSLog(@"Error: tag could not be identified");
        return nil;
    }
}

- (IBAction)birthDateDidChange:(id)sender
{
    NSDate *birthDate = ((UIDatePicker *)sender).date;
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterLongStyle];
    
    self.birthDate.text = [formatter stringFromDate:birthDate];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self getActivityData];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    self.changeCoverPhotoButton.layer.cornerRadius = 2.0;
    
    self.changePictureButton.layer.cornerRadius = 5.0;
    
    self.profilePicture.layer.cornerRadius = 8.0;
    [self.profilePicture.layer setBorderColor: [[UIColor blackColor] CGColor]];
    [self.profilePicture.layer setBorderWidth: 2.0];
    
    self.activityData.layer.cornerRadius = 8.0;
    [self.activityData.layer setBorderColor: [[UIColor blackColor] CGColor]];
    [self.activityData.layer setBorderWidth: 2.0];
    
    [self.activityDataDivisor.layer setBorderColor: [[UIColor blackColor] CGColor]];
    [self.activityDataDivisor.layer setBorderWidth: 2.0];
    
    _changedProfilePicture = NO;
    _changedCoverPhoto = NO;
    
    // Create toolbar for pickers
    UIToolbar *toolbar = [[UIToolbar alloc] init];
    toolbar.frame = CGRectMake(0, 0, self.view.frame.size.width, 42);
    UIBarButtonItem *toolbarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self
                                                                                   action:@selector(hideKeyboard:)];
    toolbar.items = @[toolbarButton];

    // Set up pickers for some text fields
    
    UIPickerView *genderPicker = [[UIPickerView alloc] init];
    genderPicker.tag = kGenderTag;
    genderPicker.delegate = self;
    genderPicker.dataSource = self;
    self.gender.inputView = genderPicker;
    self.gender.inputAccessoryView = toolbar;
    
    UIPickerView *racePicker = [[UIPickerView alloc] init];
    racePicker.tag = kRaceTag;
    racePicker.delegate = self;
    racePicker.dataSource = self;
    self.race.inputView = racePicker;
    self.race.inputAccessoryView = toolbar;
    
    UIPickerView *sexualOrientationPicker = [[UIPickerView alloc] init];
    sexualOrientationPicker.tag = kSexualOrientationTag;
    sexualOrientationPicker.delegate = self;
    sexualOrientationPicker.dataSource = self;
    self.sexualOrientation.inputView = sexualOrientationPicker;
    self.sexualOrientation.inputAccessoryView = toolbar;
    
    UIPickerView *countryPicker = [[UIPickerView alloc] init];
    countryPicker.tag = kCountryTag;
    countryPicker.delegate = self;
    countryPicker.dataSource = self;
    self.country.inputView = countryPicker;
    self.country.inputAccessoryView = toolbar;
    
    UIPickerView *religionPicker = [[UIPickerView alloc] init];
    religionPicker.tag = kReligionTag;
    religionPicker.delegate = self;
    religionPicker.dataSource = self;
    self.religion.inputView = religionPicker;
    self.religion.inputAccessoryView = toolbar;
    
    UIPickerView *ralationshipStatusPicker = [[UIPickerView alloc] init];
    ralationshipStatusPicker.tag = kRelationshipStatusTag;
    ralationshipStatusPicker.delegate = self;
    ralationshipStatusPicker.dataSource = self;
    self.relationshipStatus.inputView = ralationshipStatusPicker;
    self.relationshipStatus.inputAccessoryView = toolbar;
    
    UIPickerView *politicalViewsPicker = [[UIPickerView alloc] init];
    politicalViewsPicker.tag = kPoliticalViewsTag;
    politicalViewsPicker.delegate = self;
    politicalViewsPicker.dataSource = self;
    self.politicalViews.inputView = politicalViewsPicker;
    self.politicalViews.inputAccessoryView = toolbar;
    
    // Set up birth date picker
    UIDatePicker *birthDatePicker = [[UIDatePicker alloc] init];
    birthDatePicker.datePickerMode = UIDatePickerModeDate;
    [birthDatePicker setMaximumDate:[NSDate date]];
    [birthDatePicker addTarget:self
                             action:@selector(birthDateDidChange:)
                forControlEvents:UIControlEventValueChanged];
    self.birthDate.inputView = birthDatePicker;
    
    // Set navigation bar
    self.navigationItem.title = @"Edit Profile";
    
    UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                            target:self
                                                                            action:@selector(exitEditModeWithoutSaving:)];
    
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                          target:self
                                                                          action:@selector(exitEditModeSaving:)];
    // Disable done button until the fetch is complete to avoid data loss
    [done setEnabled:NO];
    
    self.navigationItem.rightBarButtonItem = done;
    self.navigationItem.leftBarButtonItem = cancel;
    
    // Get data to fill all the fields
    PFUser *currentUser = [PFUser currentUser];

    [currentUser fetchFromLocalDatastoreInBackgroundWithBlock:^(PFObject *user, NSError *error){
        if (!user) {
            NSLog(@"Error: %@ %@", error, [error userInfo]);
        } else {
            self.name.text =                user[@"name"];
            self.username.text =            user[@"username"];
            self.email.text =               user[@"email"];
            self.age.text =                 [user[@"age"] stringValue];
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
            
            
            [user[@"profilePicture"] getDataInBackgroundWithBlock:^(NSData *imageData, NSError *error) {
                if (!error) {
                    self.profilePicture.image = [UIImage imageWithData:imageData]; // Finish loading image
                    [user[@"coverPhoto"] getDataInBackgroundWithBlock:^(NSData *imageData, NSError *error) {
                        if (!error) {
                            self.coverPhoto.image = [UIImage imageWithData:imageData]; // Finish loading image
                            // Data fetch is complete; enable done button
                            [done setEnabled:YES];
                        } else {
                            // Error
                            NSLog(@"Error: %@ %@", error, [error userInfo]);
                        }
                    }];
                    
                    if (! user[@"coverPhoto"]) {
                        // Data fetch is complete; enable done button
                        [done setEnabled:YES];
                    }
                } else {
                    // Error
                    NSLog(@"Error: %@ %@", error, [error userInfo]);
                }
            }];
            
            if (! user[@"profilePicture"]) {
                [user[@"coverPhoto"] getDataInBackgroundWithBlock:^(NSData *imageData, NSError *error) {
                    if (!error) {
                        self.coverPhoto.image = [UIImage imageWithData:imageData]; // Finish loading image
                        // Data fetch is complete; enable done button
                        [done setEnabled:YES];
                    } else {
                        // Error
                        NSLog(@"Error: %@ %@", error, [error userInfo]);
                    }
                }];
                
                if (! user[@"coverPhoto"]) {
                    // Data fetch is complete; enable done button
                    [done setEnabled:YES];
                }
            }
        }
    }];
}

- (void)getActivityData
{
    self.posts.text = [NSString stringWithFormat:@"%tu", self.numberOfPosts];
    self.following.text = [NSString stringWithFormat:@"%tu", self.numberOfFollowing];
    self.followers.text = [NSString stringWithFormat:@"%tu", self.numberOfFollowers];
}

@end
