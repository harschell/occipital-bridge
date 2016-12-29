/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import <GameplayKit/GameplayKit.h>
#import <SceneKit/SceneKit.h>

#import "../Core/Core.h"

@interface BeamComponent : Component <ComponentProtocol>

@property (atomic) float beamWidth;
@property (atomic) float beamHeight;

@property (atomic) GLKVector3 startPos;
@property (atomic) GLKVector3 endPos;

- (void) start;
- (void) setEnabled:(bool)enabled;
- (void) setActive:(float)active beamWidth:(float)width beamHeight:(float)height;

@end
