//
//  SearchTableViewController.h
//  Ikigai
//
//  Created by Alexandre Perozim de Faveri on 7/9/15.
//  Copyright (c) 2015 Team Ikigai. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SearchTableViewController : UITableViewController <UISearchResultsUpdating, UISearchBarDelegate>

@property (weak, nonatomic) UISearchController *searchController;
@property (strong , nonatomic) PFUser *user;

@end
