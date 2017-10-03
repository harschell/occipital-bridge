/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2017 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import <Foundation/Foundation.h>
#import <SceneKit/SceneKit.h>

/**
 `GeometryHitTest` is a convience class that performs a BE friendly raycast using a world start position, and a direction + distance.  It specifically looks for items that either:
      1. Have a SCNPhysicsBody.
      2. Have been added to the [Scene main].gazeNode
 */

@interface GeometryHitTest : NSObject

/**
 Performs a raycast with the supplied parameters.
 @param start The start position of the raycast in world space.
 @param forward The forward vector for the raycast in world space.
 @param maxDistance The maximum distand for the raycast.
 
 @return The nearest raycast object that either has an SCNPhysicsBody or has been added to the [Scene main].gazeNode.
 */
+ (SCNHitTestResult*)performHitTestWithStartPosition:(GLKVector3)start forwardOrientation:(GLKVector3)forward maxDistance:(float)maxDistance;

@end
