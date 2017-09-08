/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

//  Description:
//  Portal is composed of a bunch of nodes that work to drive the OpenGL
//  state changes and handle the switched rendering order needed to make the
//  illusion of a portal into the VR world.
//
//  The visualization of real-world obstacles must be maintained when
//  walking into the VR world.  So this last visualization is rendered
//  at the end or the final portal rendering, and before transparent things
//  are drawn.  
// 
//  Node Hierarchy:
//  node - root node of the portal scene, used to position and orient the portal into the AR world.
//    portalBaseTransformNode - the base node for arranging the portal rendering stack
//      portalNode (hidden) - Base portal geometry, passage through this node is measured and triggers the switch between AR and VR worlds
//        occlude - The occlude writes to the stencil node, before rendering the VR world
//        depth - The secondary pass of writing and clearing the depth buffer after the VR world is rendered.
//    portalFrameNode - The surrounding outer portal frame geometry.
//
//  WorldRootNode - [Scene main].rootNode - custom render nodes are added here
//    prePortal - Prepare the stencil buffer for writing, and disable writing to the color and depth buffers.
//    postPortal - Prepare for rendering the VR world, Enable color and depth, mask inside or around stencil, depending on AR/VR render order.
//    postVRScene - Prepare to write the portal depth, disable stencil and color writes, but write depth.
//    portalDone - Post portal depth node, enable the regular color writes again.
//
//  Visualization of real-world geometry has its render prioritized mid or last
//  based on whether we're inside AR or VR.
//    WorldViz if in AR: render absolutely last
//    worldViz if in VR: render just after VR and portalDone is run

#import "ColorOverlayComponent.h"
#import <JavascriptCore/JavascriptCore.h>

@class VRWorldComponent;
@class OutsideWorldComponent;

@protocol WindowComponentJS <JSExport>
// @property(nonatomic, strong) SCNNode *node; (protect the node)
@property(nonatomic, readonly) BOOL open;

/**
 * Enabling emergencyExitVR = YES, plays a transition sequence that escapes from VR.
 */
@property(nonatomic) BOOL emergencyExitVR;

- (void) setEnabled:(bool)enabled;

- (float) openDuration;
- (float) closeDuration;

//- (bool) openPortalOnFloorPosition:(SCNVector3)position facingTarget:(SCNVector3)target toVRWorld:(OutsideWorldComponent*)vrWorld;
- (bool) openPortalOnWallPosition:(SCNVector3)position wallNormal:(GLKVector3)normal toVRWorld:(OutsideWorldComponent*)vrWorld;
- (void) closePortal;

@end


/**
 * Manage a portal rendering interface, for rendering a portal represented by `node`.
 * A couple of nodes `occlusion` and `depth` are cloned from the `node`,
 * and attached to the main world node.
 *
 * These nodes require manual updates to their transform if the portal node's transform changes.
 */
@interface WindowComponent : Component  <EventComponentProtocol, SCNNodeRendererDelegate, WindowComponentJS, SCNProgramDelegate>
@property(nonatomic, strong) SCNNode *node;
@property(nonatomic, readonly) bool open;

// Overlay is used for casting a white overlay, when emergencyExit is animating.
@property(nonatomic, weak) ColorOverlayComponent *overlayComponent;

- (void) setEnabled:(bool)enabled;


/**
 * NOTE: Won't open the portal if we're not isFullyClosed.
 * Open a circular portal on the wall.
 * Use the hit location (position) against a wall, rotate and offset the opening to lay against the wall.
 */
- (bool)openPortalOnWallPosition:(SCNVector3)position wallNormal:(GLKVector3)normal toVRWorld:(OutsideWorldComponent*)vrWorld;

/**
 * Begin closing the portal.
 */
- (void) closePortal;

/**
 * Check if the portal is fully closed and no longer animating.
 */
- (bool) isFullyClosed;

@end

static const long saveStateRenderOrder = BEEnvironmentScanShadowRenderingOrder - 18;
static const long prePortalRenderOrder = BEEnvironmentScanShadowRenderingOrder - 17;
static const long portalOccludeRenderOrder = BEEnvironmentScanShadowRenderingOrder - 16;
static const long postPortalRenderOrder = BEEnvironmentScanShadowRenderingOrder - 15;
static const long preEnvironmentRenderOrder = BEEnvironmentScanShadowRenderingOrder - 1;
static const long postEnvironmentRenderOrder = BEEnvironmentScanShadowRenderingOrder + 10;
