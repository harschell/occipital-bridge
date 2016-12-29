/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import "../Core/Component.h"

@interface NavigationComponent : Component

- (void) preProcess:(SCNNode *)collisionNode startY:(float)startY endY:(float)endY minBB:(GLKVector2)minBB maxBB:(GLKVector2)maxBB resolution:(float)resolution agentRadius:(float)radius;

- (float) getHeight:(GLKVector3)position;
- (float) getInterpolatedHeight:(GLKVector3)position;
- (GLKVector3) getRandomPoint:(GLKVector3)position maxDistance:(float)distance minY:(float)minY maxTry:(int)maxTry;

@end
