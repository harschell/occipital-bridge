/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import <BridgeEngine/BridgeEngine.h>
#import "Core.h"

@interface EventManager : NSObject

@property (weak) BEMixedRealityMode* mixedRealityMode;

@property (atomic) bool useReticleAsTouchLocation;

+ (EventManager *) main;

- (void) start;
- (void) pauseGlobalEventComponents;
- (void) resumeGlobalEventComponents;

- (void) updateWithDeltaTime:(NSTimeInterval)seconds;
- (void) addGlobalEventComponent:(GKComponent *)component;

- (void) controllerButtonDown;
- (void) controllerButtonUp;

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
@end
