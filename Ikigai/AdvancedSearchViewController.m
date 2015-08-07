//
//  AdvancedSearchViewController.m
//  Ikigai
//
//  Created by Alexandre Perozim de Faveri on 7/19/15.
//  Copyright (c) 2015 Team Ikigai. All rights reserved.
//

#import <Parse/Parse.h>
#import "AdvancedSearchViewController.h"
#import "FeedTableViewController.h"
#import "UserTableViewController.h"
#import "FieldsPickerConstants.h"

@interface AdvancedSearchViewController ()

@property (weak, nonatomic) IBOutlet UITextField *minAge;
@property (weak, nonatomic) IBOutlet UITextField *maxAge;
@property (weak, nonatomic) IBOutlet UITextField *city;
@property (weak, nonatomic) IBOutlet UITextField *education;
@property (weak, nonatomic) IBOutlet UITextField *occupation;

@property (strong, nonatomic) NSMutableArray *selectedGenders;
@property (strong, nonatomic) NSMutableArray *selectedRaces;
@property (strong, nonatomic) NSMutableArray *selectedSexualOrientations;
@property (strong, nonatomic) NSMutableArray *selectedCountries;
@property (strong, nonatomic) NSMutableArray *selectedReligions;
@property (strong, nonatomic) NSMutableArray *selectedRelationshipStatuses;
@property (strong, nonatomic) NSMutableArray *selectedPoliticalViews;

@property (weak, nonatomic) IBOutlet UISegmentedControl *searchType;

@end

@implementation AdvancedSearchViewController

static const NSInteger kUsersIndex = 0;
static const NSInteger kPostsIndex = 1;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Set up navigation bar
    self.navigationItem.title = @"Advanced Search";
    
    UIBarButtonItem *search = [[UIBarButtonItem alloc] initWithTitle:@"Search"
                                                               style:UIBarButtonItemStyleDone
                                                              target:self
                                                              action:@selector(displaySearchResults:)];
    self.navigationItem.rightBarButtonItem = search;
    
    // Set up selected arrays
    self.selectedGenders = [self createArrayOfBoolsWithArray:[FieldsPickerConstants getGenders]];
    self.selectedRaces = [self createArrayOfBoolsWithArray:[FieldsPickerConstants getRaces]];
    self.selectedSexualOrientations = [self createArrayOfBoolsWithArray:[FieldsPickerConstants getSexualOrientations]];
    self.selectedCountries = [self createArrayOfBoolsWithArray:[FieldsPickerConstants getCountries]];
    self.selectedReligions = [self createArrayOfBoolsWithArray:[FieldsPickerConstants getReligions]];
    self.selectedRelationshipStatuses = [self createArrayOfBoolsWithArray:[FieldsPickerConstants getRelationshipStatuses]];
    self.selectedPoliticalViews = [self createArrayOfBoolsWithArray:[FieldsPickerConstants getPoliticalViews]];
}

- (NSMutableArray *)createArrayOfBoolsWithArray:(NSArray *)array
{
    NSMutableArray *result = [NSMutableArray array];
    for (NSUInteger i = 0; i < array.count; i++) {
        [result addObject:@(YES)];
    }
    return result;
}

#pragma mark - Search picker delegate

- (void)updateSelections:(NSMutableArray *)selected withTag:(NSInteger)tag
{
    if (tag == kGenderTag) { // Update list of genders
        self.selectedGenders = selected;
    } else if (tag == kRaceTag) { // Update list of races
        self.selectedRaces = selected;
    } else if (tag == kSexualOrientationTag) { // Update list of sexual orientations
        self.selectedSexualOrientations = selected;
    } else if (tag == kCountryTag) { // Update list of countries
        self.selectedCountries = selected;
    } else if (tag == kReligionTag) { // Update list of religions
        self.selectedReligions = selected;
    } else if (tag == kRelationshipStatusTag) { // Update list of relationship statuses
        self.selectedRelationshipStatuses = selected;
    } else if (tag == kPoliticalViewsTag) { // Update list of political views
        self.selectedPoliticalViews = selected;
    } else { // Handle error
        NSLog(@"Error: tag could not be identified");
    }
}

#pragma mark - Keyboard actions

// Dismisses keyboard when user presses return
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    
    return YES;
}

// Dismisses keyboard when user taps outside the text field
- (IBAction)hideKeyboard:(id)sender
{
    [self.view endEditing:YES];
}

#pragma mark - Buttons

- (IBAction)chooseGender:(id)sender
{
    [self openTableViewWithTag:kGenderTag array:self.selectedGenders];
}

- (IBAction)chooseRace:(id)sender
{
    [self openTableViewWithTag:kRaceTag array:self.selectedRaces];
}

- (IBAction)chooseSexualOrientation:(id)sender
{
    [self openTableViewWithTag:kSexualOrientationTag array:self.selectedSexualOrientations];
}

- (IBAction)chooseCountry:(id)sender
{
    [self openTableViewWithTag:kCountryTag array:self.selectedCountries];
}

- (IBAction)chooseReligion:(id)sender
{
    [self openTableViewWithTag:kReligionTag array:self.selectedReligions];}

- (IBAction)chooseRelationshipStatus:(id)sender
{
    [self openTableViewWithTag:kRelationshipStatusTag array:self.selectedRelationshipStatuses];
}

- (IBAction)choosePoliticalViews:(id)sender
{
    [self openTableViewWithTag:kPoliticalViewsTag array:self.selectedPoliticalViews];
}

- (void)openTableViewWithTag:(NSInteger)tag array:(NSMutableArray *)array
{
    SearchPickerTableViewController *sptvc = [[SearchPickerTableViewController alloc] initWithTag:tag
                                                                                   selectedFields:array];
    sptvc.delegate = self;
    UINavigationController *pnc = [[UINavigationController alloc] initWithRootViewController:sptvc];
    [self presentViewController:pnc animated:YES completion:nil];
}

- (IBAction)displaySearchResults:(id)sender
{
    // Search for matching users
    PFQuery *query = [PFUser query];
    
    NSMutableArray *queryGenders = [NSMutableArray array];
    for (int i = 0; i < [self.selectedGenders count]; i++) {
        if ([self.selectedGenders[i] boolValue]) {
            [queryGenders addObject:[FieldsPickerConstants getGenders][i]];
        }
    }
    [query whereKey:@"gender" containedIn:queryGenders];
    
    NSMutableArray *queryRaces = [NSMutableArray array];
    for (int i = 0; i < [self.selectedRaces count]; i++) {
        if ([self.selectedRaces[i] boolValue]) {
            [queryRaces addObject:[FieldsPickerConstants getRaces][i]];
        }
    }
    [query whereKey:@"race" containedIn:queryRaces];
    
    NSMutableArray *querySexualOrientations = [NSMutableArray array];
    for (int i = 0; i < [self.selectedSexualOrientations count]; i++) {
        if ([self.selectedSexualOrientations[i] boolValue]) {
            [querySexualOrientations addObject:[FieldsPickerConstants getSexualOrientations][i]];
        }
    }
    [query whereKey:@"sexualOrientation" containedIn:querySexualOrientations];
    
    NSMutableArray *queryCountries = [NSMutableArray array];
    for (int i = 0; i < [self.selectedCountries count]; i++) {
        if ([self.selectedCountries[i] boolValue]) {
            [queryCountries addObject:[FieldsPickerConstants getCountries][i]];
        }
    }
    [query whereKey:@"country" containedIn:queryCountries];
    
    NSMutableArray *queryReligions = [NSMutableArray array];
    for (int i = 0; i < [self.selectedReligions count]; i++) {
        if ([self.selectedReligions[i] boolValue]) {
            [queryReligions addObject:[FieldsPickerConstants getReligions][i]];
        }
    }
    [query whereKey:@"religion" containedIn:queryReligions];
    
    NSMutableArray *queryRelationshipStatuses = [NSMutableArray array];
    for (int i = 0; i < [self.selectedRelationshipStatuses count]; i++) {
        if ([self.selectedRelationshipStatuses[i] boolValue]) {
            [queryRelationshipStatuses addObject:[FieldsPickerConstants getRelationshipStatuses][i]];
        }
    }
    [query whereKey:@"relationshipStatus" containedIn:queryRelationshipStatuses];
    
    NSMutableArray *queryPoliticalViews = [NSMutableArray array];
    for (int i = 0; i < [self.selectedPoliticalViews count]; i++) {
        if ([self.selectedPoliticalViews[i] boolValue]) {
            [queryPoliticalViews addObject:[FieldsPickerConstants getPoliticalViews][i]];
        }
    }
    [query whereKey:@"politicalViews" containedIn:queryPoliticalViews];
    
    // Search for whole range if ages are left empty
    
    if (self.minAge.text.length == 0) {
        self.minAge.text = @"0";
    }
    
    if (self.maxAge.text.length == 0) {
        self.maxAge.text = @"100";
    }
    
    [query whereKey:@"age" greaterThanOrEqualTo:[NSNumber numberWithInteger:[self.minAge.text integerValue]]];
    [query whereKey:@"age" lessThanOrEqualTo:[NSNumber numberWithInteger:[self.maxAge.text integerValue]]];
    
    [query whereKey:@"canonicalCity" hasPrefix:[self.city.text lowercaseString]];
    [query whereKey:@"canonicalEducation" hasPrefix:[self.education.text lowercaseString]];
    [query whereKey:@"canonicalOccupation" hasPrefix:[self.occupation.text lowercaseString]];
    
    if (self.searchType.selectedSegmentIndex == kUsersIndex) { // Display users
        UserTableViewController *utvc = [[UserTableViewController alloc] initWithStyle:UITableViewStylePlain
                                                                                 query:query
                                                                                  user:nil
                                                                               context:@"Advanced Search"];
        [self.navigationController pushViewController:utvc animated:YES];
    } else if (self.searchType.selectedSegmentIndex == kPostsIndex) { // Display posts by those users
        PFQuery *postQuery = [PFQuery queryWithClassName:@"Post"];
        [postQuery whereKey:@"parent" matchesQuery:query];
       // [postQuery orderByDescending:@"views"]; // Order by number of views
        FeedTableViewController *ftvc = [[FeedTableViewController alloc] initWithStyle:UITableViewStylePlain
                                                                                 query:postQuery
                                                                                  user:nil
                                                                               context:@"Advanced Search"];
        [self.navigationController pushViewController:ftvc animated:YES];
    }
}

@end
