/*
    This file is part of the Structure SDK.
    Copyright © 2016 Occipital, Inc. All rights reserved.
    http://structure.io
*/

#pragma once

#import "BridgeEngineAPI.h"
#import "BEEngine.h"
#import <SceneKit/SceneKit.h>
#import <Foundation/Foundation.h>

//------------------------------------------------------------------------------

typedef NSArray<NSString*> NSStringArray;

//------------------------------------------------------------------------------

/** Bridge Engine Mixed Reality Mode Delegate
 
 The interface that your application-specific class must implement in order to receive mixed reality callbacks.
 
 */
BE_API
@protocol BEMixedRealityModeDelegate

// called after the internal sceneKit world is set up, and you may add any custom sceneKit objects.
//  stageLoadingStatus indicates whether the local scene loads from device successfully or unsuccessfully
- (void) setUpSceneKitWorlds:(BEStageLoadingStatus)stageLoadingStatus;

// called when the tracking state changed.
- (void) trackingStateChanged:(BETrackingState)trackerState;

// a markup node has been changed. You may write code that handles it for this named markup.
- (void) markupDidChange:(NSString*)markupChangedName;
// the user has tapped "Done" on the editing panel.
- (void) markupEditingEnded;

// called before render each frame. It is safe to move SceneKit objects here.
- (void) updateAtTime:(NSTimeInterval)time;

@end

//------------------------------------------------------------------------------

/** Bridge Engine Mixed Reality Mode - the one-stop shop for your mixed reality rendering and interaction needs
 */
BE_API
@interface BEMixedRealityMode : NSObject

/** Initialize with required parameters.
 @param view The BEView that will be used for rendering. BEMixedRealityMode will add UI to this if necessary.
 @param engineOptions The valid keys are:
 
 - `kBECaptureReplayEnabled`: If YES, will start a capture replay. If NO, will expect a Structure Sensor to be connected to do it live.
 - `kBEUsingWideVisionLens`:  Whether a Wide Vision Lens is attached.
 - `kBEStereoRenderingEnabled`: If YES, we render two views, as if for a head-mounted display. If NO, we render a single (mono) view.
 
 @param markupNames An optional list of markup names, which will persist in the scene over multiple runs of the appl. In your app, you may call [BEMixedRealityMode startMarkupEditing] to load our internal UI for setting and saving markup.
 */
- (instancetype)
            initWithView:(BEView*)view
           engineOptions:(NSDictionary*)engineOptions
             markupNames:(NSStringArray*)markupNames;

// starts the engine running. You should have ensured that the scene is loaded by this point, or this will produce undefined behaviour.
- (void) start;

//There are two different SceneKit nodes you may attach objects to:
// worldNodeWhenRelocalized represents the alignment to the real world. You will likely add most of your Augmented Reality-like objects here. This and all children are hidden when we are not tracking
// worldNodeWhenNotTracking is only shown when we are not tracking. We currently add different status billboards here. You may do so as well if you wish.
@property (nonatomic, readonly) SCNNode* worldNodeWhenRelocalized;
@property (nonatomic, readonly) SCNNode* worldNodeWhenNotTracking;

// localDeviceNode is an SCNNode that represents the transform of the device running the bridge engine
@property (nonatomic, readonly) SCNNode* localDeviceNode;

// set your application-specific class as this delegate to receive callbacks
@property (nonatomic, weak) id<BEMixedRealityModeDelegate> delegate;

// query the current tracking state
@property (nonatomic, readonly) BETrackingState trackingState;


// query the current render style
- (BERenderStyle) getRenderStyle;
// change from the current render style to a new one, with a smooth fade. The fade looks pretty great, to be honest.
- (void) setRenderStyle:(BERenderStyle)toRenderStyle withDuration:(NSTimeInterval)duration;

// This collides a ray from an on-screen point to a position on the scene mesh, including a normal.
// This is commonly used for touch-based interaction.
// NOTE: this does not collide with any SceneKit objects.
// WARNING: Currently, this is roughly implemented and is not accurate.
- (SCNVector3) mesh3DFrom2DPoint:(CGPoint)point outputNormal:(SCNVector3*)normal;

// This internally calls SCNSceneRenderer Protocol's hitTest:options, where options are SceneKit Hit-Testing Options Keys.
// NOTE: This hit test call is performance-expensive, and you should avoid calling it in an update loop.
- (NSArray<SCNHitTestResult *> *)hitTestSceneKitFrom2DScreenPoint:(CGPoint)point options:(NSDictionary<NSString *, id> *)options;


/** fetch the markup node for a given name
 throws NSInvalidArgumentException if markupName does not correspond to a name in the list given initially
 returns nil if the markupNode has a NaN position, indicating that has not been initialized and is not "ready to use".
 */
- (SCNNode*) markupNodeForName:(NSString*)markupName;

// begin the markup editing phase. A Markup View will be loaded, allowing you to edit and save markup. Pressing Done dismisses the view.
- (void) startMarkupEditing;


@end
