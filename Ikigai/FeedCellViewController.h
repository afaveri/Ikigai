//
//  FeedCellViewController.h
//  Ikigai
//
//  Created by Alexandre Perozim de Faveri on 7/15/15.
//  Copyright (c) 2015 Team Ikigai. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PFObject;

@interface FeedCellViewController : UIViewController

@property (strong, nonatomic) PFObject *post;

@end
