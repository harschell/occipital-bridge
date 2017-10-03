/*
    This file is part of the Structure SDK.
    Copyright © 2016 Occipital, Inc. All rights reserved.
    http://structure.io
*/

#pragma once

#import <BridgeEngine/BridgeEngineAPI.h>
#import <BridgeEngine/BEEngine.h>
#import <BridgeEngine/BEShader.h>
#import <SceneKit/SceneKit.h>
#import <Foundation/Foundation.h>

@class EAGLSharegroup;

@class BEMesh;

//------------------------------------------------------------------------------

typedef NSArray<NSString*> NSStringArray;

//------------------------------------------------------------------------------

/** Bridge Engine Mixed Reality Mode Delegate
 
 The interface that your application-specific class must implement in order to receive mixed reality callbacks.
 
 */
BE_API
@protocol BEMixedRealityModeDelegate <NSObject>

/** Called after the internal SceneKit world is set up. 
  This is a good place to add custom SceneKit objects to the scene.
  @param mappedAreaStatus indicates whether a previously scanned scene could be reloaded from the device successfully
*/
- (void) mixedRealitySetUpSceneKitWorlds:(BEMappedAreaStatus)mappedAreaStatus;

/// A markup node has been changed.
- (void) mixedRealityMarkupDidChange:(NSString*)markupChangedName;

/// The user has tapped "Done" on the editing panel.
- (void) mixedRealityMarkupEditingEnded;

/** Called before rendering each frame. This is good place to update your SceneKit nodes.
     This is called on the render thread, which is a background thread, not the main thread.
 **/
- (void) mixedRealityUpdateAtTime:(NSTimeInterval)time;

@optional

/// Notifies that the status of one of the sensors changed.
- (void) mixedRealitySensorsStatusChanged:(BESensorsStatus)sensorsStatus;

/** Called after the scene has been loaded.
 This is a good place to access the BEMesh for example.
 @param mappedAreaStatus indicates whether a previously scanned scene could be reloaded from the device successfully
 */
- (void) mixedRealityDidLoadScene:(BEMappedAreaStatus)mappedAreaStatus;

/** Called once per frame while markup placement is happening. This allows you
 to project your object into the world how it will be placed.
 @pararm markupName - The name of the markup node being placed.
 @param position - Position of projected node
 @param eulerAngles - Euler angles of projected node
 @returns BOOL - YES if you want BridgeEngine to project a node. NO if you want to handle the projection yourself.
 */
- (BOOL) mixedRealityBridgeShouldProjectMarkupNode:(NSString *)markupName position:(SCNVector3)position eulerAngles:(SCNVector3)eulerAngles;

@end

//------------------------------------------------------------------------------

/** The main resource for your mixed reality rendering and interaction needs
 */
BE_API
@interface BEMixedRealityMode : NSObject

/// @name Init

/** Initialize with required parameters.
 @param view The BEView that will be used for rendering. BEMixedRealityMode will add UI to this if necessary.
 @param engineOptions The valid keys are:
 
 - `kBECaptureReplayMode`: Whether a previous capture should be replayed. Valid values are listed in BECaptureReplayMode. Default is BECaptureReplayModeDisabled.
 - `kBECaptureReplayFile`: path to the OCC replay file, relative to the app documents folder. Default is "BridgeEngineScene/sceneReplay.occ", with a fallback on "BridgeEngineScene/capture.occ".
 - `kBEUsingWideVisionLens`:  Whether a Wide Vision Lens is attached. Default is NO.
 - `kBEUsingColorCameraOnly`: Whether the engine should try to connect to a Structure Sensor. Default is NO.
 - `kBEStereoRenderingEnabled`: If YES, we render two views, as if for a head-mounted display. If NO, we render a single (mono) view. Default is NO.
 - `kBERecordingOptionsEnabled`: If YES, a button to record a replay sequence will appear in mono mode. This option does nothing if kBEStereoRenderingEnabled or `kBECaptureReplayMode` are also enabled. **IMPORTANT**: this option will disable touch interactions, as the Record button will instantiate a tap recognizer.
 - `kBETrackerFallbackOnIMUEnabled`: If YES, will fallback to IMU-based rotational-only pose updates if the visual tracker is lost. Default is YES.
 - `kBEVisualInertialPoseFilterEnabled`: If YES, the tracker output will be smoother, but with potentially a slightly higher latency. Default is YES.
 - `kBEAutoExposeWhileRelocalizing`: If YES, the iOS color camera will auto-expose while trying to relocalize. Use this if lighting may have changed since the mapped area was captured. Default is NO.
 - `kBEExpectedFpsForTrackingEstimation` : This value should be set when running the engine in headless mode. It's used to improve tracking performance by setting an expected display speed for frame rate prediction. Set this number to the FPS of your display loop and the engine will attempt to keep tracking data and display data as close to sync as possible.
 Accepted values are 60 or 30. The default value is 60.
 NOTE: When not in headless mode this setting has no effect.

 @param markupNames An optional list of markup names, which will persist in the scene over multiple runs of the appl. In your app, you may call [BEMixedRealityMode startMarkupEditing] to load our internal UI for setting and saving markup.
 */
- (instancetype) initWithView:(BEView*)view
                engineOptions:(NSDictionary*)engineOptions
                  markupNames:(NSStringArray*)markupNames;

/** Initialize with required parameters.
 @param view The BEView that will be used for rendering. BEMixedRealityMode will add UI to this if necessary.
 @param engineOptions The valid keys are:
 
 - `kBECaptureReplayMode`: Whether a previous capture should be replayed. Valid values are listed in BECaptureReplayMode. Default is BECaptureReplayModeDisabled.
 - `kBEUsingWideVisionLens`:  Whether a Wide Vision Lens is attached. Default is NO.
 - `kBEUsingColorCameraOnly`: Whether the engine should try to connect to a Structure Sensor. Default is NO.
 - `kBEStereoRenderingEnabled`: If YES, we render two views, as if for a head-mounted display. If NO, we render a single (mono) view. Default is NO.
 - `kBERecordingOptionsEnabled`: If YES, a button to record a replay sequence will appear in mono mode. This option does nothing if kBEStereoRenderingEnabled or `kBECaptureReplayMode` are also enabled. **IMPORTANT**: this option will disable touch interactions, as the Record button will instantiate a tap recognizer.
 - `kBETrackerFallbackOnIMUEnabled`: If YES, will fallback to IMU-based rotational-only pose updates if the visual tracker is lost. Default is YES.
 - `kBEVisualInertialPoseFilterEnabled`: If YES, the tracker output will be smoother, but with potentially a slightly higher latency. Default is YES.
 - `kBEExpectedFpsForTrackingEstimation` : This value should be set when running the engine in headless mode. It's used to improve tracking performance by setting an expected display speed for frame rate prediction.  Set this number to the FPS of your display loop and the engine will attempt to keep tracking data and display data as close to sync as possible.
 Accepted values are 60 or 30. The default value is 60.
 NOTE: When not in headless mode this setting has no effect.
 
 @param markupNames An optional list of markup names, which will persist in the scene over multiple runs of the appl. In your app, you may call [BEMixedRealityMode startMarkupEditing] to load our internal UI for setting and saving markup.
 
 @param eaglSharegroup An EAGLShareGroup to be used by BridgeEngine OpenGL contexts. Can be nil.
 */
- (instancetype)initWithView:(BEView*)view
               engineOptions:(NSDictionary*)engineOptions
                 markupNames:(NSStringArray*)markupNames
              eaglSharegroup:(EAGLSharegroup*)eaglSharegroup;

/// @name Delegate

/// Set your application-specific class as this delegate to receive callbacks
@property (nonatomic, weak) id<BEMixedRealityModeDelegate> delegate;

/// @name Engine Control

/// Start the engine. This will display a main menu UI to ask the user if they want to start scanning or load the last scene.
- (void) start;

/** Start the engine, automatically loading the last mapped area and starting tracking.
 Note that the last scene is stored in the `BridgeEngineScene` subfolder of the App Documents folder.
 @see startWithSavedSceneAtPath
 */
- (void) startWithSavedScene;

/** Start the engine, automatically loading the last mapped area in the given subfolder and starting tracking.
 Note that the scenePath is relative to the app Documents folder.
 @see startWithSavedScene
 */
- (void) startWithSavedSceneAtPath:(NSString*)scenePath;

/** FIXME: document
 */
- (void) enterScanningMode;
- (void) startScanning;
- (void) stopScanningAndExportToPath:(NSString*)pathRelativeToDocumentsFolder;
- (void) stopScanningAndExport; // using the default @"BridgeEngineScene" path.
- (void) resetScanning;

/// Stop the engine: tracking, rendering and camera. Use it for a graceful shutdown.
- (void) stop;

/// @name Special SceneKit Nodes

/** SceneKit Node representing the coordinate system of the mapped area.
 You should add your augmented reality-like objects here for their location to be relative to the real world.
 @note This node and all its children are hidden when we are not tracking.
*/
@property (nonatomic, readonly) SCNNode* worldNodeWhenRelocalized;

/// SceneKit renderer accessor
@property (nonatomic, readonly) SCNRenderer* sceneKitRenderer;

/// Root SceneKit Scene accessor
@property (nonatomic, readonly) SCNScene* sceneKitScene;

/// SceneKit virtual camera accessor
@property (nonatomic, readonly) SCNCamera* sceneKitCamera;

/** SceneKit node that represents the position of the device in the world.
 In mono rendering, the node is aligned with the iOS camera, looking forward. 
 In stereo rendering, this node represents the position between the user's eyes, looking forward.
 */
@property (nonatomic, readonly) SCNNode* localDeviceNode;

/// @name Sensor and Tracking Status

@property (nonatomic, readonly) BESensorsStatus sensorsStatus;

/// Return the last tracker pose accuracy.
@property (readonly) BETrackerPoseAccuracy lastTrackerPoseAccuracy;

/// Return the last tracker hints.
@property (readonly) BETrackerHints lastTrackerHints;

/// @name Rendering style

/// Current rendering style.
- (BERenderStyle)renderStyle;

/// Change the current rendering style, with the speficied fade duration.
- (void) setRenderStyle:(BERenderStyle)toRenderStyle withDuration:(NSTimeInterval)duration;

/** Set a custom shader to be used for rendering the mapped area.
 @note This requires renderStyle to be set to BERenderStyleSceneKitAndCustomEnvironmentShader.
 @see BridgeEngineShaderDelegate
*/
- (void) setCustomRenderStyle:(id<BridgeEngineShaderDelegate>)customShader;

/** Set a custom fragment shader to do full-screen post processing.
 
 Here is the default:

     const char* fragmentShader = R"(
         precision mediump float;
         
         uniform sampler2D u_bridgeRender;
         varying vec2 v_texCoord;
         
         void main()
         {
            gl_FragColor = texture2D(u_bridgeRender, v_texCoord);
         }
     )";
 
 Some uniforms are automatically set:
 
 - `u_bridgeRender`: the current full-screen rendered texture (`sampler2D`)
 - `v_texCoord`: the texture coordinates (`vec2`)
 
 @see setCustomPostProcessingShaderFloatUniforms:
*/
-(void)setCustomPostProcessingShader:(NSString*) frag_shader;

/** Specific an additional dictionary of uniform float values to be passed to the custom postprocessing shader.
 The keys must exactly match the uniform names used in the shader.
*/
-(void)setCustomPostProcessingShaderFloatUniforms:(NSDictionary*) uniforms;

/// @name Collision Testing

/** Intersect a ray between the camera center and a given on-screen point with the mesh of the mapped area.
 @param point the screen-space point
 @param normal Normal at the intersection point of the scene mesh
 @note This is usually used for touch-based interaction.
 @note This does not collide with any SceneKit objects, only with the mesh of mapped area
 @warning For efficiency reasons the intersection point might be approximate
*/
- (SCNVector3)mesh3DFrom2DPoint:(CGPoint)point outputNormal:(SCNVector3*)normal;

/** Intersect a ray between the camera center and a given on-screen point with the SceneKit objects.
 @note This internally calls SCNSceneRenderer Protocol's hitTest:options, where options are SceneKit Hit-Testing Options Keys.
 @note This hit-test is performance-intensive, you should avoid calling it in an update loop.
*/
- (NSArray<SCNHitTestResult *> *)hitTestSceneKitFrom2DScreenPoint:(CGPoint)point options:(NSDictionary<NSString *, id> *)options;

/// @name Coordinate Transforms

/** Project a 3D point in SceneKit world coordinates to the 2D SceneKit pixel coordinate.
@note This internally calls `[SCNSceneRenderer projectPoint]`
*/
- (SCNVector3) projectPoint:(SCNVector3)sceneRootNodeWorldPoint;

/** Project a 3D point in SceneKit world coordinates to screen space.
This first calls `projectPoint` and then converts the SceneKit 2D coordinates to UIKit coordinate system.
These coordinates can be used for UIKit operations like moving a UIView to a specific location.
*/
- (CGPoint) projectPointToScreenCoordinates:(SCNVector3)sceneRootNodeWorldPoint;

/// @name Markups

/** Begin the markup editing phase.
 A Markup View will be loaded, allowing you to edit and save markup.
 Pressing Done dismisses the view.
*/
- (void) startMarkupEditing;

/** Get the markup node associated to a given name
 @throws NSInvalidArgumentException if `markupName` does not correspond to a name in the list given initially
 @return nil if the markupNode has a NaN position, indicating that has not been initialized and is not "ready to use".
*/
- (SCNNode*) markupNodeForName:(NSString*)markupName;

/// @name Utilities

/// This can be used to run a block on the rendering thread, e.g. to update a SceneKit node in sync with rendering.
- (void) runBlockInRenderThread:(void(^)(void)) block;

@end

//------------------------------------------------------------------------------

/**
    BEMixedRealityRenderData can be used to create your own stereo rendering system including:
        - Position, rotation, and projection of both eyes.
        - Information needed to color your mixed reality mesh using an undistorted OpenGL texture from the camera feed.
 
    This struct is designed to be used primarily in headless mode, although it can be used to retrieve camera texture
    data in non-headless mode as well.
 */
@interface BEMixedRealityRenderData : NSObject

@property (nonatomic,readonly) GLKMatrix4 leftEyePose;
@property (nonatomic,readonly) GLKMatrix4 leftEyeGLProjection;

@property (nonatomic,readonly) GLKMatrix4 rightEyePose;
@property (nonatomic,readonly) GLKMatrix4 rightEyeGLProjection;

@property (nonatomic,readonly) GLuint mixedRealityRgbaTexture;
@property (nonatomic,readonly) int mixedRealityRgbaTextureWidth;
@property (nonatomic,readonly) int mixedRealityRgbaTextureHeight;

@end

//------------------------------------------------------------------------------

struct BEColorFrameReference;

@interface BEMixedRealityPrediction : NSObject
@property (nonatomic,readonly) BOOL couldPredict;
@property (nonatomic,readonly) GLKMatrix4 predictedColorCameraPose;
@property (nonatomic,readonly) NSTimeInterval predictedPoseTimestamp;
@property (nonatomic,readonly) struct BEColorFrameReference* associatedColorFrame;
@property (nonatomic,readonly) GLKMatrix4 associatedColorFramePose;
@property (nonatomic,readonly) GLKMatrix4 colorFrameGLProjection;
@end

//------------------------------------------------------------------------------

@interface BEMixedRealityMode(LowLevel)

/** Lock the scene mesh (mapping updates will be blocked) and return its current content.
 @return the scene mesh.
*/
- (BEMesh*)lockAndGetSceneMesh;

/** Unlock the scene mesh.
 @note You cannot safely use the BEMesh returned by lockAndGetSceneMesh after this.
 */
- (void)unlockSceneMesh;

/** Return a coarse version of the scene mesh, ideal for physics. 
 This is only updated after an export or reload operation.
 */
- (BEMesh*)coarseMesh;

/** Return the best estimate of the color camera pose for a given a display link timestamp
 
 This is meant to be used in headless mode (when BEView==nil), e.g. from the Unity plugin.
 
 @param displayLinkStart host timestamp when displayLink was started. This information will be used to determine the best pose timestamp.
 @return pose estimated by the tracker with timestamp at which the camera pose was estimated.
 
 */
- (BEMixedRealityPrediction*)predictColorCameraPoseForDisplayLinkStart:(NSTimeInterval)displayLinkStart;

/** Uses the color camera pose estimates to return data for rendering.
    
    This is meant to be used in headless mode (when BEView==nil), e.g. from the Unity plugin.
 
    @param mrPrediction - The prediction to be used for this render data.  This should be created this frame by calling - (BEMixedRealityPrediction*)predictColorCameraPoseForDisplayLinkStart:(NSTimeInterval)displayLinkStart;
    
    @param requiresTexture - If we should return texture information with camera information. 
    @warn Only use if you need the texture! This will create a delay in predictive mode as we wait for the latest color frame from the camera.
 
    @return nil if mrPrediction.couldPredict == NO. Otherwise returns render data driven by the estimated pose.  This includes information for the left / right eyes and the texture of the real world mesh.
*/
- (BEMixedRealityRenderData *)renderDataForPrediction:(BEMixedRealityPrediction *)mrPrediction requiresTexture:(BOOL)requiresTexture;

/** Render the scene mesh in the current GL context.
 
 @param glStyle the rendering shader that will be used.
 @param modelView the modelView matrix used to render the mesh.
 @param projection the projection matrix used to render the mesh.
 @param associatedColorFrame the color frame returned by predictColorCameraPoseForDisplayLinkStart
 
 */
- (void)renderSceneMeshWithStyle:(BEOpenGLRenderStyle)glStyle
                       modelView:(GLKMatrix4)modelView
                      projection:(GLKMatrix4)projection
            associatedColorFrame:(struct BEColorFrameReference*)associatedColorFrame;

/** Render the scene mesh in the current GL context from the color camera viewpoint.
 
 Use this method when you want to render the scene from the exact viewpoint of the color camera.
 This is best for monocular modes where the color background can fill the screen to avoid gaps.
 
 @param glStyle the rendering shader that will be used.
 @param associatedColorFrame the color frame returned by predictColorCameraPoseForDisplayLinkStart
 */
- (void)renderSceneMeshFromColorCameraViewpointWithStyle:(BEOpenGLRenderStyle)glStyle
                                    associatedColorFrame:(struct BEColorFrameReference*)associatedColorFrame;


@end
