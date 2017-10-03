/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */
 
#import "BehaviourComponent.h"

// fwd decl
@class PathFinding;

@interface PathFindMoveToBehaviourComponent : BehaviourComponent

@property(nonatomic) GLKVector3 reachableReferencePoint; // Use this reachable point to do path recovery.
@property(nonatomic) float moveSpeedModifier; // Movement speed between calculated waypoints.
@property(nonatomic) float stoppingDistance; // The stopping distance to the targetPosition 
@property(nonatomic) BOOL showOccupancy;  // Show the occupancy grid.
@property(nonatomic) BOOL showConnectedComponents; // Show the colored connected components.
@property(nonatomic, readonly) BOOL pathFindingSucceded; // Return if we successfully found a path to target.

@property(nonatomic) BOOL showPathPlan; // Defaults to YES on every run.
@property(nonatomic) BOOL showSadOnPathingFailure; // Defaults to YES on every run.

@property (strong, readonly) PathFinding * pathFinding; // Provides path planning for general navigation
@property (strong, readonly) PathFinding * noCoverPathFinding; // Provides path planning but avoids going under objects

/**
 * Get the largest available component area, and search for a point that's open.
 */
- (GLKVector3) findLargestOpenAreaPoint:(PathFinding*) pathFinding;

- (BOOL) occupied:(GLKVector3)target;
- (float) durationToTarget:(GLKVector3) targetPosition;
- (void) runBehaviourFor:(float)seconds targetPosition:(GLKVector3) targetPosition callback:(void (^)(void))callbackBlock;

@end
