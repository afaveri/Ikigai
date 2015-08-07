//
//  MainTabBarViewController.h
//  Ikigai
//
//  Created by Alexandre Perozim de Faveri on 7/21/15.
//  Copyright (c) 2015 Team Ikigai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVAudioPlayer.h>

@interface MainTabBarViewController : UITabBarController <UITabBarDelegate>

@property (nonatomic, strong) AVAudioPlayer *player;

@end
