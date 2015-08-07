//
//  PlacePickerViewController.m
//  Ikigai
//
//  Created by Alexandre Perozim de Faveri on 7/28/15.
//  Copyright (c) 2015 Team Ikigai. All rights reserved.
//

#import <GoogleMaps/GoogleMaps.h>
#import "PlacePickerViewController.h"
#import "IKIPublishVideoViewController.h"

@implementation PlacePickerViewController
{
    GMSMapView *_mapView;
    GMSPlacePicker *_placePicker;
    GMSPlace *_selectedPlace;
    BOOL _firstLocationUpdate;
}

static NSString *locationContext;

- (void)loadView
{
    _mapView = [[GMSMapView alloc] initWithFrame:CGRectZero];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view = _mapView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _mapView.settings.compassButton = YES;
    _mapView.settings.myLocationButton = YES;
    _firstLocationUpdate = NO;
    
    [_mapView addObserver:self forKeyPath:@"myLocation" options:NSKeyValueObservingOptionNew context:&locationContext];
    
    // Ask for my location data after the map has already been added to the UI
    dispatch_async(dispatch_get_main_queue(), ^{
        _mapView.myLocationEnabled = YES;
    });
    
    UIBarButtonItem *back = [[UIBarButtonItem alloc] initWithTitle:@"Back"
                                                             style:UIBarButtonItemStylePlain
                                                            target:self
                                                            action:@selector(didSelectBack:)];
    UIBarButtonItem *pickPlace = [[UIBarButtonItem alloc] initWithTitle:@"Pick Place"
                                                                  style:UIBarButtonItemStylePlain
                                                                 target:self
                                                                 action:@selector(pickPlace:)];
    self.navigationItem.leftBarButtonItem = back;
    self.navigationItem.rightBarButtonItem = pickPlace;
    self.navigationItem.title = @"Map";
}

- (void)dealloc
{
    [_mapView removeObserver:self forKeyPath:@"myLocation" context:&locationContext];
}

- (IBAction)didSelectBack:(id)sender
{
    [self.delegate didCancelPickingPlace];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)didSelectOk:(id)sender
{
    [self.delegate didPickPlace:_selectedPlace];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)pickPlace:(UIBarButtonItem *)sender
{
    GMSVisibleRegion visibleRegion = _mapView.projection.visibleRegion;
    GMSCoordinateBounds *viewport = [[GMSCoordinateBounds alloc] initWithCoordinate:visibleRegion.farLeft
                                                                         coordinate:visibleRegion.nearRight];
    GMSPlacePickerConfig *config = [[GMSPlacePickerConfig alloc] initWithViewport:viewport];
    _placePicker = [[GMSPlacePicker alloc] initWithConfig:config];
    
    [_placePicker pickPlaceWithCallback:^(GMSPlace *place, NSError *error) {
        if (error != nil) {
            NSLog(@"Pick Place error: %@", [error localizedDescription]);
            return;
        }
        
        if (place != nil) {
            _selectedPlace = place;
            
            // Clear markers
            [_mapView clear];
            
            // Put a marker in the selected place
            GMSMarker *marker = [GMSMarker markerWithPosition:place.coordinate];
            marker.title = place.name;
            marker.snippet = place.formattedAddress;
            marker.map = _mapView;
            [_mapView setSelectedMarker:marker];
            [_mapView animateToLocation:place.coordinate];
            
            // Change navigation bar buttons
            UIBarButtonItem *ok = [[UIBarButtonItem alloc] initWithTitle:@"Ok"
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(didSelectOk:)];
            UIBarButtonItem *pickAgain = [[UIBarButtonItem alloc] initWithTitle:@"Pick Again"
                                                                          style:UIBarButtonItemStylePlain
                                                                         target:self
                                                                         action:@selector(pickPlace:)];
            self.navigationItem.leftBarButtonItem = ok;
            self.navigationItem.rightBarButtonItem = pickAgain;
        }
    }];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == &locationContext) {
        if (! _firstLocationUpdate) {
            // If the first location update has not yet been recieved, then jump to that location
            _firstLocationUpdate = YES;
            CLLocation *location = [change objectForKey:NSKeyValueChangeNewKey];
            _mapView.camera = [GMSCameraPosition cameraWithTarget:location.coordinate
                                                             zoom:15];
        }
    }
}

@end

