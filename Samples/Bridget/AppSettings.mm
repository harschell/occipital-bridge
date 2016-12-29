/*
    This file is part of the Structure SDK.
    Copyright © 2016 Occipital, Inc. All rights reserved.
    http://structure.io
*/

#import "AppSettings.h"

// Retrieves the defaults (as a dictonary) from the app settings bundle.
// Returns nil if there are any troubles retrieving this.
NSDictionary* defaultsFromSettingsBundle()
{
    NSString *settingsBundle = [[NSBundle mainBundle] pathForResource:@"Settings" ofType:@"bundle"];
    
    if (!settingsBundle)
        return nil;
    
    NSString *plistFullName = [NSString stringWithFormat:@"%@.plist", @"Root"];
    
    NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:[settingsBundle stringByAppendingPathComponent:plistFullName]];

    if (!settings)
        return nil;
    
    NSArray *preferences = [settings objectForKey:@"PreferenceSpecifiers"];
    
    if (!preferences)
        return nil;
    
    NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
    
    for (NSDictionary *prefSpecification in preferences)
    {
        NSString *key = [prefSpecification objectForKey:@"Key"];

        id value = [prefSpecification objectForKey:@"DefaultValue"];
        
        // Populate the default in the dictionary.
        
        if (key && value)
            [defaults setObject:value forKey:key];
        
        // FIXME: App settings sub-panes are not handled.
    }
    
    return defaults;
}

void registerDefaultsFromSettingsBundle()
{
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultsFromSettingsBundle()];
}

id getValueForSettingCommon(NSString* key, id defaultValueIfSettingIsNotInBundle)
{
    NSLog(@" key %@", key);
    
    // Lazy-initialize defaults on first request by parsing the Settings bundle.
    static bool hasParsedSettingsBundleDefaults = false;
    
    if(!hasParsedSettingsBundleDefaults)
    {
        NSLog(@"Lazy-initializing Settings.bundle default settings.");
        hasParsedSettingsBundleDefaults = true;
        registerDefaultsFromSettingsBundle();
    }
    
    // It's possible that [NSUserDefaults standardUserDefaults] may return a value for a default even if the settings bundle has been removed.
    // To fix this, if the settings bundle is missing, then we return the code-specified "defaultValueIfNoSettingsBundle".
    
    static bool hasSettingsBundle = [[NSBundle mainBundle] pathForResource:@"Settings" ofType:@"bundle"] != nil;
    
    if(hasSettingsBundle)
    {
        id settingValue = [[NSUserDefaults standardUserDefaults] objectForKey:key];
        
        // If the setting is in the Bundle, return the value (or its bundle-specified default).

        if(settingValue)
            return settingValue;
        else
            NSLog(@"The setting '%s' was not found in Settings.bundle. Did you mean to add it?", [key UTF8String]);
    }
    
    // If we get here, it means the setting bundle didn't exist or else it didn't contain this setting.

    return defaultValueIfSettingIsNotInBundle;
}

@implementation AppSettings

+ (bool) booleanValueFromAppSetting:(NSString*)settingsKey defaultValueIfSettingIsNotInBundle:(bool)defaultValue
{
    return [getValueForSettingCommon(settingsKey, [NSNumber numberWithFloat:defaultValue]) boolValue];
}

@end


