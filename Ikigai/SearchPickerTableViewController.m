//
//  SearchPickerTableViewController.m
//  Ikigai
//
//  Created by Alexandre Perozim de Faveri on 7/19/15.
//  Copyright (c) 2015 Team Ikigai. All rights reserved.
//

#import "SearchPickerTableViewController.h"
#import "FieldsPickerConstants.h"

@interface SearchPickerTableViewController ()

@property (strong, nonatomic) NSMutableArray *selected;
@property (strong, nonatomic) NSArray *names;
@property (assign, nonatomic) NSInteger tag;
@property (assign, nonatomic) BOOL allSelected;

@end

@implementation SearchPickerTableViewController

- (instancetype)initWithTag:(NSInteger)tag selectedFields:(NSMutableArray *)selected
{
    self = [super init];
    if (self) {
        _tag = tag;
        _selected = selected;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                          target:self
                                                                          action:@selector(applySearchPreferences:)];
    UIBarButtonItem *selectAll = [[UIBarButtonItem alloc] initWithTitle:@"Clear"
                                                                  style:UIBarButtonItemStylePlain
                                                                 target:self
                                                                 action:@selector(selectAll:)];
    self.navigationItem.rightBarButtonItem = done;
    self.navigationItem.leftBarButtonItem = selectAll;
    self.allSelected = YES;
    
    // Identify the correct names to display
    if (self.tag == kGenderTag) { // Get list of genders
        self.names = [FieldsPickerConstants getGenders];
        self.navigationItem.title = @"Gender";
    } else if (self.tag == kRaceTag) { // Get list of races
        self.names = [FieldsPickerConstants getRaces];
        self.navigationItem.title = @"Race";
    } else if (self.tag == kSexualOrientationTag) { // Get list of sexual orientations
        self.names = [FieldsPickerConstants getSexualOrientations];
        self.navigationItem.title = @"Sexual Orientation";
    } else if (self.tag == kCountryTag) { // Get list of countries
        self.names = [FieldsPickerConstants getCountries];
        self.navigationItem.title = @"Country";
    } else if (self.tag == kReligionTag) { // Get list of religions
        self.names = [FieldsPickerConstants getReligions];
        self.navigationItem.title = @"Religion";
    } else if (self.tag == kRelationshipStatusTag) { // Get list of relationship statuses
        self.names = [FieldsPickerConstants getRelationshipStatuses];
        self.navigationItem.title = @"Relationship Status";
    } else if (self.tag == kPoliticalViewsTag) { // Get list of political views
        self.names = [FieldsPickerConstants getPoliticalViews];
        self.navigationItem.title = @"Political Views";
    } else { // Handle error
        NSLog(@"Error: tag could not be identified");
    }
}

- (IBAction)applySearchPreferences:(id)sender
{
    // Check if there is at least one field selected
    BOOL empty = YES;
    for (int i = 0; i < [self.selected count]; i++) {
        if ([self.selected[i] boolValue]) {
            empty = NO;
            break;
        }
    }
    
    if (empty) { // Prompt the user to choose at least one field
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Empty Selection"
                                                        message:@"Please choose at least one field."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    } else {
        // Update selected fields
        [self.delegate updateSelections:self.selected
                                withTag:self.tag];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (IBAction)selectAll:(id)sender
{
    if (self.allSelected) { // Clear all selections
        for (int i = 0; i < [self.selected count]; i++) {
            [self.selected replaceObjectAtIndex:i withObject:@(NO)];
        }
        ((UIBarButtonItem *)sender).title = @"Select All";
        self.allSelected = NO;
    } else { // Select all fields
        for (int i = 0; i < [self.selected count]; i++) {
            [self.selected replaceObjectAtIndex:i withObject:@(YES)];
        }
        ((UIBarButtonItem *)sender).title = @"Clear";
        self.allSelected = YES;
    }
    // Reload checkmarks
    [self.tableView reloadData];
}

#pragma mark - Table view data source


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.selected.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier = @"searchCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
    }
    
    // Disable highlighting in selection
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    
    if ([self.selected[indexPath.row] boolValue]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    if (indexPath.row == 0) {
        cell.textLabel.text = @"(Not Specified)";
    } else {
        cell.textLabel.text = self.names[indexPath.row];
    }
    
    return cell;
}


#pragma mark - Table view delegate


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.selected[indexPath.row] boolValue]) { // Deselect field
        self.selected[indexPath.row] = [NSNumber numberWithBool:NO];
        [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryNone;
    } else { // Select field
        self.selected[indexPath.row] = [NSNumber numberWithBool:YES];
        [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
    }
}

@end
