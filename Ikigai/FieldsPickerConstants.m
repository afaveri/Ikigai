//
//  FieldsPickerConstants.m
//  Ikigai
//
//  Created by Alexandre Perozim de Faveri on 7/20/15.
//  Copyright (c) 2015 Team Ikigai. All rights reserved.
//

#import "FieldsPickerConstants.h"

@implementation FieldsPickerConstants

const NSInteger kGenderTag = 0;
const NSInteger kRaceTag = 1;
const NSInteger kSexualOrientationTag = 2;
const NSInteger kCountryTag = 3;
const NSInteger kReligionTag = 4;
const NSInteger kRelationshipStatusTag = 5;
const NSInteger kPoliticalViewsTag = 6;

+ (NSArray *)getGenders
{
    static NSArray *genders;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        genders = @[@"", @"Male", @"Female", @"Transgender", @"Other"];
    });
    
    return genders;
}

+ (NSArray *)getRaces
{
    static NSArray *races;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        races = @[@"", @"White", @"Black", @"American Indian", @"Asian Indian", @"Chinese",
                    @"Filipino", @"Japanese", @"Korean", @"Vietnamese", @"Other Asian", @"Native Hawaiian", @"Guamanian",
                    @"Samoan", @"Other Pacific Islander", @"Other"];
    });
    
    return races;
}

+ (NSArray *)getSexualOrientations
{
    static NSArray *sexualOrientations;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sexualOrientations = @[@"", @"Heterosexual", @"Homosexual", @"Bisexual", @"Asexual", @"Other"];
    });
    
    return sexualOrientations;
}

+ (NSArray *)getCountries
{
    static NSArray *sortedCountries;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableArray *countries = [NSMutableArray arrayWithCapacity:[[NSLocale ISOCountryCodes] count]];
        
        for (NSString *countryCode in [NSLocale ISOCountryCodes])
        {
            NSString *identifier = [NSLocale localeIdentifierFromComponents:[NSDictionary dictionaryWithObject:countryCode
                                                                                                        forKey:NSLocaleCountryCode]];
            NSString *country = [[NSLocale currentLocale] displayNameForKey:NSLocaleIdentifier value:identifier];
            [countries addObject:country];
        }
        
        NSString *empty = @"";
        [countries addObject:empty];
        sortedCountries = [countries sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    });
    
    return sortedCountries;
}

+ (NSArray *)getReligions
{
    static NSArray *religions;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        religions = @[@"", @"Christianity", @"Hinduism", @"Islam", @"Chinese Folk Religion", @"Buddhism", @"Judaism", @"Taoism", @"Shinto", @"None", @"Other"];
    });
    
    return religions;
}

+ (NSArray *)getRelationshipStatuses
{
    static NSArray *relationshipStatuses;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        relationshipStatuses = @[@"", @"Single", @"In a Relationship", @"Married", @"Widowed", @"Divorced"];
    });
    
    return relationshipStatuses;
}

+ (NSArray *)getPoliticalViews
{
    static NSArray *politicalViews;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        politicalViews = @[@"", @"Liberal", @"Conservative", @"Libertarian", @"Communist", @"Anarchist", @"Other"];
    });
    
    return politicalViews;
}

@end
