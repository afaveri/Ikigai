//
//  RecorderViewController.h
//  Ikigai
//
//  Created by Alexandre Perozim de Faveri on 7/22/15.
//  Copyright (c) 2015 Team Ikigai. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RecorderViewController : UIImagePickerController <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

- (instancetype)initWithSourceType:(UIImagePickerControllerSourceType)sourceType NS_DESIGNATED_INITIALIZER;

@end
