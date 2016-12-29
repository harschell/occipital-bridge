/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#pragma once

// Global settings.

// Rendering And Ray-casting bits.
#define RAYCAST_IGNORE_BIT (1<<16)

// Move the reticle vertically, pushing it down a bit now to point towards robot
// +y is down, -y is up from center. z offset is 1.0.
#define RETICLE_VERTICAL_OFFSET 0.1

// From BridgeEngine
#define CATEGORY_BIT_MASK_CASTS_SHADOWS_ONTO_ENVIRONMENT 2
#define CATEGORY_BIT_MASK_CASTS_SHADOWS_ONTO_AR 4
#define CATEGORY_BIT_MASK_LIGHTING (CATEGORY_BIT_MASK_CASTS_SHADOWS_ONTO_ENVIRONMENT|CATEGORY_BIT_MASK_CASTS_SHADOWS_ONTO_AR)

#define BACKGROUND_RENDERING_ORDER 100000

#define VR_WORLD_RENDERING_ORDER 110000
// transparent objects must be rendered last
#define TRANSPARENCY_RENDERING_ORDER 120000

#import "Camera.h"
#import "Scene.h"
#import "ComponentProtocol.h"
#import "EventComponentProtocol.h"
#import "Component.h"
#import "GeometryComponent.h"
#import "SceneManager.h"
#import "EventManager.h"
