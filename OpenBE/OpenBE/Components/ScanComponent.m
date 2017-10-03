/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import "ScanComponent.h"
@import GLKit;

#import "../Core/AudioEngine.h"

@interface ScanComponent()
@property (atomic) bool scanActive;
@property (atomic) float scanTime;

@property(nonatomic, strong) AudioNode *scanSound;
@end


@implementation ScanComponent


- (void) start {
    self.duration = 2.f;
    self.scanActive = false;
    self.scanTime = 0.f;
    self.scanRadius = 2.f;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.scanSound = [[AudioEngine main] loadAudioNamed:@"Robot_ScanBeam.caf"];
    });
}

- (void) updateWithDeltaTime:(NSTimeInterval)seconds {
    if( self.scanActive ) {
        self.scanTime += seconds;

        if( self.scanTime >= _duration ) {
            [self startScan:false atPosition:GLKVector3Make(0,0,0) duration:_duration radius:_scanRadius];
            return;
        }
        
        if( self.scanEnvironmentShader ) {
            _scanSound.position = SCNVector3FromGLKVector3(_scanOrigin);
            self.scanEnvironmentShader.scanOrigin = self.scanOrigin;
            self.scanEnvironmentShader.scanRadius = self.scanRadius;
            self.scanEnvironmentShader.scanTime = self.scanTime;
            self.scanEnvironmentShader.duration = self.duration;
        }
    }

}

- (void) startScan:(bool)active atPosition:(GLKVector3)position duration:(float)duration radius:(float)radius {
    self.duration = duration;
    self.scanActive = active;
    self.scanTime = 0.f;
    self.scanOrigin = position;
    self.scanRadius = radius;
    
    if( active ) {
        _scanSound.position = SCNVector3FromGLKVector3(_scanOrigin);
        [_scanSound play];
    }

    if( self.scanEnvironmentShader ) {
        self.scanEnvironmentShader.scanOrigin = self.scanOrigin;
        self.scanEnvironmentShader.scanRadius = self.scanRadius;
        
        [self.scanEnvironmentShader setActive:self.scanActive];
    }
}

- (void) setEnabled:(bool)enabled {
    if(!enabled) {
        [self startScan:false atPosition:GLKVector3Make(0, 0, 0) duration:2.f radius:self.scanRadius];
    }
    
    [super setEnabled:enabled];
}

@end
