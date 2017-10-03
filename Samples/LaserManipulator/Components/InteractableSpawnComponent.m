/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2017 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#define SPAWN_MAX 5

#import "InteractableSpawnComponent.h"
#import "OpenBE/Core/Core.h"

@interface InteractableSpawnComponent()
    @property(nonatomic) NSInteger nameCount;
@end

@implementation InteractableSpawnComponent

- (instancetype)init {
    if (self = [super init]) {
        self.spawnedComponents = [@[] mutableCopy];
        self.spawnMax = SPAWN_MAX;
        self.nameCount = 1;
    }
    return self;
}

- (void)spawnWithPosition:(SCNVector3)position {
    if (self.componentToSpawn == nil) {
        be_dbg("InteractableSpawnComponent: No Spawn Object set");
        return;
    }
    
    GeometryComponent *component = [self.componentToSpawn copy];
    
    [[[SceneManager main] createEntity] addComponent:component];
    [[Scene main].rootNodeForGaze addChildNode:component.node];
    [component.node setValue:component.entity forKey:@"entity"];
    component.node.position = position;
    component.node.name = [NSString stringWithFormat:@"Item %li", (long)self.nameCount++];
    
    [self.spawnedComponents addObject:component];
    if (self.spawnedComponents.count > self.spawnMax) {  // despawn the first component
        GeometryComponent *firstComponent = [self.spawnedComponents firstObject];
        [self despawnComponent:firstComponent];
    }
}

/// If the ball is thrown out of the area, it eventually causes a crash here.
/// Must be some sort of catch all that's despawning it without me looking.
- (void)despawnComponent:(GeometryComponent *)component {
    [self.spawnedComponents removeObject:component];
    [[SceneManager main] removeEntity:component.entity];
    [component.node removeFromParentNode];
}

@end
