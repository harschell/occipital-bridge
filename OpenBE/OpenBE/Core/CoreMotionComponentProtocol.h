/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import <GameplayKit/GameplayKit.h>
#import <SceneKit/SceneKit.h>

@protocol CoreMotionComponentProtocol

- (bool) handleMotionTransform:(GLKMatrix4)transform;

@end
