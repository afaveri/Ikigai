//
//  UserTableViewController.m
//  Ikigai
//
//  Created by Alexandre Perozim de Faveri on 7/17/15.
//  Copyright (c) 2015 Team Ikigai. All rights reserved.
//

#import <Parse/Parse.h>
#import "UserTableViewController.h"
#import "PublicProfileViewController.h"
#import "SearchTableViewCell.h"
#import "ProfileNavigationController.h"

@interface UserTableViewController ()

@property (strong, nonatomic) NSString *context;
@property (strong, nonatomic) PFUser *user;
@property (strong, nonatomic) PFQuery *query;

@end

@implementation UserTableViewController

- (instancetype)initWithStyle:(UITableViewStyle)style query:(PFQuery *)query user:(PFUser *)user context:(NSString *)context
{
    self = [super initWithStyle:style];
    if (self) {
        if ([context isEqualToString:@"Advanced Search"]) {
            self.parseClassName = @"User";
        } else {
            self.parseClassName = @"Follow";
        }
        self.pullToRefreshEnabled = YES;
        self.paginationEnabled = YES;
        self.objectsPerPage = 25;
        self.context = context;
        self.user = user;
        self.query = query;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UINib *userCellNib = [UINib nibWithNibName:@"SearchTableViewCell" bundle:nil];
    [self.tableView registerNib:userCellNib forCellReuseIdentifier:@"SearchTableViewCell"];
    
    // Set navigation bar title
    if ([self.context isEqualToString:@"Followers"]) {
        self.navigationItem.title = @"Followers";
    } else if ([self.context isEqualToString:@"Following"]) {
        self.navigationItem.title = @"Following";
    } else if ([self.context isEqualToString:@"Advanced Search"]) {
        self.navigationItem.title = @"Advanced Search Results";
    }
}

- (PFQuery *)queryForTable
{
    return self.query;
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.objects.count + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.objects.count == 0) { // Nothing to display
        static NSString *loadCellIdentifier = @"noResultsCell";
        
        PFTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:loadCellIdentifier];
        
        if (cell == nil) {
            cell = [[PFTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault  reuseIdentifier:loadCellIdentifier];
        }
        
        cell.textLabel.text = @"Your search did not return any results";
        
        return cell;
    }
    
    if (indexPath.row == self.objects.count) { // "Load more" cell
        return [self tableView:tableView cellForNextPageAtIndexPath:indexPath];
    } else {
        SearchTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SearchTableViewCell"
                                                                    forIndexPath:indexPath];
        
        // Create cell fields
        if ([self.context isEqualToString:@"Followers"]) {
            [self.objects[indexPath.row][@"from"] fetchInBackgroundWithBlock:^(PFObject *user, NSError *error) {
                if (!error) {
                    cell.nameLabel.text = user[@"name"];
                    cell.usernameLabel.text = user[@"username"];
                    cell.pictureImageView.image = [UIImage imageNamed:@"default_user.jpg"
                                                       inBundle:nil
                                  compatibleWithTraitCollection:nil];
                    
                    [user[@"profilePicture"] getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
                        if (!error) {
                            cell.pictureImageView.image = [UIImage imageWithData:data];
                        } else {
                            NSLog(@"Error: %@", [error localizedDescription]);
                        }
                    }];
                } else {
                    NSLog(@"Error: %@", [error localizedDescription]);
                }
            }];
        } else if ([self.context isEqualToString:@"Following"]) {
            [self.objects[indexPath.row][@"to"] fetchInBackgroundWithBlock:^(PFObject *user, NSError *error) {
                if (!error) {
                    cell.nameLabel.text = user[@"name"];
                    cell.usernameLabel.text = user[@"username"];
                    cell.pictureImageView.image = [UIImage imageNamed:@"default_user.jpg"
                                               inBundle:nil
                          compatibleWithTraitCollection:nil];
                    
                    [user[@"profilePicture"] getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
                        if (!error) {
                            cell.pictureImageView.image = [UIImage imageWithData:data];
                        } else {
                            NSLog(@"Error: %@", [error localizedDescription]);
                        }
                    }];
                } else {
                    NSLog(@"Error: %@", [error localizedDescription]);
                }
            }];
        } else {
            cell.nameLabel.text = self.objects[indexPath.row][@"name"];
            cell.usernameLabel.text = self.objects[indexPath.row][@"username"];
            cell.pictureImageView.image = [UIImage imageNamed:@"default_user.jpg"
                                               inBundle:nil
                          compatibleWithTraitCollection:nil];
            
            [self.objects[indexPath.row][@"profilePicture"] getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
                if (!error) {
                    cell.pictureImageView.image = [UIImage imageWithData:data];
                } else {
                    NSLog(@"Error: %@", [error localizedDescription]);
                }
            }];
        }
        
        return cell;
    }
}

- (PFTableViewCell *)tableView:(UITableView *)tableView cellForNextPageAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *loadCellIdentifier = @"loadMoreCell";
    
    PFTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:loadCellIdentifier];
    
    if (cell == nil) {
        cell = [[PFTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:loadCellIdentifier];
    }
    
    cell.textLabel.text = @"Load More...";
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row < self.objects.count) {
        PublicProfileViewController *ppvc;
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
        
        if ([self.context isEqualToString:@"Followers"]) {
            ppvc = [[PublicProfileViewController alloc] initWithUser:(PFUser *)self.objects[indexPath.row][@"from"]];
        } else if ([self.context isEqualToString:@"Following"]) {
            ppvc = [[PublicProfileViewController alloc] initWithUser:(PFUser *)self.objects[indexPath.row][@"to"]];
        } else { // Advanced search
            ppvc = [[PublicProfileViewController alloc] initWithUser:self.objects[indexPath.row]];
        }
            
        ProfileNavigationController *ppnc = [[ProfileNavigationController alloc] initWithRootViewController:ppvc];
        [self presentViewController:ppnc animated:YES completion:nil];
    } else { // Load more
        [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    }
}

@end
