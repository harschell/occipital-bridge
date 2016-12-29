/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import "BehaviourComponent.h"

@interface LookAtNodeBehaviourComponent : BehaviourComponent
@property(nonatomic, weak) SCNNode *targetNode;

- (void) runBehaviourFor:(float)seconds lookAtNode:(SCNNode *) targetNode callback:(void (^)(void))callbackBlock;

@end
