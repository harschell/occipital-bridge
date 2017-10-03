/*
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import <Foundation/Foundation.h>
#import <mach/mach_time.h>

#import "BEUnityBaseInterop.h"

#pragma mark - Interop Utility Functions

beVector2 GLKVector2ToVector2(const GLKVector2& vec)
{
    return beVector2 {vec.v[0], vec.v[1]};
}

beVector3 GLKMatrix4ToPositionVector3(const GLKMatrix4& matrix)
{
    return beVector3 {matrix.m[12], matrix.m[13], matrix.m[14]};
}

beVector3 GLKMatrix4ToScaleVector3(const GLKMatrix4& m)
{
    return beVector3 {
        static_cast<float>(sqrt(m.m[0] * m.m[0] + m.m[4] * m.m[4] + m.m[8]  * m.m[8] )),
        static_cast<float>(sqrt(m.m[1] * m.m[1] + m.m[5] * m.m[5] + m.m[9]  * m.m[9] )),
        static_cast<float>(sqrt(m.m[2] * m.m[2] + m.m[6] * m.m[6] + m.m[10] * m.m[10])),
    };
}

beVector4 GLKMatrix4ToVector4Quaternion(const GLKMatrix4& matrix)
{
    const GLKQuaternion q = GLKQuaternionMakeWithMatrix4(matrix);
    
    return beVector4 {q.q[0], q.q[1], q.q[2], q.q[3]};
}

beMatrix4 GLKMatrix4ToBEMatrix4(const GLKMatrix4 & matrix)
{
    beMatrix4 m;
    for (int i = 0; i < 16; ++i)
        m.m[i] = matrix.m[i];
    return m;
}

GLKMatrix4 BEMatrix4ToGLKMatrix4(const beMatrix4 & matrix)
{
    GLKMatrix4 m;
    for (int i = 0; i < 16; ++i)
        m.m[i] = matrix.m[i];
    return m;
}

#pragma mark - Unity Interop Math

GLKMatrix4 BE2UnityMatrix(const GLKMatrix4 &m)
{
    if(isnan(m.m[12]))
    {
        return nanGLKMatrix4;
    }
    
    // Converting from Structure SDK axis convention to Unity axis convention
    GLKMatrix4 flipY = GLKMatrix4MakeScale(1, -1, 1);
    GLKMatrix4 result = GLKMatrix4Multiply(flipY, m);
    result = GLKMatrix4Multiply(result, flipY);
    
    return result;
}

GLKMatrix4 Unity2BEMatrix(const GLKMatrix4 &m)
{
    if(isnan(m.m[12]))
    {
        return nanGLKMatrix4;
    }
    
    // Converting from Structure SDK axis convention to Unity axis convention
    GLKMatrix4 flipY = GLKMatrix4MakeScale(1, -1, 1);
    GLKMatrix4 result = GLKMatrix4Multiply(flipY, m);
    result = GLKMatrix4Multiply(result, flipY);
    
    return result;
}

GLKMatrix4 BE2UnityProjMatrix(const GLKMatrix4 &projectionMatrix)
{
    GLKMatrix4 flipYZ = GLKMatrix4MakeScale(1, -1, -1);
    return GLKMatrix4Multiply(projectionMatrix, flipYZ);
}

GLKMatrix4 Unity2BEProjMatrix(const GLKMatrix4 &projectionMatrix)
{
    GLKMatrix4 flipYZ = GLKMatrix4MakeScale(1, -1, -1);
    return GLKMatrix4Multiply(projectionMatrix, flipYZ);
}

#pragma mark - Tools
NSString* mat2String(GLKMatrix4 m) {
    return [NSString stringWithFormat:@"\n%f, %f, %f, %f\n%f, %f, %f, %f\n%f, %f, %f, %f\n%f, %f, %f, %f",
            m.m[0], m.m[1], m.m[2], m.m[3], m.m[4], m.m[5], m.m[6], m.m[7], m.m[8], m.m[9], m.m[10], m.m[11], m.m[12], m.m[13], m.m[14], m.m[15]];
}

uint64_t nanoFromMach(uint64_t mach)
{
    static mach_timebase_info_data_t timebase;
    if ( timebase.denom == 0 ) {
        mach_timebase_info(&timebase);
    }
    
    return mach * timebase.numer / timebase.denom;
}

double msecFromMach(uint64_t mach)
{
    uint64_t nano = nanoFromMach(mach);
    return nano * 1e-6;
}

double msecFromMachAbsoluteTime() {
    return msecFromMach(mach_absolute_time());
}

GLKMatrix4 nanGLKMatrix4 = GLKMatrix4Make(NAN, NAN, NAN, NAN,
                                          NAN, NAN, NAN, NAN,
                                          NAN, NAN, NAN, NAN,
                                          NAN, NAN, NAN, NAN);
