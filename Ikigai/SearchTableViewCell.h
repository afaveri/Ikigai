//
//  SearchTableViewCell.h
//  Ikigai
//
//  Created by Alexandre Perozim de Faveri on 8/3/15.
//  Copyright (c) 2015 Team Ikigai. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SearchTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *pictureImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;

@end
