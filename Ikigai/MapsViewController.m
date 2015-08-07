//
//  MapsViewController.m
//  Ikigai
//
//  Created by Alexandre Perozim de Faveri on 7/22/15.
//  Copyright (c) 2015 Team Ikigai. All rights reserved.
//

#import <GoogleMaps/GoogleMaps.h>
#import <Parse/Parse.h>
#import "MapsViewController.h"

@implementation MapsViewController
{
    GMSMapView *_mapView;
    PFObject *_post;
}

- (instancetype)initWithPost:(PFObject *)post
{
    self = [super init];
    if (self) {
        _post = post;
    }
    
    return self;
}

- (void)loadView
{
    PFGeoPoint *location = _post[@"locationPoint"];
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:location.latitude
                                                            longitude:location.longitude
                                                                 zoom:15];
    _mapView = [GMSMapView mapWithFrame:CGRectZero camera:camera];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view = _mapView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Set up the map
    _mapView.settings.compassButton = YES;
    _mapView.myLocationEnabled = YES;
    _mapView.settings.myLocationButton = YES;
    
    // Create back button and title
    UIBarButtonItem *back = [[UIBarButtonItem alloc] initWithTitle:@"Back"
                                                             style:UIBarButtonItemStylePlain
                                                            target:self
                                                            action:@selector(didSelectBack:)];
    self.navigationItem.leftBarButtonItem = back;
    self.navigationItem.title = @"Map";
    
    // Put marker at the location of the post
    PFGeoPoint *location = _post[@"locationPoint"];
    CLLocationCoordinate2D position = CLLocationCoordinate2DMake(location.latitude, location.longitude);
    GMSMarker *marker = [GMSMarker markerWithPosition:position];
    marker.title = _post[@"title"];
    marker.snippet = _post[@"locationText"];
    marker.map = _mapView;
    [_mapView setSelectedMarker:marker];
}

- (IBAction)didSelectBack:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
