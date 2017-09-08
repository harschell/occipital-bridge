//
// Created by John Austin on 7/17/17.
// Copyright (c) 2017 Occipital. All rights reserved.
//

#import "OpenWindowComponent.h"

@implementation OpenWindowComponent

- (void) start {
    [super start];




}

- (bool)touchBeganButton:(uint8_t)button forward:(GLKVector3)touchForward hit:(SCNHitTestResult *)hit {
    return true;
}

- (bool)touchMovedButton:(uint8_t)button forward:(GLKVector3)touchForward hit:(SCNHitTestResult *)hit {
    return true;
}

- (bool)touchEndedButton:(uint8_t)button forward:(GLKVector3)touchForward hit:(SCNHitTestResult *)hit {
    // TODO: Disallow opening a new window while we are inside a portal.

    if (hit) {
        ColorOverlayComponent *colorOverlay = [[ColorOverlayComponent alloc] init];
        [[[SceneManager main] createEntity] addComponent:self.outsideComponent];

        WindowComponent *newPortal = [[WindowComponent alloc] init];
        newPortal.overlayComponent = colorOverlay;



        GKEntity *portalEntity = [[SceneManager main] createEntity];
        [portalEntity addComponent:newPortal];
    }
    return false;
}
- (bool)touchCancelledButton:(uint8_t)button forward:(GLKVector3)touchForward hit:(SCNHitTestResult *)hit {
    return 0;
}

@end