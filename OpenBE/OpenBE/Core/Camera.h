/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */
 
#import <GameplayKit/GameplayKit.h>
#import <SceneKit/SceneKit.h>
#import <JavascriptCore/JavascriptCore.h>

@protocol CameraJSExports <JSExport>
- (SCNNode*)node;
- (SCNCamera*)camera;

// GLKVector3 are incompatable with JSContext, require SCNVector3 instead.
//- (GLKVector3)forward;
//- (GLKVector3)up;
//- (GLKVector3)position;

- (float)speed;
@end

@interface Camera : NSObject <CameraJSExports>

@property (weak) SCNNode * node;
@property (weak) SCNCamera * camera;

@property (atomic) GLKVector3 forward;
@property (atomic) GLKVector3 reticleForward;
@property (atomic) GLKVector3 up;
@property (atomic) GLKVector3 position;

@property (atomic) float speed;

+ (Camera *) main;

- (void) updateWithDeltaTime:(NSTimeInterval)seconds andNode:(SCNNode *) node andCamera:(SCNCamera *)camera;

@end
