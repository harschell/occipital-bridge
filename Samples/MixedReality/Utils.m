//
//  Utils.m
//  MixedReality
//
//  Created by John Austin on 8/1/17.
//  Copyright © 2017 Occipital. All rights reserved.
//

#import "Utils.h"

@implementation Utils
+ (GLKQuaternion) SCNQuaternionMakeFromRotation:(GLKVector3)from to:(GLKVector3)dest {
    GLKVector3 rotationAxis = GLKVector3CrossProduct(from, dest);
    float rotationAmount = (float) acos(GLKVector3DotProduct(from, dest));
    return GLKQuaternionMakeWithAngleAndVector3Axis(rotationAmount, rotationAxis);
}

@end
