//
//  ProfileNavigationController.m
//  Ikigai
//
//  Created by Alexandre Perozim de Faveri on 8/3/15.
//  Copyright (c) 2015 Team Ikigai. All rights reserved.
//

#import "ProfileNavigationController.h"

@implementation ProfileNavigationController

-(NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotate
{
    return NO;
}

@end
