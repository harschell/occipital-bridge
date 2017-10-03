/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2017 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import "GeometryHitTest.h"

#import <OpenBE/Core/Core.h>
#import <OpenBE/Core/Scene.h>
#import <GLKit/GLKit.h>

@implementation GeometryHitTest

+ (SCNHitTestResult*)performHitTestWithStartPosition:(GLKVector3)start forwardOrientation:(GLKVector3)forward maxDistance:(float)maxDistance
{
    SCNVector3 from = SCNVector3FromGLKVector3(start);
    SCNVector3 to = SCNVector3FromGLKVector3( GLKVector3Add( start, GLKVector3MultiplyScalar(forward, maxDistance) ) );
    
    if( (from.x == 0.f && from.y == 0.f && from.z == 0.f) ||
       (to.x == 0.f && to.y == 0.f && to.z == 0.f) ||
       (from.x == to.x && from.y == to.y && from.z == to.z ) ||
       isnan(from.x) || isnan(from.y) || isnan(from.z) ||
       isnan(to.x) || isnan(to.y) || isnan(to.z) ) {
        return nil;
    }
    
    // hitTestWithSegmentFromPoint is extremely slow, so use a combination of physics test and
    // test children from rootNodeForGaze (basicaly, the robot and the UI).
    
    SCNHitTestResult * result = nil;
    SCNHitTestResult * resultGaze;
    SCNHitTestResult * resultPhysics;
    
    Scene *mainScene = [Scene main];
    SCNNode *gazeNode = mainScene.rootNodeForGaze;
    NSDictionary *options = @{SCNHitTestSortResultsKey:@YES, SCNHitTestBackFaceCullingKey:@NO};
    NSArray<SCNHitTestResult *> *hitTestGazeResults = [gazeNode hitTestWithSegmentFromPoint:from toPoint:to options:options];
    
    SCNPhysicsWorld *physicsWorld = mainScene.scene.physicsWorld;
    
    if( ![Scene main].rootNode.hidden ) {
        // TODO: couldn't figure out what this code does, but it can cause a crash.
        
        @try {
            NSDictionary *physicsRayOptions = @{
                                                SCNPhysicsTestBackfaceCullingKey:@NO,
                                                SCNPhysicsTestSearchModeKey:SCNPhysicsTestSearchModeAll};
            
            NSArray<SCNHitTestResult *> *hitTestPhysicsResults = [physicsWorld rayTestWithSegmentFromPoint:from toPoint:to options:physicsRayOptions];
            
            if( [hitTestPhysicsResults count] ) {
                
                for( SCNHitTestResult * hitTestResult in hitTestPhysicsResults ) {
                    //be_dbg("physics hit : %s", [hitTestResult.node.name UTF8String]);
                    if( !(resultPhysics.node.categoryBitMask & RAYCAST_IGNORE_BIT) ) {
                        if (resultPhysics == nil ||
                            GLKVector3Distance(start, SCNVector3ToGLKVector3(hitTestResult.worldCoordinates)) <
                            GLKVector3Distance(start, SCNVector3ToGLKVector3(resultPhysics.worldCoordinates))) {
                         
                            //be_dbg("physics hit counted : %s", [hitTestResult.node.name UTF8String]);
                            result = hitTestResult;
                            resultPhysics = hitTestResult;
                        }
                    }
                }
            }
            
        } @catch (NSException *exception) {
        } @finally {
        }
    }
    
    if( [hitTestGazeResults count] ) {
        for( resultGaze in hitTestGazeResults ) {
            if( !(resultGaze.node.categoryBitMask & RAYCAST_IGNORE_BIT) )  {
                result = resultGaze;
                break;
            }
        }
    }
    
    if( resultPhysics && result && GLKVector3Distance(start, SCNVector3ToGLKVector3(resultPhysics.worldCoordinates)) < GLKVector3Distance(start, SCNVector3ToGLKVector3(result.worldCoordinates))) {
        result = resultPhysics;
    }
    
    return result;
}

@end
