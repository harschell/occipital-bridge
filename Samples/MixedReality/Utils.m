//
//  Utils.m
//  MixedReality
//
//  Created by John Austin on 8/1/17.
//  Copyright © 2017 Occipital. All rights reserved.
//

#import "Utils.h"
#include "math.h"

@implementation Utils
+ (GLKQuaternion)SCNQuaternionMakeFromRotation:(GLKVector3)from to:(GLKVector3)dest {
    GLKVector3 rotationAxis = GLKVector3CrossProduct(from, dest);
    float rotationAmount = (float) acos(GLKVector3DotProduct(from, dest));
    return GLKQuaternionMakeWithAngleAndVector3Axis(rotationAmount, rotationAxis);
}

// see header for docs
// Based on decompiled unity sources.
+ (GLKQuaternion)SCNQuaternionLookRotation:(GLKVector3)forward up:(GLKVector3)up {
    forward = GLKVector3Normalize(forward);
    GLKVector3 right = GLKVector3Normalize(GLKVector3CrossProduct(up, forward));
    up = GLKVector3CrossProduct(forward, right);

    float num8 = right.x + up.y + forward.z;
    GLKQuaternion quaternion = GLKQuaternionMake(0, 0, 0, 0);
    if (num8 > 0.0f) {
        float num = (float) sqrt(num8 + 1.0f);
        quaternion.w = num * 0.5f;
        num = 0.5f / num;
        quaternion.x = (up.z - forward.y) * num;
        quaternion.y = (forward.x - right.z) * num;
        quaternion.z = (right.y - up.x) * num;
        return quaternion;
    }
    if ((right.x >= up.y) && (right.x >= forward.z)) {
        float num7 = (float) sqrt(((1.0f + right.x) - up.y) - forward.z);
        float num4 = 0.5f / num7;
        quaternion.x = 0.5f * num7;
        quaternion.y = (right.y + up.x) * num4;
        quaternion.z = (right.z + forward.x) * num4;
        quaternion.w = (up.z - forward.y) * num4;
        return quaternion;
    }
    if (up.y > forward.z) {
        float num6 = (float) sqrt(((1.0f + up.y) - right.x) - forward.z);
        float num3 = 0.5f / num6;
        quaternion.x = (up.x + right.y) * num3;
        quaternion.y = 0.5f * num6;
        quaternion.z = (forward.y + up.z) * num3;
        quaternion.w = (forward.x - right.z) * num3;
        return quaternion;
    }
    float num5 = (float) sqrt(((1.0f + forward.z) - right.x) - up.y);
    float num2 = 0.5f / num5;
    quaternion.x = (forward.x + right.z) * num2;
    quaternion.y = (forward.y + up.z) * num2;
    quaternion.z = 0.5f * num5;
    quaternion.w = (right.y - up.x) * num2;
    return quaternion;
}

@end
