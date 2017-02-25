/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import "../Core/Core.h"

@class PortalComponent;

/**
 * Enums for selecting the current portal mode.
 */
typedef NS_ENUM (NSUInteger, VRWorldMode) {
    VRWorldRobotRoom = 0,
    VRWorldBookstore,
};

@interface VRWorldComponent : Component

@property(nonatomic, strong) PortalComponent *portalComponent;
@property(nonatomic) VRWorldMode mode;

/**
 * Align the VRWorld to a movable node, like a Portal, so our entry/exit is consistenly oriented.
 */
- (void)alignVRWorldToNode:(SCNNode*)node;

@end
