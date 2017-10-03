/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import "../Core/Core.h"

/**
 Used to quickly create a projection style node from geometry
 */
@interface ProjectedGeometryComponent : GeometryComponent

/** Creates and adds a node with the geometry and the Projection
    Shader to the stage. 
    
    NOTE: The node will be hidden by default.
 */
- (instancetype)initWithChildNode:(SCNNode *)node;

@end
