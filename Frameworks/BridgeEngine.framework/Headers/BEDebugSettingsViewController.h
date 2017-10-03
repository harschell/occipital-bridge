/*
    This file is part of the Structure SDK.
    Copyright © 2016 Occipital, Inc. All rights reserved.
    http://structure.io
*/

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "BEAppSettings.h"

#import <BridgeEngine/BridgeEngineAPI.h>

@protocol BEDebugSettingsDelegate <NSObject>

/// Reset all the settings for release.
- (void) resetSettingsToDefaults;

/// User tapped on "Begin" to start the BE experience.
- (void) debugSettingsBegin;

@end

BE_API
@interface BEDebugSettingsViewController : UITableViewController
@property(nonatomic, weak) id<BEDebugSettingsDelegate> delegate;

/// Add a User Default's setting switch.
- (void) addKey:(NSString*)userDefaultKey label:(NSString*)label defaultBool:(BOOL)defaultBool;

@end
