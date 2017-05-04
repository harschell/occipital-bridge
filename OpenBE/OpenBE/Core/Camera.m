/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */
 
#import "Core.h"
#import "Camera.h"
#import "../Utils/Math.h"
#import "AudioEngine.h"

@import GLKit;

@interface Camera()
@property (atomic) GLKVector3 tmpForward;
@property (atomic) GLKVector3 tmpUp;
@property (atomic) GLKVector3 previousPosition;
@property (atomic) GLKVector3 reticleOffset;

@end

@implementation Camera

- (id) init {
    self = [super init];
    
    self.tmpForward = GLKVector3Make(0,0,1);
    self.reticleOffset = GLKVector3Make(0,RETICLE_VERTICAL_OFFSET,0);

    self.tmpUp = GLKVector3Make(0,1,0);
    self.position = GLKVector3Make(0, 0, 0);
    self.speed = 0.f;
    
    return self;
}

+ (Camera *) main {
    static Camera * mainCamera;
    if( mainCamera == NULL) {
        mainCamera = [[Camera alloc] init];
    }
    
    return mainCamera;
}

- (void) updateWithDeltaTime:(NSTimeInterval)seconds andNode:(SCNNode *) node andCamera:(SCNCamera *)camera {
    self.camera = camera;
    self.node = node;
    
    GLKQuaternion orientation = GLKQuaternionMake( node.orientation.x,
                                                  node.orientation.y,
                                                  node.orientation.z,
                                                  node.orientation.w );
    
    self.previousPosition = self.position;
    
    self.forward = GLKQuaternionRotateVector3( orientation, self.tmpForward );
    
    self.reticleForward = GLKQuaternionRotateVector3( orientation,
                             GLKVector3Add(self.tmpForward, self.reticleOffset));
    
    self.reticleForward = GLKVector3Normalize(self.reticleForward);
    
    self.up = GLKQuaternionRotateVector3( orientation, self.tmpUp );
    self.position = SCNVector3ToGLKVector3( node.position );
    
    // Update positional and orientation of the AudioEngine.
    [AudioEngine.main updateListenerFromCameraNode:node];
    
    float newSpeed = GLKVector3Distance(self.previousPosition, self.position) / seconds;
    if( !isnan(newSpeed)) {
        self.speed = lerpf(self.speed, newSpeed, .2f);
    }
}

@end
