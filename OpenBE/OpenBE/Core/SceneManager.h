/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import <BridgeEngine/BridgeEngine.h>
#import "Core.h"

@interface SceneManager : NSObject

@property (strong) NSMutableArray * entities;
@property (weak) BEMixedRealityMode * mixedRealityMode;

+ (SceneManager *) main;

- (void) initWithMixedRealityMode:(BEMixedRealityMode *)mixedRealityMode stereo:(BOOL)stereo;
- (BOOL) isStereo;

- (void) addEntity:(GKEntity *) entity;
- (GKEntity *) createEntity;
- (GKEntity *) createEntityWithSceneNode:(SCNNode *)node;

- (void) startWithMixedRealityMode:(BEMixedRealityMode *) mixedRealityMode;

- (void) updateWithDeltaTime:(NSTimeInterval)seconds mixedRealityMode:(BEMixedRealityMode *) mixedRealityMode;
- (void) updateAtTime:(NSTimeInterval)time mixedRealityMode:(BEMixedRealityMode *) mixedRealityMode;


@end
