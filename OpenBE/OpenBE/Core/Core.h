/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#pragma once

// Global settings.
// #define ENABLE_ROBOTROOM - Moved to OpenBE Preprocessor Macros.

#define USE_3DSPATIALIZED_AUDIO 1

// Rendering And Ray-casting bits.
#define RAYCAST_IGNORE_BIT (1<<16)

// Move the reticle vertically, pushing it down a bit now to point towards robot
// +y is down, -y is up from center. z offset is 1.0.
#define RETICLE_VERTICAL_OFFSET 0.1

// From BE private
#define CATEGORY_BIT_MASK_CASTS_SHADOWS_ONTO_ENVIRONMENT 2
#define CATEGORY_BIT_MASK_CASTS_SHADOWS_ONTO_AR 4
#define CATEGORY_BIT_MASK_LIGHTING (CATEGORY_BIT_MASK_CASTS_SHADOWS_ONTO_ENVIRONMENT|CATEGORY_BIT_MASK_CASTS_SHADOWS_ONTO_AR)

/**
 * Transaprency and world rendering is put at specific render order levels,
 * relative to the background rendering
 *
 * Background (Real World, with Video passthru and shadow) is 100,000
 *  See BEEnvironmentScanRenderingOrder and BEEnvironmentScanShadowRenderingOrder
 *
 * VRWorld for portal is Environment + 10,000
 * Transparency for Bridge menus is Environment + 20,000
 */
#define VR_WORLD_RENDERING_ORDER (BEEnvironmentScanShadowRenderingOrder + 10000)
// transparent objects must be rendered last
#define TRANSPARENCY_RENDERING_ORDER (BEEnvironmentScanShadowRenderingOrder + 20000)

#define PORTAL_STENCIL_VALUE 4 // 1 is used internally by the engine currently

#import "Camera.h"
#import "Scene.h"
#import "ComponentProtocol.h"
#import "EventComponentProtocol.h"
#import "Component.h"
#import "GeometryComponent.h"
#import "SceneManager.h"
#import "EventManager.h"
