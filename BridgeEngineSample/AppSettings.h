/*
    This file is part of the Structure SDK.
    Copyright © 2016 Occipital, Inc. All rights reserved.
    http://structure.io
*/

#import <Foundation/Foundation.h>

@interface AppSettings : NSObject 

+ (bool) booleanValueFromAppSetting:(NSString*)settingsKey defaultValueIfSettingIsNotInBundle:(bool)defaultValue;

@end
