/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import <GameplayKit/GameplayKit.h>
#import <SceneKit/SceneKit.h>
#import "../Core/Core.h"

#define GAZE_INTERSECTION_FAR_DISTANCE 100

@interface GazeComponent : Component <ComponentProtocol>

@property (atomic) GLKVector3 intersection;
@property (atomic) float intersectionDistance; // MAX_FLOAT if no intersection.

@end
