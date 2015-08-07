//
//  PublicProfileViewController.h
//  Ikigai
//
//  Created by Alexandre Perozim de Faveri on 7/13/15.
//  Copyright (c) 2015 Team Ikigai. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PFUser;

@interface PublicProfileViewController : UIViewController

- (instancetype)initWithUser:(PFUser *)user NS_DESIGNATED_INITIALIZER;

@end
