/*
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#ifndef BEUnityBaseInterop_h
#define BEUnityBaseInterop_h

#include <GLKit/GLKit.h>

#pragma mark - Interop Structures
// Basic Data Structures shared between the different interops.

struct beVector2 {
    float x;
    float y;
};

struct beVector3 {
    float x;
    float y;
    float z;
};

struct beVector4 {
    float x;
    float y;
    float z;
    float w;
};

struct beMatrix4 {
    float m[16];
};

#pragma mark - Interop Utility Functions
beVector2 GLKVector2ToVector2(const GLKVector2& vec);
beVector3 GLKMatrix4ToPositionVector3(const GLKMatrix4& matrix);
beVector3 GLKMatrix4ToScaleVector3(const GLKMatrix4& m);
beVector4 GLKMatrix4ToVector4Quaternion(const GLKMatrix4& matrix);
beMatrix4 GLKMatrix4ToBEMatrix4(const GLKMatrix4 & matrix);
GLKMatrix4 BEMatrix4ToGLKMatrix4(const beMatrix4 & matrix);

GLKMatrix4 BE2UnityMatrix(const GLKMatrix4 &m);
GLKMatrix4 Unity2BEMatrix(const GLKMatrix4 &m);
GLKMatrix4 BE2UnityProjMatrix(const GLKMatrix4 &projectionMatrix);
GLKMatrix4 Unity2BEProjMatrix(const GLKMatrix4 &projectionMatrix);

#pragma mark - Interop Callback Types

typedef void (*BEVoidEventCallback)(void);

#pragma mark - Tools
NSString* mat2String(GLKMatrix4 m);
uint64_t nanoFromMach(uint64_t mach);
double msecFromMach(uint64_t mach);
double msecFromMachAbsoluteTime();
extern GLKMatrix4 nanGLKMatrix4;

#endif /* BEUnityStructInterop_h */
