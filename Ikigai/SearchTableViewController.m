//
//  SearchTableViewController.m
//  Ikigai
//
//  Created by Alexandre Perozim de Faveri on 7/9/15.
//  Copyright (c) 2015 Team Ikigai. All rights reserved.
//

#import <Parse/Parse.h>
#import "SearchTableViewController.h"
#import "PublicProfileViewController.h"
#import "FeedTableViewCell.h"
#import "FeedCellViewController.h"
#import "SearchTableViewCell.h"
#import "ProfileNavigationController.h"

@interface SearchTableViewController ()

@property (nonatomic) NSMutableArray *searchResults;

@end

@implementation SearchTableViewController

static const NSInteger userIndex = 0;
static const NSInteger postIndex = 1;
static const CGFloat feedCellHeight = 392;
static const CGFloat defaultCellHeight = 44;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UINib *userCellNib = [UINib nibWithNibName:@"SearchTableViewCell" bundle:nil];
    [self.tableView registerNib:userCellNib forCellReuseIdentifier:@"SearchTableViewCell"];
}

#pragma mark - UISearchResultsUpdating delegate

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    // Avoid corner case (empty search)
    if (searchController.searchBar.text.length == 0) {
        [self.searchResults removeAllObjects];
        [self.tableView reloadData];
        return;
    }
    
    NSString *lowercaseText = [searchController.searchBar.text lowercaseString];
    
    if (self.user == nil) { // Search all posts and users
        if (searchController.searchBar.selectedScopeButtonIndex == userIndex) {
            // Query the users database
            PFQuery *usernameQuery = [PFUser query];
            [usernameQuery whereKey:@"canonicalUsername" hasPrefix:lowercaseText];
            
            PFQuery *nameQuery = [PFUser query];
            [nameQuery whereKey:@"canonicalName" hasPrefix:lowercaseText];
            
            PFQuery *query = [PFQuery orQueryWithSubqueries:@[usernameQuery, nameQuery]];
            query.limit = 100;
            [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                if (!error) {
                    // The find succeeded.
                    NSLog(@"Successfully retrieved %lu users.", (unsigned long)objects.count);
                    
                    self.searchResults = (NSMutableArray *)objects;
                    [self.tableView reloadData];
                } else {
                    // Log details of the failure
                    NSLog(@"Error: %@", [error localizedDescription]);
                }
            }];
        }
        
        if (searchController.searchBar.selectedScopeButtonIndex == postIndex) {
            // Query the posts database
            PFQuery *query = [PFQuery queryWithClassName:@"Post"];
            [query whereKey:@"canonicalTitle" hasPrefix:lowercaseText];
            query.limit = 100;
            [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                if (!error) {
                    // The find succeeded.
                    NSLog(@"Successfully retrieved %lu posts.", (unsigned long)objects.count);
                    
                    self.searchResults = (NSMutableArray *)objects;
                    [self.tableView reloadData];
                } else {
                    // Log details of the failure
                    NSLog(@"Error: %@", [error localizedDescription]);
                }
            }];
        }
    } else { // Search only for posts of a specific user
        PFQuery *query = [PFQuery queryWithClassName:@"Post"];
        [query whereKey:@"parent" equalTo:self.user];
        [query whereKey:@"canonicalTitle" hasPrefix:lowercaseText];
        query.limit = 100;
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (!error) {
                // The find succeeded.
                NSLog(@"Successfully retrieved %lu posts.", (unsigned long)objects.count);
                
                self.searchResults = (NSMutableArray *)objects;
                [self.tableView reloadData];
            } else {
                // Log details of the failure
                NSLog(@"Error: %@", [error localizedDescription]);
            }
        }];
    }
}


#pragma mark - UISearchBar delegate


- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope
{
    // Query again
    [self updateSearchResultsForSearchController:self.searchController];
}


#pragma mark - Table view data source


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.searchController.searchBar.text.length == 0) return 0; // Empty search
    
    if (self.searchResults.count == 0) return 1; // Space for message
    
    return self.searchResults.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    tableView.allowsSelection = YES;
    
    if (self.searchController.searchBar.text.length == 0) { // Empty search
        return cell;
    }
    
    if (self.searchResults.count == 0) { // No results
        // Create a cell for a message
        cell = [tableView dequeueReusableCellWithIdentifier:@"Message"];
        
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Message"];
        }
        
        // Create message
        NSString *genericMessage = @"Could not find any matches for ";
        NSString *message = [genericMessage stringByAppendingString:self.searchController.searchBar.text];
        
        cell.textLabel.text = message;
        
        tableView.allowsSelection = NO; // Users cannot select message
        
        return cell;
    }
    
    if (self.searchController.searchBar.selectedScopeButtonIndex == userIndex) { // Create a cell for an user
        PFUser *user = ((PFUser *)[self.searchResults objectAtIndex:indexPath.row]);

        SearchTableViewCell *userCell = [tableView dequeueReusableCellWithIdentifier:@"SearchTableViewCell"
                                                                        forIndexPath:indexPath];
        
        userCell.nameLabel.text = user[@"name"];
        userCell.usernameLabel.text = user.username;
        
        userCell.pictureImageView.image = [UIImage imageNamed:@"default_user.jpg"
                                   inBundle:nil
              compatibleWithTraitCollection:nil];
        
        [user[@"profilePicture"] getDataInBackgroundWithBlock:^(NSData *imageData, NSError *error) {
            if (!error) {
                userCell.pictureImageView.image = [UIImage imageWithData:imageData];
            } else {
                // Error
                NSLog(@"Error: %@", [error localizedDescription]);
            }
        }];
        
        return userCell;
    } else { // Create a cell for a post
        FeedTableViewCell *feedCell = [tableView dequeueReusableCellWithIdentifier:@"feedCell"];
        
        if (feedCell == nil) {
            feedCell = [[FeedTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"feedCell"];
            
            // Disable highlighting in selection
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            
            FeedCellViewController *fcvc = [[FeedCellViewController alloc] init];
            fcvc.view.frame = feedCell.contentView.bounds;
            feedCell.viewController = fcvc;
            [self addChildViewController:fcvc];
            [feedCell.contentView addSubview:fcvc.view];
        }
        
        feedCell.viewController.post = self.searchResults[indexPath.row];
        
        return feedCell;
    }
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.searchController.searchBar.selectedScopeButtonIndex == userIndex ||
        self.searchResults.count == 0) { // Default cell
        return defaultCellHeight;
    } else { // Post search
        return feedCellHeight;
    }
}


#pragma mark - Table view delegate


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.searchController.searchBar.selectedScopeButtonIndex == userIndex &&
        self.searchResults.count != 0) { // User search
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
        PublicProfileViewController *ppvc = [[PublicProfileViewController alloc] initWithUser:(PFUser *)self.searchResults[indexPath.row]];
        ProfileNavigationController *ppnc = [[ProfileNavigationController alloc] initWithRootViewController:ppvc];
        [self presentViewController:ppnc animated:YES completion:nil];
    }
}


@end
