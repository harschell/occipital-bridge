/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import <objc/NSObjCRuntime.h>
#import "Core.h"
#import "WindowComponent.h"

/**
 * Enums for selecting the current portal mode.
 */
typedef NS_ENUM (NSUInteger, OutsideWorldMode) {
    WindowWorldRobotRoom = 0,
    WindowWorldBookstore,
};

@interface OutsideWorldComponent : Component

@property(nonatomic, strong) WindowComponent *windowComponent;
@property(nonatomic) OutsideWorldMode mode;

/**
 * Align the VRWorld to a movable node, like a Portal, so our entry/exit is consistenly oriented.
 */
- (void)alignVRWorldToNode:(SCNNode*)node;

@end
