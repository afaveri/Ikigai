//
//  SearchPickerTableViewController.h
//  Ikigai
//
//  Created by Alexandre Perozim de Faveri on 7/19/15.
//  Copyright (c) 2015 Team Ikigai. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SearchPickerDelegate <NSObject>

- (void)updateSelections:(NSMutableArray *)selected withTag:(NSInteger)tag;

@end

@interface SearchPickerTableViewController : UITableViewController

@property (weak, nonatomic) id<SearchPickerDelegate> delegate;

- (instancetype)initWithTag:(NSInteger)tag selectedFields:(NSMutableArray *)selected;

@end
