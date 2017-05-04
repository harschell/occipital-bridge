/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import "ButtonContainerComponent.h"
#import "../Utils/ComponentUtils.h"
#import "ButtonComponent.h"

#define BUTTON_Z_OFFSET 0.5f

@interface ButtonContainerComponent()
@end

@implementation ButtonContainerComponent

- (void) start {
    [super start];
    
    self.node = [self createSceneNodeForGaze];
    
    float numButtons = (float)[self.buttonComponents count];
    float offset = -numButtons * 1.1f / 2.f + .05f;
    
    for( ButtonComponent * component in self.buttonComponents ) {
        component.node.position = SCNVector3Make( offset+.5f, 0, BUTTON_Z_OFFSET);
        offset += 1.1f;
        
        [self.node addChildNode:component.node];
    }
}

- (void) updateWithDeltaTime:(NSTimeInterval)seconds {
    float numButtons = (float)[self activeButtonsCount];
    
    float offset = -numButtons * 1.1f / 2.f + .05f;
    
    for( ButtonComponent * component in self.buttonComponents ) {
        if( [component isEnabled] ) {
            float x = offset+.5f;
            if( component.node.position.x != x ) {
                component.node.position = SCNVector3Make( x, 0, BUTTON_Z_OFFSET);
            }
            offset += 1.1f;
        }
    }
}

- (int) activeButtonsCount {
    int numButtons = 0.f;
    
    for( ButtonComponent * component in self.buttonComponents ) {
        if( [component isEnabled] )  numButtons ++;
    }
    return numButtons;
}


@end
