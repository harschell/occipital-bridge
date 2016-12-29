/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */
 
//
//  Description:
//
//  All GeometryNode objects must be connected to the world with registerNodeToEntity,
//  or gaze tracking won't work for it.
//
//  And activation of the GeometryNode has to be done by registering it with:
//   [[[SceneManager main] createEntity] addComponent:geometryComponent]
//

#import "Component.h"
#import <JavascriptCore/JavascriptCore.h>

@protocol GeometryComponentJSExports <JSExport>
@property (strong) SCNNode * node;
@end

@interface GeometryComponent : Component <ComponentProtocol, GeometryComponentJSExports>

@property (strong) SCNNode * node;

- (id) initWithNode:(SCNNode *) node;

- (void) start;
- (void) setEnabled:(bool)enabled;

- (void) registerNodeToEntity:(SCNNode *) node;
- (SCNNode *) createSceneNode;
- (SCNNode *) createSceneNodeForGaze;

@end
