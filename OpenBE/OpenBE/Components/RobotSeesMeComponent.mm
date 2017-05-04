/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */


#import "RobotSeesMeComponent.h"
#import "../Utils/ComponentUtils.h"
#import "RobotMeshControllerComponent.h"
#import "../Utils/SceneKitTools.h"
#import <GLKit/GLKit.h>

@implementation RobotSeesMeComponent

- (void) start {
    [super start];
}

- (void) updateWithDeltaTime:(NSTimeInterval)seconds {
    if( ![self isEnabled] ) return;
    
    RobotMeshControllerComponent *meshControllerComponent = (RobotMeshControllerComponent * )[ComponentUtils getComponentFromEntity:self.entity ofClass:[RobotMeshControllerComponent class]];
    SCNNode *robotSensorNode = meshControllerComponent.sensorCtrl;
    
    SCNNode *cameraNode = [Camera main].node;
    if( cameraNode == nil ) {
        return;
    }
    
    GLKVector3 from = SCNVector3ToGLKVector3([SceneKitTools getWorldPos:cameraNode]);
    GLKVector3 fromFwd = SCNVector3ToGLKVector3([SceneKitTools getLookAtVectorOfNode:cameraNode]);
    GLKVector3 to = SCNVector3ToGLKVector3([SceneKitTools getWorldPos:robotSensorNode]);
    GLKVector3 toFwd = SCNVector3ToGLKVector3([SceneKitTools getLookAtVectorOfNode:robotSensorNode]);

    // Early orientation checks...
    
    // if camera gaze is within 45 degrees of line of sight of robot.
    GLKVector3 fromAimAtTo = GLKVector3Normalize(GLKVector3Subtract(to, from));
    if( GLKVector3DotProduct(fromFwd, fromAimAtTo) < cos(M_PI_4) ) {
        self.mainCameraSeesRobot = NO;
        self.robotSeesMainCamera = NO;
        return;
    } else {
        self.mainCameraSeesRobot = YES;
    }

    // if robot gaze is within 45 degrees of line of sight of camera.
    GLKVector3 toAimAtFrom = GLKVector3Normalize(GLKVector3Subtract(from, to));
    if( GLKVector3DotProduct(toFwd, toAimAtFrom) < cos(M_PI_4) ) {
        self.robotSeesMainCamera = NO;
        return;
    }

    // TODO: Get gaze point-to-point testing working.... for now just see camera.
    self.robotSeesMainCamera = YES;
}
@end
