/*
    This file is part of the Structure SDK.
    Copyright © 2016 Occipital, Inc. All rights reserved.
    http://structure.io
*/

#pragma once

#import <BridgeEngine/BridgeEngineAPI.h>
#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

//------------------------------------------------------------------------------

/**
 * Bridge controller button bit values
 */
typedef NS_ENUM(unsigned, BEControllerButtons) {
    BEControllerButtonPrimary   = 1<<0, // Trigger pulled or CODAWheel clicker
    BEControllerButtonSecondary = 1<<1, // App button with (•••)
    BEControllerButtonHomePower = 1<<2, // Home/Power button with (o)
    BEControllerButtonTouchpad     = 1<<3, // Touch pad clicker pressed
    BEControllerButtonTouchContact = 1<<4, // Touch pad contact with finger
};

/**
 * Bridge controller touch event states
 */ 
typedef NS_ENUM(unsigned, BEControllerTouchStatus)  {
    BECTouchIdle = 0,
    BECTouchFirstContact = 1,
    BECTouchReleaseContact = 2,
    BECTouchMove = 3
};

/// Example offsetFromCamera for placing the controller around the user's body.
BE_API extern const GLKVector3 kBEControllerOffsetInsideHead; // = GLKVector3Make(0, 0, 0);
BE_API extern const GLKVector3 kBEControllerOffsetCenterWaist;// = GLKVector3Make(0, .30, .10); (DEFAULT)
BE_API extern const GLKVector3 kBEControllerOffsetRightHandedTallerWaist;// = GLKVector3Make(0.2, .55, .20);

//------------------------------------------------------------------------------

/** Bridge Engine Bluetooth Controller Delegate

 The interface that your application-specific class must implement to receive events from the bluetooth controller.

*/
BE_API
@protocol BEControllerDelegate <NSObject>

@optional

/// Called when the controller is paired and ready to send events.
- (void)controllerDidConnect;

/// Called when the controller got disconnected.
- (void)controllerDidDisconnect;

/**
 * Called when any button is pressed or released
 * @parameter buttons Current state of all buttons (1 - held down, 0 - released)
 * @parameter buttonsDown Buttons that have changed to down state (1 - click down, 0 - no change)
 * @parameter buttonsUp Buttons that have changed to released state (1 - released, 0 - no change)
 */
- (void)controllerButtons:(BEControllerButtons)buttons down:(BEControllerButtons)buttonsDown up:(BEControllerButtons)buttonsUp;

/**
 * Controller motion event:
 * @parameter orientation Controller orientation in world coordinate space
 */
- (void)controllerMotionTransform:(GLKMatrix4)transform;

/**
 * Controller touch events
 * @parameter position relative position across the touch pad
 * @parameter status Active tracking touch status
 */
- (void)controllerTouchPosition:(GLKVector2)position status:(BEControllerTouchStatus)status;

// --- Deprecated ---
/// Controller button is pressed
- (void)controllerButtonDown __deprecated;

/// Controller button is released
- (void)controllerButtonUp __deprecated;

/// Controller primary button was quickly pressed and released.
- (void)controllerDidPressButton __deprecated;

/// Controller primary button has been pressed for a long time.
- (void)controllerDidHoldButton __deprecated;

/// Core motion input, but deprecated in favor of controllerMotionEventEulerAngles:
- (void)controllerDidOutputCoreMotionRotation:(GLKVector3)rotation __deprecated;

/// Touchpad position, but deprecated in favor of controllerTouchEventPosition:status:
- (void)controllerDidOutputTouchpadPositionX:(float)x positionY:(float)y __deprecated;

@end

//------------------------------------------------------------------------------

/**
 * Bridge Engine Controller
 * The interface that your application-specific class must implement to receive events from Bridge compatible controllers.
 */
BE_API
@interface BEController : NSObject

/// Shared instance, BEController is a singleton.
+ (BEController*)sharedController;

// Preventing a classical init, use sharedController.
- (instancetype)init NS_UNAVAILABLE;

/// Delegate to receive the controller events.
@property (nonatomic, weak) id<BEControllerDelegate> delegate;

/** Whether the controller is currently connected.
 @note This property can be observed using the NSKeyValueObserver mechanism.
*/
@property (nonatomic, readonly) BOOL isConnected;

/**
 * Currently held down buttons
 */
@property (nonatomic, readonly) BEControllerButtons buttons;

/**
 * Current controller orientation in world coordinate space
 */
@property (nonatomic, readonly) GLKMatrix4 transform;

/**
 * Current controller orientation in world space, without the translation
 */
@property (nonatomic, readonly) GLKMatrix3 orientation;

/**
 * Current touch pad position.
 */
@property (nonatomic, readonly) GLKVector2 touchPosition;

/**
 * Current touch pad status.
 */
@property (nonatomic, readonly) BEControllerTouchStatus touchStatus;

// --- Inputs that affect the controller's transform ---

/**
 * Updated camera transform from BE's camera tracking
 */
@property (nonatomic) GLKMatrix4 cameraTransform;

/**
 * Relative offset from camera's position, oriented along the camera's forward yaw on a level plane
 * X - Distance to the right of camera's forward-level direction.
 * Y - Vertical drop from camera height
 * Z - Forward distance away from camera
 * Default: (0, .30, .10) // Centered, down 30cm, and forward 10cm
 */
@property (nonatomic) GLKVector3 offsetFromCamera;

/**
 * Center the controller's relative Yaw tracking to cameraTransform's
 */
- (void) resetYawToCameraTransform;

@end
