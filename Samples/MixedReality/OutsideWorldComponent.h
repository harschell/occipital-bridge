/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import <objc/NSObjCRuntime.h>
#import "Core.h"
#import "WindowComponent.h"

@interface OutsideWorldComponent : Component

@property(readonly) SCNNode *animationNode; // handles animating the world left / right

/**
 * Align the VRWorld to a movable node, like a Portal, so our entry/exit is consistenly oriented.
 */
- (void)alignVRWorldToNode:(SCNNode*)node;

@end
