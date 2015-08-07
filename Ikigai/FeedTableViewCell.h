//
//  FeedTableViewCell.h
//  Ikigai
//
//  Created by Alexandre Perozim de Faveri on 7/15/15.
//  Copyright (c) 2015 Team Ikigai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ParseUI/ParseUI.h>

@class FeedCellViewController;

@interface FeedTableViewCell : PFTableViewCell

@property (weak, nonatomic) FeedCellViewController *viewController;

@end
