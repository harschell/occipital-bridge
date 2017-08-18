//
//  Utils.m
//  MixedReality
//
//  Created by John Austin on 8/1/17.
//  Copyright © 2017 Occipital. All rights reserved.
//

#import "Utils.h"

@implementation Utils
+ (GLKQuaternion)SCNQuaternionMakeFromRotation:(GLKVector3)from to:(GLKVector3)dest {
    GLKVector3 rotationAxis = GLKVector3CrossProduct(from, dest);
    float rotationAmount = (float) acos(GLKVector3DotProduct(from, dest));
    return GLKQuaternionMakeWithAngleAndVector3Axis(rotationAmount, rotationAxis);
}

// see header for docs
+ (GLKQuaternion)SCNQuaternionLookRotation:(GLKVector3)forward up:(GLKVector3)up {
    forward = GLKVector3Normalize(forward);
    GLKVector3 right = GLKVector3Normalize(GLKVector3CrossProduct(up, forward));
    up = GLKVector3CrossProduct(forward, right);

    float m00 = right.x;
    float m01 = right.y;
    float m02 = right.z;
    float m10 = up.x;
    float m11 = up.y;
    float m12 = up.z;
    float m20 = forward.x;
    float m21 = forward.y;
    float m22 = forward.z;

    float num8 = (m00 + m11) + m22;
    GLKQuaternion quaternion = GLKQuaternionMake(0, 0, 0, 0);
    if (num8 > 0.0f) {
        float num = (float) sqrt(num8 + 1.0f);
        quaternion.w = num * 0.5f;
        num = 0.5f / num;
        quaternion.x = (m12 - m21) * num;
        quaternion.y = (m20 - m02) * num;
        quaternion.z = (m01 - m10) * num;
        return quaternion;
    }
    if ((m00 >= m11) && (m00 >= m22)) {
        float num7 = (float) sqrt(((1.0f + m00) - m11) - m22);
        float num4 = 0.5f / num7;
        quaternion.x = 0.5f * num7;
        quaternion.y = (m01 + m10) * num4;
        quaternion.z = (m02 + m20) * num4;
        quaternion.w = (m12 - m21) * num4;
        return quaternion;
    }
    if (m11 > m22) {
        float num6 = (float) sqrt(((1.0f + m11) - m00) - m22);
        float num3 = 0.5f / num6;
        quaternion.x = (m10 + m01) * num3;
        quaternion.y = 0.5f * num6;
        quaternion.z = (m21 + m12) * num3;
        quaternion.w = (m20 - m02) * num3;
        return quaternion;
    }
    float num5 = (float) sqrt(((1.0f + m22) - m00) - m11);
    float num2 = 0.5f / num5;
    quaternion.x = (m20 + m02) * num2;
    quaternion.y = (m21 + m12) * num2;
    quaternion.z = 0.5f * num5;
    quaternion.w = (m01 - m10) * num2;
    return quaternion;
}

@end
