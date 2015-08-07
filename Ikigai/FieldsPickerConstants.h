//
//  FieldsPickerConstants.h
//  Ikigai
//
//  Created by Alexandre Perozim de Faveri on 7/20/15.
//  Copyright (c) 2015 Team Ikigai. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FieldsPickerConstants : NSObject

extern const NSInteger kGenderTag;
extern const NSInteger kRaceTag;
extern const NSInteger kSexualOrientationTag;
extern const NSInteger kCountryTag;
extern const NSInteger kReligionTag;
extern const NSInteger kRelationshipStatusTag;
extern const NSInteger kPoliticalViewsTag;

+ (NSArray *)getGenders;
+ (NSArray *)getRaces;
+ (NSArray *)getSexualOrientations;
+ (NSArray *)getCountries;
+ (NSArray *)getReligions;
+ (NSArray *)getRelationshipStatuses;
+ (NSArray *)getPoliticalViews;

@end
