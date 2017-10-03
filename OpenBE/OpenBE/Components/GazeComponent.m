/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import "GazeComponent.h"
#import "GazePointerProtocol.h"
#import "../Core/Core.h"
#import "../Utils/ComponentUtils.h"
@import GLKit;

@interface GazeComponent()
@property (strong) GKEntity * activeEntity;
@property CFTimeInterval lastUpdate;
@end

@implementation GazeComponent

- (void) start {
    [super start];
    self.activeEntity = NULL;
    self.intersectionDistance = GAZE_INTERSECTION_FAR_DISTANCE;
}

- (void) updateWithDeltaTime:(NSTimeInterval)seconds {
    if( ![self isEnabled] ) return;
    
    // Let's only run this 5 times a second!
    CFTimeInterval startTime = CACurrentMediaTime();
    if (startTime - self.lastUpdate < 1.0 / 5.0) {
        return;
    }
    self.lastUpdate = startTime;
    
    float maxDistance = GAZE_INTERSECTION_FAR_DISTANCE;
        
    SCNVector3 from = SCNVector3FromGLKVector3( [Camera main].position );
    SCNVector3 to = SCNVector3FromGLKVector3( GLKVector3Add( [Camera main].position, GLKVector3MultiplyScalar([Camera main].reticleForward, maxDistance) ) );
    
    if( (from.x == 0.f && from.y == 0.f && from.z == 0.f) ||
        (to.x == 0.f && to.y == 0.f && to.z == 0.f) ||
        (from.x == to.x && from.y == to.y && from.z == to.z ) ||
        isnan(from.x) || isnan(from.y) || isnan(from.z) ||
        isnan(to.x) || isnan(to.y) || isnan(to.z) ) {
        return;
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
                    if( !(resultPhysics.node.categoryBitMask & RAYCAST_IGNORE_BIT) ) {
                        if (resultPhysics == nil ||
                            GLKVector3Distance([Camera main].position, SCNVector3ToGLKVector3(hitTestResult.worldCoordinates)) <
                            GLKVector3Distance([Camera main].position, SCNVector3ToGLKVector3(resultPhysics.worldCoordinates))) {
                            
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
    
    if( resultPhysics && result && GLKVector3Distance([Camera main].position, SCNVector3ToGLKVector3(resultPhysics.worldCoordinates)) < GLKVector3Distance([Camera main].position, SCNVector3ToGLKVector3(result.worldCoordinates))) {
        result = resultPhysics;
    }

    // Get all the late gaze pointer handlers.
    NSMutableArray *gazePointers = [ComponentUtils getComponentsFromEntity:self.entity ofProtocol:@protocol(GazePointerProtocol)];

    if( result ) {
        // find entity of component
        GKEntity * resultEntity = [result.node valueForKey:@"entity"];
        SCNNode * resultNode = result.node;
        
        while( !resultEntity && resultNode.parentNode ) {
            resultNode = resultNode.parentNode;
            resultEntity = [resultNode valueForKey:@"entity"];
        }

        GKComponent<EventComponentProtocol> *entityEventComponent = (GKComponent<EventComponentProtocol> *)[ComponentUtils getComponentFromEntity:resultEntity ofProtocol:@protocol(EventComponentProtocol)];
        bool isInteractive = entityEventComponent != NULL;
        
        self.intersection = SCNVector3ToGLKVector3([result worldCoordinates]);
        self.intersectionDistance = GLKVector3Distance([Camera main].position, _intersection);

        // Changing activeEntity, we must gazeExit the activeEntity first.
        if( resultEntity != self.activeEntity ) {
            GKComponent<EventComponentProtocol> *entityEventComponent = (GKComponent<EventComponentProtocol> *)[ComponentUtils getComponentFromEntity:self.activeEntity ofProtocol:@protocol(EventComponentProtocol)];
            if( entityEventComponent != NULL && [entityEventComponent respondsToSelector:@selector(gazeExit:)]) {
                [entityEventComponent gazeExit:self];
            }

            for( GKComponent <GazePointerProtocol> * component in gazePointers ) {
                [component onGazeExit:self targetEntity:self.activeEntity];
            }
        }
        
        // Either Start on a new entity, or Stay the existing activeEntity.
        for( GKComponent <GazePointerProtocol> * component in gazePointers ) {
            if( resultEntity != self.activeEntity ) {
                if( entityEventComponent != NULL && [entityEventComponent respondsToSelector:@selector(gazeStart:intersection:)]) {
                    [entityEventComponent gazeStart:self intersection:result];
                }
                [component onGazeStart:self targetEntity:resultEntity intersection:result isInteractive:isInteractive];
            } else {
                if( entityEventComponent != NULL && [entityEventComponent respondsToSelector:@selector(gazeStay:intersection:)]) {
                    [entityEventComponent gazeStay:self intersection:result];
                }
                [component onGazeStay:self targetEntity:resultEntity intersection:result isInteractive:isInteractive];
            }
        }

        self.activeEntity = resultEntity;
    } else {
        self.intersection = SCNVector3ToGLKVector3(to);
        self.intersectionDistance = GAZE_INTERSECTION_FAR_DISTANCE;

        GKComponent<EventComponentProtocol> *entityEventComponent = (GKComponent<EventComponentProtocol> *)[ComponentUtils getComponentFromEntity:self.activeEntity ofProtocol:@protocol(EventComponentProtocol)];
        if( entityEventComponent != NULL && [entityEventComponent respondsToSelector:@selector(gazeExit:)]) {
            [entityEventComponent gazeExit:self];
        }

        for( GKComponent <GazePointerProtocol> * component in gazePointers ) {
            [component onGazeExit:self targetEntity:self.activeEntity];
        }
        self.activeEntity = NULL;
    }
}

@end
