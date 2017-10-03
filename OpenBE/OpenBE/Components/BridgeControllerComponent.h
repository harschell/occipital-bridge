/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2017 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import <Foundation/Foundation.h>
#import <SceneKit/SceneKit.h>
#import <BridgeEngine/BEController.h>

#import "OpenBE/Core/ComponentProtocol.h"
#import "OpenBE/Core/GeometryComponent.h"

@interface BridgeControllerComponent : GeometryComponent<ComponentProtocol>

/// Initialize the BridgeController
- (instancetype) init;

- (void) start;
- (void) setEnabled:(bool)enabled;
- (bool) isEnabled;
@end
