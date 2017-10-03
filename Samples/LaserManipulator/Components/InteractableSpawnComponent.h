/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2017 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import <OpenBE/Core/GeometryComponent.h>
#import <SceneKit/SceneKit.h>

/**
 `InteractableSpawnComponent` is a component that is used to spawn other components.  It can spawn any component that subclasses GeometryComponent.
 
 @warning GeometryComponent performs a deep copy and creates new geometries and materials. Don't make a lot of copies or you'll hurt performance.
 */
@interface InteractableSpawnComponent : Component

/**
 Components that are spawned by this component are kept track of in this array. This allows us to set a maximum limit for spawned objects.
 */
@property (nonatomic, strong) NSMutableArray<GeometryComponent*> *spawnedComponents;

/**
 The maximum number of spawns this component may have at any given time.
 
 Defaults to 5.
*/
@property (nonatomic) NSInteger spawnMax;

/**
 The component this spawner creates a copy of with each spawn.
 */
@property (nonatomic, strong) GeometryComponent *componentToSpawn;

/**
 Spawns a new component and adds it to the [Scene main].gazeNode at the specified position.
 
 @params position Desired position of new object in world space.
 */
- (void)spawnWithPosition:(SCNVector3)position;

@end
