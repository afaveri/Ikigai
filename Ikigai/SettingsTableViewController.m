//
//  SettingsTableViewController.m
//  Ikigai
//
//  Created by Alexandre Perozim de Faveri on 7/10/15.
//  Copyright (c) 2015 Team Ikigai. All rights reserved.
//

#import <Parse/Parse.h>
#import "SettingsTableViewController.h"

const NSUInteger kLogOutRow = 0;
const NSUInteger kDeleteAccountRow = 1;

@interface SettingsTableViewController ()

@property (nonatomic) NSMutableArray *settingsCells;

@end

@implementation SettingsTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSMutableArray *arr = [NSMutableArray array];
    arr[kLogOutRow] = @"Log Out";
    arr[kDeleteAccountRow] = @"Delete Account";
    self.settingsCells = arr;
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"settingsCell"];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"settingsCell"];
    }
    
    cell.textLabel.text = [self.settingsCells objectAtIndex:indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == kLogOutRow) {
        [PFUser logOut]; // Log out
        // Return to login page
        if (![PFUser currentUser]) {
            [self.tabBarController dismissViewControllerAnimated:YES completion:nil];
        }
    }
    if (indexPath.row == kDeleteAccountRow) { //Confirms that the user wants to delete an account
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Are you sure?"
                                                                       message:@"Are you sure you want to delete your account? We will miss you!"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"What? No! That was my mistake."
                                                               style:UIAlertActionStyleCancel
                                                             handler:nil];
        
        UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"Confirm"
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                                                                  PFRelation *relation = [[PFUser currentUser] relationForKey:@"posts"];
                                                                  PFQuery *query = [relation query];
                                                                  [query findObjectsInBackgroundWithBlock:^(NSArray *posts, NSError *error) {
                                                                      if (error) {
                                                                          NSLog(@"Error: %@", [error localizedDescription]);
                                                                      } else {
                                                                          for (PFObject *post in posts) {
                                                                              [post deleteInBackground];
                                                                          }
                                                                          [[PFUser currentUser] deleteInBackgroundWithBlock:^(BOOL success, NSError *error) {
                                                                              if (! success) {
                                                                                  NSLog(@"Error: %@", [error localizedDescription]);
                                                                              } else {
                                                                                  [PFUser logOut];
                                                                                  [self.tabBarController dismissViewControllerAnimated:YES completion:nil];
                                                                              }
                                                                          }];
                                                                      }
                                                                  }];
                                                              }];
        
        [alert addAction:cancelAction];
        [alert addAction:confirmAction];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

@end
