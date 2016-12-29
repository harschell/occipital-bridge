/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import "BehaviourComponent.h"

@interface ScanBehaviourComponent : BehaviourComponent

- (void) runBehaviourFor:(float)seconds targetPosition:(GLKVector3) targetPosition radius:(float)radius callback:(void (^)(void))callbackBlock;

@end
