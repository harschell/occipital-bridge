/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */
//
// Design:
//  Selectable models are placed in 3D space.
//   Sometimes using the markupNode position and orientation to place it into the environment.
//   SelectableModelComponent *selectableModel = [[SelectableModelComponent alloc] initWithMarkupName:@"Name" withModelName:@"model.dae"];
//   [[[SceneManager main] createEntity] addComponent:selectableModel];

#import "../Core/EventComponentProtocol.h"
#import "../Core/ComponentProtocol.h"
#import "../Core/GeometryComponent.h"
#import "GazePointerProtocol.h"

typedef void (^callback)(void);

@interface SelectableModelComponent : GeometryComponent <EventComponentProtocol, ComponentProtocol>
@property(nonatomic) NSString *markupName;
@property(nonatomic, strong) callback callbackBlock;
@property(nonatomic, strong) callback callbackNotArmed; // Tried to hit the target but wasn't armed and in range.
@property(nonatomic) float fadeInScale;
@property(nonatomic, readonly) BOOL targetArmed;  // selectable target is ready to activate


- (instancetype) initWithMarkupName:(NSString*)markupName withRadius:(float)radius;
- (instancetype) initWithMarkupName:(NSString*)markupName withModelName:(NSString *)modelName;

- (void) setEnabled:(bool)enabled withFade:(BOOL)fade;

/**
 * Calculate the ground distance to camera on X/Z plane.
 */
- (float) groundDistanceToCamera;

- (SCNNode*) findNodeChildNamed:(NSString*)name;
@end
