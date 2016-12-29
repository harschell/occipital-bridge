/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import "../Core/Core.h"
#import <SceneKit/SceneKit.h>

/**
 * Calculate if robot can see the main camera,
 * or if the gaze is obscured by an obstacle.
 */
@interface RobotSeesMeComponent : Component
<
    ComponentProtocol
>

@property(atomic) BOOL mainCameraSeesRobot;
@property(atomic) BOOL robotSeesMainCamera;

@end
