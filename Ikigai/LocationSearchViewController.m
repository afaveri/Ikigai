//
//  LocationSearchViewController.m
//  Ikigai
//
//  Created by Alexandre Perozim de Faveri on 7/30/15.
//  Copyright (c) 2015 Team Ikigai. All rights reserved.
//

#import <Parse/Parse.h>
#import "LocationSearchViewController.h"
#import "FeedCellViewController.h"

@interface LocationSearchViewController () <GMSMapViewDelegate>

@end

@implementation LocationSearchViewController
{
    GMSMapView *_mapView;
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
    
    // Set up the map
    _mapView.settings.compassButton = YES;
    _mapView.settings.myLocationButton = YES;
    _mapView.delegate = self;
    _firstLocationUpdate = NO;
    
    [_mapView addObserver:self forKeyPath:@"myLocation" options:NSKeyValueObservingOptionNew context:&locationContext];
    
     // Ask for location data
    _mapView.myLocationEnabled = YES;
    
    // Create back button and title
    UIBarButtonItem *back = [[UIBarButtonItem alloc] initWithTitle:@"Back"
                                                             style:UIBarButtonItemStylePlain
                                                            target:self
                                                            action:@selector(didSelectBack:)];
    self.navigationItem.leftBarButtonItem = back;
    self.navigationItem.title = @"Nearby Posts";
}

- (void)dealloc
{
    [_mapView removeObserver:self forKeyPath:@"myLocation" context:&locationContext];
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

#pragma mark - GMSMapViewDelegate

- (void)mapView:(GMSMapView *)mapView idleAtCameraPosition:(GMSCameraPosition *)position
{
    // Get all posts in the visible area and show a marker for each one
    PFQuery *query = [PFQuery queryWithClassName:@"Post"];
    GMSVisibleRegion visibleRegion = mapView.projection.visibleRegion;
    
    CLLocationDirection bearing = mapView.camera.bearing;

    CLLocationCoordinate2D southwest = [self southwestPointWithAngle:bearing
                                                            nearLeft:visibleRegion.nearLeft
                                                             farLeft:visibleRegion.farLeft
                                                           nearRight:visibleRegion.nearRight
                                                            farRight:visibleRegion.farRight];
    CLLocationCoordinate2D northeast = [self notheastPointWithAngle:bearing
                                                           nearLeft:visibleRegion.nearLeft
                                                            farLeft:visibleRegion.farLeft
                                                          nearRight:visibleRegion.nearRight
                                                           farRight:visibleRegion.farRight];
    
    PFGeoPoint *southwestPoint = [PFGeoPoint geoPointWithLatitude:southwest.latitude longitude:southwest.longitude];
    PFGeoPoint *northeastPoint = [PFGeoPoint geoPointWithLatitude:northeast.latitude longitude:northeast.longitude];
    
    if (northeast.longitude >= southwest.longitude) { // Query doesn't cross the International Date Line
        if (northeast.longitude - southwest.longitude < 180) { // Small query
            [query whereKey:@"locationPoint" withinGeoBoxFromSouthwest:southwestPoint toNortheast:northeastPoint];
            [query findObjectsInBackgroundWithBlock:^(NSArray *posts, NSError *error) {
                if (error) {
                    NSLog(@"Error: %@", [error localizedDescription]);
                } else {
                    // Clear previous markers
                    [mapView clear];
                    
                    // Add markers for posts in the visible area
                    [self addMarkersToMap:mapView forPosts:posts];
                }
            }];
        } else { // More than 180 degrees of longitude difference. Split in two.
            PFGeoPoint *northMidPoint = [PFGeoPoint geoPointWithLatitude:northeast.latitude longitude:(northeast.longitude + southwest.longitude) / 2];
            PFGeoPoint *southMidPoint = [PFGeoPoint geoPointWithLatitude:southwest.latitude longitude:(northeast.longitude + southwest.longitude) / 2];
            
            [query whereKey:@"locationPoint" withinGeoBoxFromSouthwest:southwestPoint toNortheast:northMidPoint];
            [query findObjectsInBackgroundWithBlock:^(NSArray *posts, NSError *error) {
                if (error) {
                    NSLog(@"Error: %@", [error localizedDescription]);
                } else {
                    // Clear previous markers
                    [mapView clear];
                    
                    // Add markers for posts in the first box
                    [self addMarkersToMap:mapView forPosts:posts];
                    
                    PFQuery *secondQuery = [PFQuery queryWithClassName:@"Post"];
                    [secondQuery whereKey:@"locationPoint" withinGeoBoxFromSouthwest:southMidPoint toNortheast:northeastPoint];
                    [secondQuery findObjectsInBackgroundWithBlock:^(NSArray *posts, NSError *error) {
                        if (error) {
                            NSLog(@"Error: %@", [error localizedDescription]);
                        } else {
                            // Add markers for posts in the second box
                            [self addMarkersToMap:mapView forPosts:posts];
                        }
                    }];
                }
            }];
        }
    } else { // Query crosses the International Date Line. Split it in two.
        PFGeoPoint *preInternationalDateLinePoint = [PFGeoPoint geoPointWithLatitude:northeast.latitude longitude:179.99];
        PFGeoPoint *postInternationalDateLinePoint = [PFGeoPoint geoPointWithLatitude:southwest.latitude longitude:-179.99];
        
        [query whereKey:@"locationPoint" withinGeoBoxFromSouthwest:southwestPoint toNortheast:preInternationalDateLinePoint];
        [query findObjectsInBackgroundWithBlock:^(NSArray *posts, NSError *error) {
            if (error) {
                NSLog(@"Error: %@", [error localizedDescription]);
            } else {
                // Clear previous markers
                [mapView clear];
                
                // Add markers for posts in the first box (to the left of the IDL)
                [self addMarkersToMap:mapView forPosts:posts];
                
                PFQuery *secondQuery = [PFQuery queryWithClassName:@"Post"];
                [secondQuery whereKey:@"locationPoint" withinGeoBoxFromSouthwest:postInternationalDateLinePoint toNortheast:northeastPoint];
                [secondQuery findObjectsInBackgroundWithBlock:^(NSArray *posts, NSError *error) {
                    if (error) {
                        NSLog(@"Error: %@", [error localizedDescription]);
                    } else {
                        // Add markers for posts in the second box (to the right of the IDL)
                        [self addMarkersToMap:mapView forPosts:posts];
                    }
                }];
            }
        }];
    }
}

- (BOOL)mapView:(GMSMapView *)mapView didTapMarker:(GMSMarker *)marker
{
    // Avoid centering camera at tapped marker
    mapView.selectedMarker = marker;
    return YES;
}

- (void)addMarkersToMap:(GMSMapView *)mapView forPosts:(NSArray *)posts
{
    for (PFObject *post in posts) {
        PFGeoPoint *postLocation = post[@"locationPoint"];
        GMSMarker *marker = [GMSMarker markerWithPosition:CLLocationCoordinate2DMake(postLocation.latitude, postLocation.longitude)];
        marker.title = post[@"title"];
        marker.snippet = post[@"locationText"];
        marker.userData = post;
        marker.map = mapView;
    }
}

// Returns the northeast corner of a rectangle with sides parallel to the Equador that contains the tilted rectangle
// determined by the four points passed as arguments
- (CLLocationCoordinate2D)notheastPointWithAngle:(CLLocationDirection)bearing
                                        nearLeft:(CLLocationCoordinate2D)nearLeft
                                         farLeft:(CLLocationCoordinate2D)farLeft
                                       nearRight:(CLLocationCoordinate2D)nearRight
                                        farRight:(CLLocationCoordinate2D)farRight
{
    if (bearing < 0 || bearing > 360.0) {
        NSLog(@"Bearing is not in [0, 360].");
    } else if (bearing <= 90.0) {
        return CLLocationCoordinate2DMake(farLeft.latitude, farRight.longitude);
    } else if (bearing <= 180.0) {
        return CLLocationCoordinate2DMake(nearLeft.latitude, farLeft.longitude);
    } else if (bearing <= 270.0) {
        return CLLocationCoordinate2DMake(nearRight.latitude, nearLeft.longitude);
    } else if (bearing <= 360.0) {
        return CLLocationCoordinate2DMake(farRight.latitude, nearRight.longitude);
    }
    
    return kCLLocationCoordinate2DInvalid;
}

// Returns the southwest corner of a rectangle with sides parallel to the Equador that contains the tilted rectangle
// determined by the four points passed as arguments
- (CLLocationCoordinate2D)southwestPointWithAngle:(CLLocationDirection)bearing
                                         nearLeft:(CLLocationCoordinate2D)nearLeft
                                          farLeft:(CLLocationCoordinate2D)farLeft
                                        nearRight:(CLLocationCoordinate2D)nearRight
                                         farRight:(CLLocationCoordinate2D)farRight
{
    if (bearing < 0 || bearing > 360.0) {
        NSLog(@"Bearing is not in [0, 360].");
    } else if (bearing <= 90.0) {
        return CLLocationCoordinate2DMake(nearRight.latitude, nearLeft.longitude);
    } else if (bearing <= 180.0) {
        return CLLocationCoordinate2DMake(farRight.latitude, nearRight.longitude);
    } else if (bearing <= 270.0) {
        return CLLocationCoordinate2DMake(farLeft.latitude, farRight.longitude);
    } else if (bearing <= 360.0) {
        return CLLocationCoordinate2DMake(nearLeft.latitude, farLeft.longitude);
    }
    
    return kCLLocationCoordinate2DInvalid;
}

- (void)mapView:(GMSMapView *)mapView didTapInfoWindowOfMarker:(GMSMarker *)marker
{
    PFObject *post = marker.userData;
    [post[@"video"] getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        if (error) {
            NSLog(@"Error: %@", [error localizedDescription]);
        } else {
            NSString *fileName = [NSString stringWithFormat:@"%@.mp4", post.objectId];
            NSURL *fileURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:fileName]];
            
            // Save video
            [data writeToURL:fileURL atomically:YES];
            
            // Show video
            FeedCellViewController *fcvc = [[FeedCellViewController alloc] init];
            UINavigationController *fcnc = [[UINavigationController alloc] initWithRootViewController:fcvc];

            [self presentViewController:fcnc animated:YES completion:^{
                // Change post
                fcvc.post = post;
            }];
        }
    }];
}

- (IBAction)didSelectBack:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
