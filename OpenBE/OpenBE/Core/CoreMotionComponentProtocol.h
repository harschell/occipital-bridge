/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import <GamePlayKit/GamePlayKit.h>
#import <SceneKit/SceneKit.h>

@protocol CoreMotionComponentProtocol

- (bool) handleRotation:(GLKVector3)rotation;

@end