/*
    This file is part of the Structure SDK.
    Copyright © 2016 Occipital, Inc. All rights reserved.
    http://structure.io
*/

#pragma once

#import "BridgeEngineAPI.h"
#import <Foundation/Foundation.h>

//------------------------------------------------------------------------------

BE_API bool getBooleanValueFromAppSettings (NSString* key, bool defaultValueIfSettingIsNotInBundle);
