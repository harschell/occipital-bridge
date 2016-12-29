/*
    This file is part of the Structure SDK.
    Copyright © 2016 Occipital, Inc. All rights reserved.
    http://structure.io
*/

#import <BridgeEngine/BridgeEngineAPI.h>

#import <Foundation/Foundation.h>

/** Utility class to manage app settings in a persistent way
 @see BEDebugSettingsViewController
*/
BE_API
@interface BEAppSettings : NSObject
+ (BOOL) booleanValueFromAppSetting:(NSString* __nonnull)settingsKey defaultValueIfSettingIsNotInBundle:(BOOL)defaultValue;
+ (void) setBooleanValue:(BOOL)value forAppSetting:(NSString * __nonnull)settingsKey;
@end
