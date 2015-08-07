//
//  FeedTableViewController.m
//  Ikigai
//
//  Created by Alexandre Perozim de Faveri on 7/16/15.
//  Copyright (c) 2015 Team Ikigai. All rights reserved.
//

#import <Parse/Parse.h>
#import "FeedTableViewController.h"
#import "FeedTableViewCell.h"
#import "SearchTableViewController.h"
#import "AdvancedSearchViewController.h"
#import "FeedCellViewController.h"
#import "LocationSearchViewController.h"

@interface FeedTableViewController ()

@property (strong, nonatomic) UISearchController *searchController;
@property (strong, nonatomic) PFQuery *query;
@property (strong, nonatomic) NSString *context;
@property (strong, nonatomic) PFUser *user;
@property (strong, nonatomic) NSMutableArray *sortedObjects;

@end

@implementation FeedTableViewController

static const CGFloat feedCellHeight = 392.0;
static const CGFloat defaultCellHeight = 44.0;
static const CGFloat kSelfMultiplier = 25.0;
static const CGFloat kFollowingMultiplier = 50.0;
static const NSInteger kPostsPerPage = 25;

- (instancetype)initWithStyle:(UITableViewStyle)style query:(PFQuery *)query user:(PFUser *)user context:(NSString *)context
{
    self = [super initWithStyle:style];
    if (self) {
        // Displays items in the "Post" class
        self.parseClassName = @"Post";
        self.pullToRefreshEnabled = YES;
        self.paginationEnabled = YES;
        self.objectsPerPage = kPostsPerPage;
        self.query = query;
        self.user = user;
        self.context = context;
    }
    return self;
}

- (void)objectsDidLoad:(nullable NSError *)error
{
    [super objectsDidLoad:error];
    
    PFQuery *followersQuery = [PFQuery queryWithClassName:@"Follow"];
    [followersQuery whereKey:@"from" equalTo:[PFUser currentUser]];
    [followersQuery findObjectsInBackgroundWithBlock:^(NSArray *follows, NSError *error) {
        if (error) {
            NSLog(@"Error: %@", [error localizedDescription]);
            return;
        }
        
        self.sortedObjects = [self.objects mutableCopy];
        [self.sortedObjects sortUsingComparator:^NSComparisonResult(id a, id b) {
            PFObject *post1 = (PFObject *)a;
            PFObject *post2 = (PFObject *)b;
            
            return [self _compareFeedObject:post1 toObject:post2 withFollows:follows];
        }];
        
        for (int i = 0; i < self.sortedObjects.count; i++) {
            PFObject *post = self.sortedObjects[i];
            
            // Fetch and save the video
            PFFile *video = post[@"video"];
            [video getDataInBackgroundWithBlock:^(NSData *data, NSError *error){
                if (!error) {
                    // Name of the file (unique for each post)
                    NSString *fileName = [NSString stringWithFormat:@"%@.mp4", post.objectId];
                    NSURL *fileURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:fileName]];
                    
                    // Save video
                    [data writeToURL:fileURL atomically:YES];
                    
                    // Send notification for video ready
                    [[NSNotificationCenter defaultCenter] postNotificationName:[NSString stringWithFormat:@"%@", ((PFObject *)self.sortedObjects[i]).objectId] object:self];
                } else {
                    NSLog(@"Error: %@", [error localizedDescription]);
                }
            }];
        }
        
        [self.tableView reloadData];
    }];
}

- (NSComparisonResult)_compareFeedObject:(PFObject *)post1 toObject:(PFObject *)post2 withFollows:(NSArray *)follows
{
    CGFloat score1 = [self _scoreForFeedObject:post1 withFollows:follows];
    CGFloat score2 = [self _scoreForFeedObject:post2 withFollows:follows];
    
    if (score1 < score2) {
        return NSOrderedDescending;
    } else if (score1 > score2) {
        return NSOrderedAscending;
    } else {
        return NSOrderedSame;
    }
}

- (CGFloat)_scoreForFeedObject:(PFObject *)post withFollows:(NSArray *)follows
{
    NSTimeInterval timeSincePosted = [[NSDate date] timeIntervalSinceDate:post.createdAt];
    CGFloat score = ([(NSNumber *)post[@"views"] integerValue] + 1) / (timeSincePosted + 10.0);
    
    for (PFObject *follow in follows) {
        if (follow[@"to"] == post[@"parent"]) { // bonus points!
            score *= kFollowingMultiplier;
            break;
        } else if ([PFUser currentUser] == post[@"parent"]) { // small bonus
            score *= kSelfMultiplier;
            break;
        }
    }
    
    return score;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Get notified when application is about to enter foreground and reload data
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reloadData)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    
    // Create search table view controller
    SearchTableViewController *stvc = [[SearchTableViewController alloc] init];
    
    if (! [self.context isEqualToString:@"Advanced Search"]) { // Use the search controller
        self.searchController = [[UISearchController alloc] initWithSearchResultsController:stvc];
        self.searchController.searchResultsUpdater = stvc;
        self.searchController.dimsBackgroundDuringPresentation = YES;
        self.searchController.searchBar.delegate = stvc;
        
        // Pass a reference to the search controller
        stvc.searchController = self.searchController;
    }
    
    // Set navigation bar title and search options
    if (self.user == nil) {
        if ([self.context  isEqualToString: @"Feed"]) {// This is the Feed
            self.navigationItem.title = @"Feed";
            self.searchController.searchBar.scopeButtonTitles = @[@"Users", @"Posts"];
            
            // Add button for advanced search
            UIBarButtonItem *advancedSearch = [[UIBarButtonItem alloc] initWithTitle:[NSString stringWithFormat:@"%C%C", 0xD83D, 0xDD0E]
                                                                               style:UIBarButtonItemStyleDone
                                                                              target:self
                                                                              action:@selector(openAdvancedSearch:)];
            self.navigationItem.rightBarButtonItem = advancedSearch;
            
            // Add button for search by location
            UIBarButtonItem *locationSearch = [[UIBarButtonItem alloc] initWithTitle:[NSString stringWithFormat:@"%C%C", 0xD83C, 0xDF0E]
                                                                               style:UIBarButtonItemStyleDone
                                                                              target:self
                                                                              action:@selector(openLocationSearch:)];
            self.navigationItem.leftBarButtonItem = locationSearch;
        } else if ([self.context  isEqualToString: @"Advanced Search"]) { // This is Advanced Search
            self.navigationItem.title = @"Advanced Search Results";
        }
    } else { // Those are the posts of a specific user
        // Pass reference to the user
        stvc.user = self.user;
        self.searchController.searchBar.scopeButtonTitles = @[];
        if (self.user[@"name"] != nil) { // User has a name
            self.navigationItem.title = [NSString stringWithFormat:@"%@'s Posts", self.user[@"name"]];
        } else { // User didn't specify a name
            self.navigationItem.title = [NSString stringWithFormat:@"%@'s Posts", self.user.username];
        }
    }
    
    if (! [self.context isEqualToString:@"Advanced Search"]) { // Display search bar
        self.tableView.tableHeaderView = self.searchController.searchBar;
        [self.searchController.searchBar sizeToFit];
        self.definesPresentationContext = YES;
    }
}

- (void)reloadData
{
    [self loadObjects];
}

- (PFQuery *)queryForTable
{
    return self.query;
}

- (PFUI_NULLABLE PFObject *)objectAtIndexPath:(nullable NSIndexPath *)indexPath
{
    return self.sortedObjects[indexPath.row];
}

- (IBAction)openLocationSearch:(id)sender
{
    // Open location search
    LocationSearchViewController *lsvc = [[LocationSearchViewController alloc] init];
    UINavigationController *lsnc = [[UINavigationController alloc] initWithRootViewController:lsvc];
    
    [self presentViewController:lsnc animated:YES completion:nil];
}

- (IBAction)openAdvancedSearch:(id)sender
{
    AdvancedSearchViewController *asvc = [[AdvancedSearchViewController alloc] init];
    [self.navigationController pushViewController:asvc animated:YES];
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
        static NSString *feedIdentifier = @"feedCell";
        
        FeedTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:feedIdentifier];
        
        if (cell == nil) {
            cell = [[FeedTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:feedIdentifier];
            
            // Disable highlighting in selection
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            
            FeedCellViewController *fcvc = [[FeedCellViewController alloc] init];
            fcvc.view.frame = cell.contentView.bounds;
            cell.viewController = fcvc;
            [self addChildViewController:fcvc];
            [cell.contentView addSubview:fcvc.view];
        }
        
        cell.viewController.post = [self objectAtIndexPath:indexPath];
        
        return cell;
    }
}

- (PFTableViewCell *)tableView:(UITableView *)tableView cellForNextPageAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *loadCellIdentifier = @"loadMoreCell";
    
    PFTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:loadCellIdentifier];
    
    if (cell == nil) {
        cell = [[PFTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault  reuseIdentifier:loadCellIdentifier];
    }
    
    cell.textLabel.text = @"Load More...";
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == self.objects.count) { // "Load more" cell
        return defaultCellHeight;
    } else {
        return feedCellHeight;
    }
}

@end
