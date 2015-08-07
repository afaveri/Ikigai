//
//  IKIPublishVideoViewController.m
//  Ikigai
//
//  Created by Priscilla Guo on 7/20/15.
//  Copyright (c) 2015 Team Ikigai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import <Parse/Parse.h>
#import <ParseUI/ParseUI.h>
#import <GoogleMaps/GoogleMaps.h>
#import "IKIPublishVideoViewController.h"
#import "MainTabBarViewController.h"
#import "FeedTableViewController.h"
#import "PlacePickerViewController.h"
#import "MapsViewController.h"

@interface IKIPublishVideoViewController ()

@property (strong, nonatomic) AVPlayerViewController *playerViewController;

@property (weak, nonatomic) IBOutlet UIView *playerView;
@property (weak, nonatomic) IBOutlet UIView *postView;
@property (weak, nonatomic) IBOutlet UITextField *playerTitle;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIButton *postButton;
@property (weak, nonatomic) IBOutlet UILabel *name;
@property (weak, nonatomic) IBOutlet UILabel *date;
@property (weak, nonatomic) IBOutlet UILabel *location;
@property (weak, nonatomic) IBOutlet UILabel *separator;
@property (weak, nonatomic) IBOutlet UIImageView *profilePicture;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@property (strong, nonatomic) PFFile *videoFile;
@property (assign, nonatomic) CLLocationCoordinate2D currentSelectedLocation; // The coordinates of the current selected location, if it is not a place. Default is user's location
@property (strong, nonatomic) GMSPlace *place; // The place selected by the user. nil if none explicitly selected

@end

static const NSInteger kProfileButtonIndex = 0;
static const NSInteger kFeedButtonIndex = 2;
static const CGFloat kCornerRadius = 8.0;
static const CGFloat kBorderWidth = 2.0;

@implementation IKIPublishVideoViewController
{
    BOOL _locationActivated;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.postView.layer.cornerRadius = kCornerRadius;
    [self.postView.layer setBorderColor: [[UIColor blackColor] CGColor]];
    [self.postView.layer setBorderWidth:kBorderWidth];
    
    self.playerTitle.layer.cornerRadius = kCornerRadius;
    [self.playerTitle.layer setBorderColor: [[UIColor blackColor] CGColor]];
    [self.playerTitle.layer setBorderWidth:kBorderWidth];
    
    self.postButton.layer.cornerRadius = kCornerRadius;
    [self.postButton.layer setBorderColor: [[UIColor blackColor] CGColor]];
    [self.postButton.layer setBorderWidth:kBorderWidth];
    
    [self registerForKeyboardNotifications];
    
    _locationActivated = NO;
    [self.location setHidden:YES];
    [self.separator setHidden:YES];
    
    // Allow taps to be detected
    self.location.userInteractionEnabled = YES;
    
    // Set up the navigation bar
    UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithTitle:@"Cancel"
                                                               style:UIBarButtonItemStylePlain
                                                              target:self
                                                              action:@selector(didCancel:)];
    UIBarButtonItem *location = [[UIBarButtonItem alloc] initWithTitle:@"Add Location"
                                                                 style:UIBarButtonItemStylePlain
                                                                target:self
                                                                action:@selector(changeLocationStatus:)];
    self.navigationItem.leftBarButtonItem = cancel;
    self.navigationItem.rightBarButtonItem = location;
    self.navigationItem.title = @"Preview";
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    // Load data and allow user to enter a title for the video player
    PFUser *user = [PFUser currentUser];
    [user fetchFromLocalDatastoreInBackgroundWithBlock:^(PFObject *user, NSError *error) {
        if (!user) {
            NSLog(@"Error: %@ %@", error, [error userInfo]);
        } else {
            self.date.text = @"Just now";
            
            NSURL *fileURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"post.mp4"]];
            
            // Video playback
            self.playerViewController = [[AVPlayerViewController alloc] init];
            self.playerViewController.player = [AVPlayer playerWithURL:fileURL];
            self.playerViewController.view.frame = self.playerView.frame;
            [self addChildViewController:self.playerViewController];
            [self.playerView.superview addSubview:self.playerViewController.view];
            
            self.name.text = (user[@"name"] != nil && ! [user[@"name"] isEqualToString:@""]) ? user[@"name"] : user[@"username"];
            
            PFFile *profilePicture = user[@"profilePicture"];
            [profilePicture getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
                if (!error) {
                    self.profilePicture.image = [UIImage imageWithData:data];
                } else {
                    NSLog(@"Error: %@", [error localizedDescription]);
                }
            }];
        }
    }];
}

- (IBAction)changeLocationStatus:(UIBarButtonItem *)sender
{
    if (_locationActivated) {
        // Change the navigation bar button
        UIBarButtonItem *add = [[UIBarButtonItem alloc] initWithTitle:@"Add Location"
                                                                style:UIBarButtonItemStylePlain
                                                               target:self
                                                               action:@selector(changeLocationStatus:)];
        self.navigationItem.rightBarButtonItem = add;
        _locationActivated = NO;
        [self.location setHidden:YES];
        [self.separator setHidden:YES];
        self.place = nil;
    } else {
        // Pick a place
        PlacePickerViewController *ppvc = [[PlacePickerViewController alloc] init];
        ppvc.delegate = self;
        UINavigationController *ppnc = [[UINavigationController alloc] initWithRootViewController:ppvc];
        
        [self presentViewController:ppnc animated:YES completion:nil];
    }
}

- (IBAction)showLocation:(id)sender
{
    PFObject *post = [PFObject objectWithClassName:@"Post"];
    post[@"title"] = self.titleLabel.text;
    post[@"locationText"] = self.location.text;
    
    CLLocationCoordinate2D location;
    
    if (self.place == nil) { // Use current location
        location = self.currentSelectedLocation;
    } else { // Use  the place's location
        location = CLLocationCoordinate2DMake(self.place.coordinate.latitude, self.place.coordinate.longitude);
    }
    post[@"locationPoint"] = [PFGeoPoint geoPointWithLatitude:location.latitude
                                               longitude:location.longitude];
    MapsViewController *mvc = [[MapsViewController alloc] initWithPost:post];
    UINavigationController *mnc = [[UINavigationController alloc] initWithRootViewController:mvc];
    [self presentViewController:mnc animated:YES completion:nil];
}

#pragma mark - PlacePickerDelegate

- (void)didPickPlace:(GMSPlace *)place
{
    // Change the navigation bar button
    UIBarButtonItem *remove = [[UIBarButtonItem alloc] initWithTitle:@"Remove Location"
                                                               style:UIBarButtonItemStylePlain
                                                              target:self
                                                              action:@selector(changeLocationStatus:)];
    self.navigationItem.rightBarButtonItem = remove;
    _locationActivated = YES;
    [self.location setHidden:NO];
    [self.separator setHidden:NO];
    
    if (! [place.types containsObject:@"synthetic_geocode"]) { // Actually selected a place
        self.place = place;
        self.location.text = [NSString stringWithFormat:@"at %@", self.place.name];
    } else { // Selected a location but not a place. Should display the city of the selected place
        self.place = nil;
        
        // Store location
        self.currentSelectedLocation = place.coordinate;
        
        // Find the city
        CLGeocoder *geoCoder = [[CLGeocoder alloc] init];
        [geoCoder reverseGeocodeLocation:[[CLLocation alloc] initWithLatitude:place.coordinate.latitude longitude:place.coordinate.longitude]
                       completionHandler:^(NSArray *placemarks, NSError *error) {
                           if (error) {
                               NSLog(@"Error: %@", [error localizedDescription]);
                           } else {
                               CLPlacemark *placemark = [placemarks firstObject];
                               if ([placemark locality] && [placemark country]) {
                                   if ([[placemark country] isEqualToString:@"United States"] && [placemark administrativeArea]) { // Show city and state
                                       self.location.text = [NSString stringWithFormat:@"in %@, %@", [placemark locality], [placemark administrativeArea]];
                                   } else { // Show city and country
                                       self.location.text = [NSString stringWithFormat:@"in %@, %@", [placemark locality], [placemark country]];
                                   }
                               } else if ([placemark name]) { // Show name of isolated place
                                  self.location.text = [NSString stringWithFormat:@"in %@", [placemark name]];
                               } else if ([placemark region]) { // Show name of region
                                   self.location.text = [NSString stringWithFormat:@"in %@", [placemark region]];
                               } else { // Show generic message
                                   self.location.text = [NSString stringWithFormat:@"in Planet Earth"];
                               }
                           }
                       }];
    }
}

- (void)didCancelPickingPlace
{
    _locationActivated = YES;
    [self changeLocationStatus:nil];
    
}

#pragma mark - Text Field Delegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    self.titleLabel.text = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    return YES;
}

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

- (IBAction)didCancel:(id)sender
{
    ((UITabBarController *)self.presentingViewController).selectedIndex = kProfileButtonIndex;
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)handlePostingError:(NSError *)error
{
    NSLog(@"Error: %@", [error localizedDescription]);
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                    message:[NSString stringWithFormat:@"%@", [error localizedDescription]]
                                                   delegate:nil cancelButtonTitle:@"Ok"
                                          otherButtonTitles:nil];
    [alert show];
    
    // Remove activity indicator
    [self.postButton.subviews[0] removeFromSuperview];
    [self.postButton addSubview:self.postButton.titleLabel];
    // Enable button
    [self.postButton setEnabled:YES];
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
    NSDictionary * info = [aNotification userInfo];
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

- (void)createPostWithFile:(PFFile *)videoFile
{
    PFUser *currentUser = [PFUser currentUser];
    
    // Create post
    PFObject *post = [PFObject objectWithClassName:@"Post"];
    
    post[@"title"] = self.playerTitle.text;
    post[@"canonicalTitle"] = [self.playerTitle.text lowercaseString];
    post[@"views"] = @0;
    post[@"parent"] = [PFUser currentUser];
    post[@"video"] = videoFile;
    
    // Find the maximum index number and assign new post the next index number.
    PFQuery *query = [PFQuery queryWithClassName:@"Post"];
    [query orderByDescending:@"index"];
    
    [query getFirstObjectInBackgroundWithBlock:^(PFObject *maxIndexVideo, NSError *error) {
        if (!error) {
            NSInteger maxIndex = [(NSNumber *)maxIndexVideo[@"index"] integerValue];
            NSInteger nextIndex = maxIndex + 1;
            post[@"index"] = [NSNumber numberWithInteger:nextIndex];
            
            if (_locationActivated) { // Save location
                if (self.place == nil) {
                    post[@"locationPoint"] = [PFGeoPoint geoPointWithLatitude:self.currentSelectedLocation.latitude longitude:self.currentSelectedLocation.longitude];
                    post[@"locationText"] = self.location.text;
                } else {
                    post[@"locationPoint"] = [PFGeoPoint geoPointWithLatitude:self.place.coordinate.latitude longitude:self.place.coordinate.longitude];
                    post[@"locationText"] = self.location.text;
                }
            }
            
            // Save to Parse
            [post saveInBackgroundWithBlock:^(BOOL success, NSError *error) {
                if (success) {
                    PFRelation *posts = currentUser[@"posts"];
                    [posts addObject:post];
                    [currentUser saveInBackgroundWithBlock:^(BOOL success, NSError *error) {
                        if (success) {
                            // Reload feed and show it
                            MainTabBarViewController *tbc = (MainTabBarViewController *)self.navigationController.presentingViewController;
                            UINavigationController *fnc = tbc.viewControllers[kFeedButtonIndex];
                            tbc.selectedIndex = kFeedButtonIndex;
                            [self dismissViewControllerAnimated:YES completion:nil];
                            [(FeedTableViewController *)fnc.viewControllers[0] loadObjects];
                            [((FeedTableViewController *)fnc.viewControllers[0]).tableView scrollRectToVisible:CGRectMake(0.0, 44.0, 1.0, 1.0) animated:YES];
                        } else {
                            [self handlePostingError:error];
                        }
                    }];
                } else {
                    [self handlePostingError:error];
                }
            }];
        } else {
            NSLog(@"Error: %@", [error localizedDescription]);
        }
    }];
}

-(IBAction)postToParse:(id)sender
{
    // Check if file is larger than 10 MB
    NSString *fileName = @"post.mp4";
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[NSTemporaryDirectory() stringByAppendingPathComponent:fileName] error:nil];
    unsigned long long fileSize = [attributes fileSize]; // Result in bytes
    
    if (fileSize > 10485760) { // Too large
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Video file is too large"
                                                                       message:@"Videos must be at most 10 MB"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Ok"
                                                     style:UIAlertActionStyleCancel
                                                   handler:nil];
        [alert addAction:ok];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    
    // Show activity indicator instead of post button
    [self.postButton setEnabled:NO];
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    activityIndicator.color = [UIColor blackColor];
    [activityIndicator setCenter:CGPointMake(self.postButton.frame.size.width / 2,
                                             self.postButton.frame.size.height / 2)];
    [self.postButton.titleLabel removeFromSuperview];
    [self.postButton addSubview:activityIndicator];
    [activityIndicator startAnimating];
    
    NSURL *videoURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:fileName]];
    NSData *videoData = [NSData dataWithContentsOfURL:videoURL];
    PFFile *videoFile = [PFFile fileWithName:@"video.mp4" data:videoData];
    
    [videoFile saveInBackgroundWithBlock:^(BOOL success, NSError *error){
        if (success) {
            PFUser *currentUser = [PFUser currentUser];
            [currentUser fetchFromLocalDatastoreInBackgroundWithBlock:^(PFObject *user, NSError *error) {
                if (!user) {
                    [self handlePostingError:error];
                } else {
                    self.name.text = user[@"name"];
                    [user[@"profilePicture"] getDataInBackgroundWithBlock:^(NSData *imageData, NSError *error) {
                        if (!error) {
                            // Set profile picture
                            self.profilePicture.image = [UIImage imageWithData:imageData];
                            
                            [self createPostWithFile:videoFile];
                        } else {
                            [self handlePostingError:error];
                        }
                    }];
                    
                    if (!user[@"profilePicture"]) { // Block didn't execute
                        [self createPostWithFile:videoFile];
                    }
                }
            }];
        } else {
            [self handlePostingError:error];
        }
    }];
}

@end