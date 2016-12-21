/*
    This file is part of the Structure SDK.
    Copyright © 2016 Occipital, Inc. All rights reserved.
    http://structure.io
*/

#pragma once

#import <BridgeEngine/BridgeEngineAPI.h>

#import <Foundation/Foundation.h>

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

/// Called when the controller button is pressed
- (void)controllerButtonDown;

/// Called when the controller button is released
- (void)controllerButtonUp;

/// Called if the controller button was quickly pressed and released.
- (void)controllerDidPressButton;

/// Called if the controller button has been pressed for a long time.
- (void)controllerDidHoldButton;

@end

/** Bridge Engine Bluetooth Controller
 
 The interface that your application-specific class must implement to receive events from the bluetooth controller.
 
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

@end
