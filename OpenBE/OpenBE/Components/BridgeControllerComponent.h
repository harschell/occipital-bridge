/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2017 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import <Foundation/Foundation.h>
#import <SceneKit/SceneKit.h>
#import "OpenBE/Core/EventComponentProtocol.h"
#import "OpenBE/Core/CoreMotionComponentProtocol.h"
#import "OpenBE/Core/ComponentProtocol.h"
#import "OpenBE/Core/GeometryComponent.h"

@interface BridgeControllerComponent : GeometryComponent
<
    ComponentProtocol,
    EventComponentProtocol,
    CoreMotionComponentProtocol
>

- (id) initWithBlock:(void (^)(void))callbackBlock;
- (void) setDepthTesting:(BOOL)doDepthTest;

- (bool) handleMotionTransform:(GLKMatrix4)transform; // CoreMotionComponentProtocol

- (void) handleControllerTriggerDown:(BOOL) down;
- (void) handleTouchpadPositionX:(float)x positionY:(float)y;

- (void) start;
- (void) setEnabled:(bool)enabled;
- (bool) isEnabled;
- (bool) touchBeganButton:(uint8_t)button forward:(GLKVector3)touchForward hit:(SCNHitTestResult *) hit;
- (bool) touchMovedButton:(uint8_t)button forward:(GLKVector3)touchForward hit:(SCNHitTestResult *) hit;
- (bool) touchEndedButton:(uint8_t)button forward:(GLKVector3)touchForward hit:(SCNHitTestResult *) hit;
- (bool) touchCancelledButton:(uint8_t)button forward:(GLKVector3)touchForward hit:(SCNHitTestResult *) hit;
@end
