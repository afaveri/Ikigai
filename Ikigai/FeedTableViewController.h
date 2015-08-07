//
//  FeedTableViewController.h
//  Ikigai
//
//  Created by Alexandre Perozim de Faveri on 7/16/15.
//  Copyright (c) 2015 Team Ikigai. All rights reserved.
//

#import <ParseUI/ParseUI.h>

@interface FeedTableViewController : PFQueryTableViewController

- (instancetype)initWithStyle:(UITableViewStyle)style query:(PFQuery *)query user:(PFUser *)user context:(NSString *)context;

@end
