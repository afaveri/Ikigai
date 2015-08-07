//
//  FeedCellViewController.m
//  Ikigai
//
//  Created by Alexandre Perozim de Faveri on 7/15/15.
//  Copyright (c) 2015 Team Ikigai. All rights reserved.
//

#import "FeedTableViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import <Parse/Parse.h>
#import "FeedCellViewController.h"
#import "PublicProfileViewController.h"
#import "MapsViewController.h"
#import "MainTabBarViewController.h"
#import "ProfileNavigationController.h"

@interface FeedCellViewController ()

@property (strong, nonatomic) AVPlayerViewController *playerViewController;
@property (strong, nonatomic) AVPlayerItem *playerItem;

@property (weak, nonatomic) IBOutlet UIView *playerView;
@property (weak, nonatomic) IBOutlet UIImageView *profilePicture;
@property (weak, nonatomic) IBOutlet UILabel *playerNumberOfViews;
@property (weak, nonatomic) IBOutlet UILabel *playerTitle;
@property (weak, nonatomic) IBOutlet UILabel *name;
@property (weak, nonatomic) IBOutlet UILabel *date;
@property (weak, nonatomic) IBOutlet UILabel *location;
@property (weak, nonatomic) IBOutlet UILabel *separator;
@property (weak, nonatomic) IBOutlet UIButton *delete;

@property (strong, nonatomic) UIActivityIndicatorView *spinner;

@end

@implementation FeedCellViewController
{
    BOOL _canIncreaseViewCount;
}

static const NSString *PostContext;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Properties for presentation in container (only when inside UINavigationController)
    self.edgesForExtendedLayout = UIRectEdgeNone;
    UIBarButtonItem *back = [[UIBarButtonItem alloc] initWithTitle:@"Back"
                                                             style:UIBarButtonItemStylePlain
                                                            target:self
                                                            action:@selector(didSelectBack:)];
    self.navigationItem.leftBarButtonItem = back;
    
    // Allow taps to be identified
    self.profilePicture.userInteractionEnabled = YES;
    self.name.userInteractionEnabled = YES;
    self.location.userInteractionEnabled = YES;
    
    // Create player view controller
    self.playerViewController = [[AVPlayerViewController alloc] init];
    self.playerViewController.view.frame = self.playerView.bounds;
    [self addChildViewController:self.playerViewController];
    [self.playerView addSubview:self.playerViewController.view];
    
    // Add activity indicator view
    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.spinner.hidesWhenStopped = YES;
    self.spinner.center = self.playerViewController.view.center;
    [self.playerViewController.view addSubview:self.spinner];

    // Update data if post changes
    [self addObserver:self forKeyPath:@"post" options:NSKeyValueObservingOptionNew context:&PostContext];
}

- (void)dealloc
{
    @try {
        [self removeObserver:self forKeyPath:@"post" context:&PostContext];
    } @catch (id anException) {
        // The view controller was dealloc'ed too fast
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (IBAction)didSelectBack:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)showProfile:(id)sender
{
    PublicProfileViewController *ppvc = [[PublicProfileViewController alloc] initWithUser:self.post[@"parent"]];
    ProfileNavigationController *ppnc = [[ProfileNavigationController alloc] initWithRootViewController:ppvc];
    [self presentViewController:ppnc animated:YES completion:nil];
}

- (IBAction)showLocation:(id)sender
{
    MapsViewController *mvc = [[MapsViewController alloc] initWithPost:self.post];
    UINavigationController *mnc = [[UINavigationController alloc] initWithRootViewController:mvc];
    [self presentViewController:mnc animated:YES completion:nil];
}

- (IBAction)deleteButton:(id)sender
{
    if ([PFUser currentUser] != self.post[@"parent"]) { // Add an extra check
        self.delete.hidden = YES;
        return;
    }
    
    UIAlertController *deleteAlert = [UIAlertController alertControllerWithTitle:@"Are you sure?"
                                                                         message:@"You are about to delete this post."
                                                                  preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
    
    UIAlertAction* confirmAction = [UIAlertAction actionWithTitle:@"Confirm"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              [self.post deleteInBackgroundWithBlock:^(BOOL success, NSError *error) {
                                                                  if (! success) {
                                                                      NSLog(@"Error: %@", [error localizedDescription]);
                                                                  } else {
                                                                      [(FeedTableViewController *)self.parentViewController loadObjects];
                                                                      [((FeedTableViewController *)self.parentViewController).tableView scrollRectToVisible:CGRectMake(0.0, 44.0, 1.0, 1.0)
                                                                                                                                                   animated:YES];
                                                                  }
                                                              }];
                                                          }];
    
    [deleteAlert addAction:cancelAction];
    [deleteAlert addAction:confirmAction];
    [self presentViewController:deleteAlert animated:YES completion:nil];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context
{
    if (context == &PostContext) { // Change in post
        if (self.post == nil) { // Do nothing
            return;
        }

        // Delete Button is hidden by default
        self.delete.hidden = YES;
        if ([PFUser currentUser] == self.post[@"parent"]) {
            self.delete.hidden = NO;
        }

        self.navigationItem.title = self.post[@"title"];
        
        // Stop observing the old notifications
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        
        // Allow view count to increase
        _canIncreaseViewCount = YES;
        
        // Set the text fields to the correct values
        self.playerTitle.text = self.post[@"title"];
        self.playerNumberOfViews.text = [NSString stringWithFormat:@"%@ views", self.post[@"views"]];
        
        BOOL locationHidden;
        if (self.post[@"locationPoint"] == nil) { // No location associated to post
            locationHidden = YES;
        } else {
            locationHidden = NO;
            self.location.text = self.post[@"locationText"];
        }
        self.location.hidden = locationHidden;
        self.separator.hidden = locationHidden;
        
        // Set the date field
        NSTimeInterval timeInterval =  - [self.post.createdAt timeIntervalSinceNow];
        NSInteger midnightsFromCurrentDate = [self midnightsFromDate:self.post.createdAt toDate:[NSDate date]];
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        BOOL shouldUseDateFormatter = NO;
        
        if (timeInterval < 60) { // Show "Just now"
            self.date.text = @"Just now";
        } else if (timeInterval < 120) { // Show "1 min"
            self.date.text = @"1 min";
        } else if (timeInterval < 60 * 60) { // Show time interval in minutes
            self.date.text = [NSString stringWithFormat:@"%d mins", (int)floor(timeInterval / 60)];
        } else if (timeInterval < 60 * 60 * 2) { // Show "1 hr"
            self.date.text = @"1 hr";
        } else if (timeInterval < 60 * 60 * 24) { // Show time interval in hours
            self.date.text = [NSString stringWithFormat:@"%d hrs", (int)floor(timeInterval / (60 * 60))];
        } else if (midnightsFromCurrentDate == 1) { // Show "Yesterday" and time
            [dateFormatter setDateFormat:@"'Yesterday at' hh:mm a"];
            shouldUseDateFormatter = YES;
        } else if (midnightsFromCurrentDate < 8) { // Show day of the week and time
            [dateFormatter setDateFormat:@"EEEE 'at' hh:mm a"];
            shouldUseDateFormatter = YES;
        } else if ([self isDate:[NSDate date] inSameYearAsDate:self.post.createdAt]) { // Show only day and month
            [dateFormatter setDateFormat:@"MMMM d 'at' hh:mm a"];
            shouldUseDateFormatter = YES;
        } else { // Show complete date
            [dateFormatter setDateFormat:@"MMMM d, yyyy"];
            shouldUseDateFormatter = YES;
        }
        
        if (shouldUseDateFormatter) {
            self.date.text = [dateFormatter stringFromDate:self.post.createdAt];
        }
        
        PFUser *user = self.post[@"parent"];
        [user fetchIfNeededInBackgroundWithBlock:^(PFObject *user, NSError *error) {
            if (!error) {
                self.name.text = (user[@"name"] != nil && ! [user[@"name"] isEqualToString:@""]) ? user[@"name"] : user[@"username"];
                
                // Get the profile picture
                PFFile *profilePicture = user[@"profilePicture"];
                [profilePicture getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
                    if (!error) {
                        self.profilePicture.image = [UIImage imageWithData:data];
                    } else {
                        NSLog(@"Error: %@", [error localizedDescription]);
                    }
                }];
                
                if (! user[@"profilePicture"]) { // Show default profile picture
                    self.profilePicture.image = [UIImage imageNamed:@"default_user.jpg"
                                                     inBundle:nil
                                compatibleWithTraitCollection:nil];
                }
            } else {
                NSLog(@"Error: %@", [error localizedDescription]);
            }
        }];
        
        // Set the video to the correct file
        NSString *fileName = [NSString stringWithFormat:@"%@.mp4", self.post.objectId];
        NSURL *fileURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:fileName]];
        self.playerItem = [AVPlayerItem playerItemWithURL:fileURL];
        
        // Check if video is ready. If not, show activity indicator and wait for notification.
        if ([[NSFileManager defaultManager] fileExistsAtPath:[NSTemporaryDirectory() stringByAppendingPathComponent:fileName]])
        {
            // Subscribe to the AVPlayerItem's DidPlayToEndTime notification.
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemDidFinishPlaying:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem];
            
            self.playerViewController.player = [AVPlayer playerWithPlayerItem:self.playerItem];
        } else {
            self.playerViewController.player = nil;
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoDidLoad:) name:[NSString stringWithFormat:@"%@", self.post.objectId] object:self.parentViewController];
            [self.spinner startAnimating];
        }
    }
}

- (NSInteger)midnightsFromDate:(NSDate *)startDate toDate:(NSDate *)endDate
{
    NSCalendar *calendar = [NSCalendar autoupdatingCurrentCalendar];
    NSInteger startDay = [calendar ordinalityOfUnit:NSCalendarUnitDay
                                             inUnit:NSCalendarUnitEra
                                            forDate:startDate];
    NSInteger endDay = [calendar ordinalityOfUnit:NSCalendarUnitDay
                                           inUnit:NSCalendarUnitEra
                                          forDate:endDate];
    return endDay - startDay;
}

- (BOOL)isDate:(NSDate *)startDate inSameYearAsDate:(NSDate *)endDate
{
    NSCalendar *calendar = [NSCalendar autoupdatingCurrentCalendar];
    NSInteger startYear = [calendar ordinalityOfUnit:NSCalendarUnitYear
                                             inUnit:NSCalendarUnitEra
                                            forDate:endDate];
    NSInteger endYear = [calendar ordinalityOfUnit:NSCalendarUnitYear
                                           inUnit:NSCalendarUnitEra
                                          forDate:startDate];
    
    if (endYear == startYear) {
        return YES;
    }
    
    return NO;
}

- (void)itemDidFinishPlaying:(NSNotification *)notification
{
    if (_canIncreaseViewCount) {
        [self.post incrementKey:@"views"];
        [self.post saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (succeeded) {
                // Update the view count
                self.playerNumberOfViews.text = [NSString stringWithFormat:@"%@ views", self.post[@"views"]];
            } else {
                NSLog(@"Error: %@", [error localizedDescription]);
            }
        }];
        
        // Block tries to increase view count for some time
        _canIncreaseViewCount = NO;
        [NSTimer scheduledTimerWithTimeInterval:CMTimeGetSeconds(self.playerItem.duration)
                                         target:self
                                       selector:@selector(unblockViewCountIncrease:)
                                       userInfo:nil
                                        repeats:NO];
    }
}

- (void)unblockViewCountIncrease:(NSTimer *)timer
{
    _canIncreaseViewCount = YES;
}

- (void)videoDidLoad:(NSNotification *)notification
{
    // Stop activity indicator and show video
    [self.spinner stopAnimating];
    
    // Subscribe to the AVPlayerItem's DidPlayToEndTime notification.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemDidFinishPlaying:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    
    self.playerViewController.player = [AVPlayer playerWithPlayerItem:self.playerItem];
}

@end