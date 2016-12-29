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

/*
    if( from.x == 0.f && from.y == 0.f && from.z == 0.f ) {
        // don't know why: but if we continue now a bad access exception will be thrown
        // by rayTestWithSegmentFromPoint.
        // TODO: find out why and fix this.
        return;
    }

    // Do point-to-point checks to see if we're occluded by something.
    NSArray<SCNHitTestResult *> *hitTestGazeResults = [[Scene main].rootNodeForGaze hitTestWithSegmentFromPoint:SCNVector3FromGLKVector3(from) toPoint:SCNVector3FromGLKVector3(to) options:nil];
    NSArray<SCNHitTestResult *> *hitTestPhysicsResults = [[Scene main].scene.physicsWorld rayTestWithSegmentFromPoint:SCNVector3FromGLKVector3(from) toPoint:SCNVector3FromGLKVector3(to) options:nil];
    
    SCNHitTestResult * result;
    SCNHitTestResult * resultGaze;
    SCNHitTestResult * resultPhysics;
    
    if( [hitTestGazeResults count] ) {
        for( resultGaze in hitTestGazeResults ) {
            if( !(resultGaze.node.categoryBitMask & RAYCAST_IGNORE_BIT) ) break;
        }
    }

    result = resultGaze;
    if( [hitTestPhysicsResults count] ) {
        for( resultPhysics in hitTestPhysicsResults ) {
            if( !(resultPhysics.node.categoryBitMask & RAYCAST_IGNORE_BIT) ) break;
        }
    }
    
    // Map down the result from physics engine if it's closer.
    if( resultPhysics && result && GLKVector3Distance([Camera main].position, SCNVector3ToGLKVector3(resultPhysics.worldCoordinates)) < GLKVector3Distance([Camera main].position, SCNVector3ToGLKVector3(result.worldCoordinates))) {
        result = resultPhysics;
    }

    if( result && result.node == _robotSensorNode ) {
        self.robotSeesMainCamera = YES;
    } else {
        self.robotSeesMainCamera = NO;
    }
*/
}
@end
