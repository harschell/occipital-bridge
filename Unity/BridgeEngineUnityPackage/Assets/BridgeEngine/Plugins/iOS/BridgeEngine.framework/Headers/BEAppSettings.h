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
+ (BOOL) booleanValueFromAppSetting:(NSString*_Nonnull)settingsKey defaultValueIfSettingIsNotInBundle:(BOOL)defaultValue;
+ (void) setBooleanValue:(BOOL)value forAppSetting:(NSString*_Nonnull)settingsKey;

+ (float) floatValueFromAppSetting:(NSString*_Nonnull)settingsKey defaultValueIfSettingIsNotInBundle:(float)defaultValue;

/// Persistant storage of the manualDeviceName of a Bridge Controller.
+ (NSString*_Nullable) manualBridgeControllerDeviceName;

/// Set the persistant value of the manualDeviceName of a Bridge Controller.
+ (void) setManualBridgeControllerDeviceName:(NSString*_Nullable)manualDeviceName;

@end
