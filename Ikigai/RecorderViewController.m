//
//  RecorderViewController.m
//  Ikigai
//
//  Created by Alexandre Perozim de Faveri on 7/22/15.
//  Copyright (c) 2015 Team Ikigai. All rights reserved.
//

#import "RecorderViewController.h"
#import "IKIPublishVideoViewController.h"

@implementation RecorderViewController

static const NSInteger kProfileButtonIndex = 0;
static const NSInteger kMaxVideoDuration = 60; // In seconds

- (instancetype)initWithSourceType:(UIImagePickerControllerSourceType)sourceType
{
    self = [super init];
    if (self ) {
        self.sourceType = sourceType;
        self.delegate = self;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didCaptureItem:) name:@"_UIImagePickerControllerUserDidCaptureItem" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRejectItem:) name:@"_UIImagePickerControllerUserDidRejectItem" object:nil];
    
    if (self.sourceType == UIImagePickerControllerSourceTypeCamera) { // Add overlay view with button for choosing video
        UIView *overlayView = [[UIView alloc] initWithFrame:self.view.frame];
        
        UIButton *library = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [library setTitle:@"Library" forState:UIControlStateNormal];
        [library setTintColor:[UIColor whiteColor]];
        library.titleLabel.font = [UIFont systemFontOfSize:18.0];
        library.frame = CGRectMake(overlayView.frame.size.width - 80.0, overlayView.frame.size.height - 65.0, 68.0, 35.0);
        [library addTarget:self action:@selector(openVideoLibrary:) forControlEvents:UIControlEventTouchUpInside];
        
        [overlayView addSubview:library];
        self.cameraOverlayView = overlayView;
    }

    // Restrict media to video
    NSArray *mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
    NSArray *videoMediaTypesOnly = [mediaTypes filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(SELF contains %@)", @"movie"]];
    
    self.mediaTypes = videoMediaTypesOnly;
    self.videoMaximumDuration = kMaxVideoDuration;
    self.videoQuality = UIImagePickerControllerQualityTypeMedium;
    self.allowsEditing = YES;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (IBAction)openVideoLibrary:(id)sender
{
    RecorderViewController *rvc = [[RecorderViewController alloc] initWithSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.presentingViewController presentViewController:rvc animated:YES completion:nil];
}

- (IBAction)didCaptureItem:(id)sender
{
    // Remove library button
    self.cameraOverlayView = nil;
}

- (IBAction)didRejectItem:(id)sender
{
    // Add library button
    UIView *overlayView = [[UIView alloc] initWithFrame:self.view.frame];
    
    UIButton *library = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [library setTitle:@"Library" forState:UIControlStateNormal];
    [library setTintColor:[UIColor whiteColor]];
    library.titleLabel.font = [UIFont systemFontOfSize:18.0];
    library.frame = CGRectMake(overlayView.frame.size.width - 80.0, overlayView.frame.size.height - 65.0, 68.0, 35.0);
    [library addTarget:self action:@selector(openVideoLibrary:) forControlEvents:UIControlEventTouchUpInside];
    
    [overlayView addSubview:library];
    self.cameraOverlayView = overlayView;
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    if (self.sourceType == UIImagePickerControllerSourceTypeCamera) { // Dismiss image picker and go to profile
        ((UITabBarController *)self.presentingViewController).selectedIndex = kProfileButtonIndex;
        [self dismissViewControllerAnimated:YES completion:nil];
    } else { // Present camera
        RecorderViewController *rvc = [[RecorderViewController alloc] initWithSourceType:UIImagePickerControllerSourceTypeCamera];
        [self dismissViewControllerAnimated:YES completion:nil];
        [self.presentingViewController presentViewController:rvc animated:YES completion:nil];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    // Get the video URL
    NSURL *videoURL = [info objectForKey:UIImagePickerControllerMediaURL];
    NSData *videoData = [NSData dataWithContentsOfURL:videoURL];
    NSString *fileName = @"post.mp4";
    NSURL *fileURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:fileName]];
    
    // Save file
    [videoData writeToURL:fileURL atomically:YES];
    
    // Also save to Photo Album if taken with camera
    if (picker.sourceType == UIImagePickerControllerSourceTypeCamera && UIVideoAtPathIsCompatibleWithSavedPhotosAlbum([fileURL path])) {
        UISaveVideoAtPathToSavedPhotosAlbum([fileURL path], nil, nil, nil);
    }
    
    IKIPublishVideoViewController *pvc = [[IKIPublishVideoViewController alloc] init];
    UINavigationController *pnc = [[UINavigationController alloc] initWithRootViewController:pvc];
    
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.presentingViewController presentViewController:pnc animated:YES completion:nil];
}

@end
