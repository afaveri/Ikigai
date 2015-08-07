//
//  PlacePickerViewController.h
//  Ikigai
//
//  Created by Alexandre Perozim de Faveri on 7/28/15.
//  Copyright (c) 2015 Team Ikigai. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GMSPlace;

@protocol PlacePickerDelegate <NSObject>

- (void)didPickPlace:(GMSPlace *)place;
- (void)didCancelPickingPlace;

@end

@interface PlacePickerViewController : UIViewController

@property (weak, nonatomic) UIViewController<PlacePickerDelegate> *delegate;

@end
