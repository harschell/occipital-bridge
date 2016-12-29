/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */
 
//  Description:
//
// There are two main parts to the GazeComponent system:
// 1)  Receivers of GazePointerProtocol that get the active gaze selection events
// 2)  GeometryNodes that may offer a form of interactivity if they implement the EventComponentProtocol
//
//  The gaze tracking system reports to all registerd GazePointerProtocol objects
//  when gaze enters, stays, and exits any GeometryNode
//
//  All GeometryNode objects must be connected to the world with registerNodeToEntity, or it won't work.
//  And activation of the GeometryNode has to be done by registering it with:
//   [[[SceneManager main] createEntity] addComponent:geometryComponent]
//

#import <GameplayKit/GameplayKit.h>
#import <SceneKit/SceneKit.h>
#import "GazeComponent.h"

@protocol GazePointerProtocol

- (void) onGazeStart:(GazeComponent *) gazeComponent targetEntity:(GKEntity *) targetEntity intersection:(SCNHitTestResult *) intersection isInteractive:(bool)isInteractive;

- (void) onGazeStay:(GazeComponent *) gazeComponent targetEntity:(GKEntity *) targetEntity intersection:(SCNHitTestResult *) intersection isInteractive:(bool)isInteractive;

- (void) onGazeExit:(GazeComponent *) gazeComponent targetEntity:(GKEntity *) targetEntity;

@end
