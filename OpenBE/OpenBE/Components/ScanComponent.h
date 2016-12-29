/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */
 
#import "../Core/EventComponentProtocol.h"
#import "../Core/ComponentProtocol.h"
#import "../Core/Component.h"

#import "../Shaders/ScanEnvironmentShader.h"


@interface ScanComponent : Component <ComponentProtocol>

@property (weak) SCNNode * environmentNode;
@property (strong) ScanEnvironmentShader * scanEnvironmentShader;
@property (atomic) GLKVector3 scanOrigin;
@property (atomic) float scanRadius;
@property (atomic) float duration;

- (void) start;

- (void) startScan:(bool)active atPosition:(GLKVector3)position duration:(float)duration radius:(float)radius;

@end
