/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */
 
//  Apply a globally rendered overlay of a specific color to the screen.
//  Good for fade to Black, fade to White, or strobe effect for
//  things like taking a hit.

#import <GameplayKit/GameplayKit.h>
#import <SceneKit/SceneKit.h>

#import "../Core/Core.h"

@interface ColorOverlayComponent  : GeometryComponent <ComponentProtocol>

/**
 * Set the color with alpha
 * When alpha is zero, no overlay is rendered.
 */
@property (nonatomic, copy) UIColor *color;

@end
