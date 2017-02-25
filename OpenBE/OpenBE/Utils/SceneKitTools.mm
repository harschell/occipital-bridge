/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#import <GLKit/GLKit.h>
#import <SceneKit/SceneKit.h>
#import "SceneKitTools.h"

NSString* NSStringFromSCNVector3(SCNVector3 vector)
{
    return [NSString stringWithFormat:@" [ %f %f %f ]", vector.x, vector.y, vector.z];
}

NSString* NSStringFromSCNMatrix4(SCNMatrix4 matrix)
{
    return [NSString stringWithFormat:@"\n%f %f %f %f\n%f %f %f %f\n%f %f %f %f\n%f %f %f %f",
            matrix.m11, matrix.m21, matrix.m31, matrix.m41,
            matrix.m12, matrix.m22, matrix.m32, matrix.m42,
            matrix.m13, matrix.m23, matrix.m33, matrix.m43,
            matrix.m14, matrix.m24, matrix.m34, matrix.m44];
}

//NSStringFromGLKMatrix4 already built into GLKit, but makes string 2 compact 2 read.
// NOTE: the way we output this is row-major.
// GLKMatrix4Make expects values in column-major.
// So, if you're copying from here, use GLKMatrix4MakeAndTranspose !
NSString* PrettyNSStringFromGLKMatrix4(GLKMatrix4 m)
{
    return [NSString stringWithFormat:@"%f, %f, %f, %f,\n%f, %f, %f, %f,\n%f, %f, %f, %f,\n%f, %f, %f, %f\n",
           m.m00, m.m10, m.m20, m.m30,
           m.m01, m.m11, m.m21, m.m31,
           m.m02, m.m12, m.m22, m.m32,
           m.m03, m.m13, m.m23, m.m33];
}

GLKMatrix4 GLKMatrix4FromSCNMatrix4(SCNMatrix4 matrix)
{
    //(1,1) => (0,0)
    
    GLKMatrix4 g;
    g.m00 = matrix.m11; g.m10 = matrix.m21; g.m20 = matrix.m31; g.m30 = matrix.m41;
    g.m01 = matrix.m12; g.m11 = matrix.m22; g.m21 = matrix.m32; g.m31 = matrix.m42;
    g.m02 = matrix.m13; g.m12 = matrix.m23; g.m22 = matrix.m33; g.m32 = matrix.m43;
    g.m03 = matrix.m14; g.m13 = matrix.m24; g.m23 = matrix.m34; g.m33 = matrix.m44;
    
    return g;
}

NSString* NSStringFromHomogenousGLKVector4(GLKVector4 vector)
{
    return NSStringFromGLKVector4(GLKVector4Make(vector.x/vector.w, vector.y/vector.w, vector.z/vector.w, vector.w/vector.w));
}


bool GLKMatrix4Equals(GLKMatrix4 m1, GLKMatrix4 m2)
{
    const float EPS = 0.001;
    
    bool eq = true;
    for (int i = 0; i < 16; i++)
    {
        eq &= fabsf(m1.m[i] - m2.m[i]) < EPS;
    }
    return eq;
}

bool hasnan(SCNVector3 v)
{
    return isnan(v.x) || isnan(v.y) || isnan(v.z);
}

bool hasnan(SCNMatrix4 m)
{
    return isnan(m.m11) || isnan(m.m21) || isnan(m.m31) || isnan(m.m41) ||
        isnan(m.m12) || isnan(m.m22) || isnan(m.m32) || isnan(m.m42) ||
        isnan(m.m13) || isnan(m.m23) || isnan(m.m33) || isnan(m.m43) ||
        isnan(m.m14) || isnan(m.m24) || isnan(m.m34) || isnan(m.m44);
}

bool hasnan(GLKVector3 v)
{
    return isnan(v.x) || isnan(v.y) || isnan(v.z);
}

bool hasnan(GLKMatrix4 m)
{
    return  isnan(m.m00) || isnan(m.m10) || isnan(m.m20) || isnan(m.m30) ||
            isnan(m.m01) || isnan(m.m11) || isnan(m.m21) || isnan(m.m31) ||
            isnan(m.m02) || isnan(m.m12) || isnan(m.m22) || isnan(m.m32) ||
            isnan(m.m03) || isnan(m.m13) || isnan(m.m23) || isnan(m.m33);
}


//------------------------------------------------------------------------------

@implementation SceneKitTools : NSObject

+ (SCNVector3)addVector:(SCNVector3)a toVector:(SCNVector3) b
{
    return SCNVector3Make(a.x + b.x,
                          a.y + b.y,
                          a.z + b.z);
}

+ (SCNVector3)subtractVector:(SCNVector3)b fromVector:(SCNVector3) a
{
    return SCNVector3Make(a.x - b.x,
                          a.y - b.y,
                          a.z - b.z);
}

+ (SCNVector3) lerpVector:(SCNVector3)start toVector:(SCNVector3)end fraction:(float)fraction {
    SCNVector3 a = [SceneKitTools multiplyVector:start byFloat:(1-fraction)];
    SCNVector3 b = [SceneKitTools multiplyVector:end byFloat:fraction];
    return [SceneKitTools addVector:a toVector:b];
}


+ (float)vectorMagnitude:( SCNVector3 ) vectorA
{
    float Ax = vectorA.x * vectorA.x;
    float Ay = vectorA.y * vectorA.y;
    float Az = vectorA.z * vectorA.z;
    return ABS(sqrtf(Ax + Ay + Az));
}

+ (SCNVector3)normalizedVector:( SCNVector3 ) vectorA
{
    float magnitude = [self vectorMagnitude:vectorA];
    float Ax = vectorA.x/magnitude;
    float Ay = vectorA.y/magnitude;
    float Az = vectorA.z/magnitude;
    return SCNVector3Make(Ax, Ay, Az);
}

+ (float)distanceFromVector:( SCNVector3 ) vectorA toVector: ( SCNVector3 ) vectorB
{
    return [self vectorMagnitude:[self subtractVector:vectorB fromVector:vectorA]];
}

+ (SCNVector3)directionFromVector:( SCNVector3 ) vectorA toVector: ( SCNVector3 ) vectorB
{
    float Ax = vectorB.x - vectorA.x;
    float Ay = vectorB.y - vectorA.y;
    float Az = vectorB.z - vectorA.z;
    return SCNVector3Make(Ax, Ay, Az);
}

+ (SCNVector3)multiplyVector:( SCNVector3 ) v byFloat: ( float ) factor
{
    return SCNVector3Make(factor*v.x, factor*v.y, factor*v.z);
}

+ (SCNVector3)divideVector:( SCNVector3 ) vectorA byDouble: ( double ) value
{
    float Ax = vectorA.x / value;
    float Ay = vectorA.y / value;
    float Az = vectorA.z / value;
    return SCNVector3Make(Ax, Ay, Az);
}

+ (float)dotProduct:(SCNVector3)vectorA andVector:(SCNVector3)vectorB
{
    return vectorA.x * vectorB.x + vectorA.y * vectorB.y + vectorA.z * vectorB.z;
}

+ (float)angleBetweenVector:(SCNVector3)vectorA andVector:(SCNVector3)vectorB
{
    float dot = [self dotProduct:vectorA andVector:vectorB];
    return acos(dot/([self vectorMagnitude:vectorA]*[self vectorMagnitude:vectorB]));
}

+ (SCNVector3)capSCNVector3Length:(SCNVector3)vector atFloat:(float) maxLength
{
    float length = [self vectorMagnitude:vector];
    if (length > maxLength) {
        vector = [SceneKitTools multiplyVector:vector byFloat:maxLength/length];
    }
    return vector;
}

#define ARC4RANDOM_MAX      0x100000000
+ (float)randf
{
    //returns a random float (-1, 1)
    return 2*(float) arc4random() / ARC4RANDOM_MAX - 1;
}

#pragma mark - command line logging functions

+ (void)logSCNVector3:(SCNVector3)vector
{
    NSLog(@"\n %@ \n", NSStringFromSCNVector3(vector));
}

+ (void)logSCNVector4:(SCNVector4)vector
{
    NSLog(@"\n [ %f %f %f %f ] \n", vector.w, vector.x, vector.y, vector.z);
}

+ (void)logSCNMatrix4:(SCNMatrix4)matrix
{
    
    NSLog(@"\n%f %f %f %f\n%f %f %f %f\n%f %f %f %f\n%f %f %f %f",
          matrix.m11, matrix.m21, matrix.m31, matrix.m41,
          matrix.m12, matrix.m22, matrix.m32, matrix.m42,
          matrix.m13, matrix.m23, matrix.m33, matrix.m43,
          matrix.m14, matrix.m24, matrix.m34, matrix.m44);
}

+ (void)logGLKMatrix4:(GLKMatrix4)matrix
{
    NSLog(@"\n%f %f %f %f\n%f %f %f %f\n%f %f %f %f\n%f %f %f %f",
          matrix.m00, matrix.m10, matrix.m20, matrix.m30,
          matrix.m01, matrix.m11, matrix.m21, matrix.m31,
          matrix.m02, matrix.m12, matrix.m22, matrix.m32,
          matrix.m03, matrix.m13, matrix.m23, matrix.m33);
}

+ (void)printParentHierarchyOfNode:(SCNNode*)node
{
    do {
        NSLog(@" name: %@", node.name);
        NSLog(@" transform: %@", NSStringFromSCNMatrix4(node.transform) );
        NSLog(@" worldTransform: %@", NSStringFromSCNMatrix4(node.worldTransform) );
        NSLog(@" ------  ");
        node = node.parentNode;
    } while (node != nil);
    
    NSLog(@" Node Hierarchy Search Done.");
}

#pragma mark - SceneKit conversions

+ (SCNVector3)getPositionFromTransform:(SCNMatrix4)m
{
    SCNVector3 pos = SCNVector3Make(m.m41, m.m42, m.m43);
    return pos;
}

+ (SCNVector4)getRotationFromTransform:(SCNMatrix4)m
{
    SCNVector4 rot;
    if (m.m11 == 1.0f)
    {
        rot.y = atan2f(m.m13, m.m34);
        rot.x = 0;
        rot.z = 0;
        
    }else if (m.m11 == -1.0f)
    {
        rot.y = atan2f(m.m13, m.m34);
        rot.x = 0;
        rot.z = 0;
    }else
    {
        rot.y = atan2(-m.m31,m.m11);
        rot.x = asin(m.m21);
        rot.z = atan2(-m.m23,m.m22);
    }
    return  rot;
}

+ (SCNVector3)getWorldPos:(SCNNode *)n
{
    return [self getPositionFromTransform:n.presentationNode.worldTransform];
}

+ (SCNVector4)getWorldRot:(SCNNode *)n
{
    return [self getRotationFromTransform:n.presentationNode.worldTransform];
}

+ (SCNVector3)vectorFromNode:(SCNNode *)fromNode toNode:(SCNNode*)toNode
{
    SCNVector3 diff = [SceneKitTools subtractVector:[SceneKitTools getWorldPos:toNode] fromVector:[SceneKitTools getWorldPos:fromNode]];
    
    return diff;
}

+ (float)distancefromNode:(SCNNode *)fromNode toNode:(SCNNode*)toNode
{
    SCNVector3 diff = [self vectorFromNode:fromNode toNode:toNode];
    return [self vectorMagnitude:diff];
}

+ (SCNVector3)getLookAtVectorOfNodeLocal:(SCNNode*)n
{
    SCNMatrix4 lookVectorMatrix = SCNMatrix4MakeTranslation(0, 0, -1);
    SCNMatrix4 nodeRotationMatrix = [self isolateRotationFromSCNMatrix4:n.presentationNode.transform];
    // IMPORTANT: SCNMatrix4Mult(a,b) returns b*a.
    SCNMatrix4 lookVectorMatrixTransformed = SCNMatrix4Mult(lookVectorMatrix, nodeRotationMatrix);
    
    return [self normalizedVector:[self getPositionFromTransform:lookVectorMatrixTransformed]];
}

+ (SCNVector3)getLookAtVectorOfNode:(SCNNode*)n
{
    SCNMatrix4 lookVectorMatrix = SCNMatrix4MakeTranslation(0, 0, 1);
    SCNMatrix4 nodeRotationMatrix = [self isolateRotationFromSCNMatrix4:n.presentationNode.worldTransform];
    // IMPORTANT: SCNMatrix4Mult(a,b) returns b*a.
    SCNMatrix4 lookVectorMatrixTransformed = SCNMatrix4Mult(lookVectorMatrix, nodeRotationMatrix);
    
    return [self normalizedVector:[self getPositionFromTransform:lookVectorMatrixTransformed]];
}

SCNMatrix4 SCNMatrix4MakeFromSCNVector3(SCNVector3 vector)
{
    return SCNMatrix4MakeTranslation(vector.x, vector.y, vector.z);
}

+ (SCNVector3)multiplyVector:(SCNVector3)vector bySCNMatrix4:(SCNMatrix4)matrix
{
    SCNMatrix4 vectorMatrix = SCNMatrix4MakeFromSCNVector3(vector);
    // IMPORTANT: SCNMatrix4Mult(a,b) returns b*a.
    SCNMatrix4 vectorTransformed = SCNMatrix4Mult(vectorMatrix, matrix);
    return [self getPositionFromTransform:vectorTransformed];
}

+ (SCNVector3)crossProductOfSCNVector3:(SCNVector3)vectorA with:(SCNVector3)vectorB
{
    GLKVector3 product = GLKVector3CrossProduct(SCNVector3ToGLKVector3(vectorA), SCNVector3ToGLKVector3(vectorB));
    return SCNVector3FromGLKVector3(product);
}

+ (SCNMatrix4)isolateAxisRotationFromSCNMatrix4:(SCNMatrix4)rotationMatrix axis:(SCNVector3)axis orthoVector:(SCNVector3)orthoVector
{
    // A user-supplied orthoAxis shouldn't be necessary, but it is easier than just guessing one.
    
    // Normalize just in case
    axis = [self normalizedVector:axis];
    orthoVector = [self normalizedVector:orthoVector];
    
    SCNVector3 orthoVectorRotated = [self multiplyVector:orthoVector bySCNMatrix4:rotationMatrix];
    
    if ([self vectorMagnitude:orthoVectorRotated] < 0.01)
    {
        // Use new orthogonal vector
        NSLog(@"use new orthogonal vector (as first was rotated out)");
        orthoVector = [self crossProductOfSCNVector3:axis with:orthoVector];
        orthoVectorRotated = [self multiplyVector:orthoVector bySCNMatrix4:rotationMatrix];
    }
    
    GLKVector3 axisGLK = SCNVector3ToGLKVector3(axis);
    GLKVector3 orthoVectorGLK = SCNVector3ToGLKVector3(orthoVector);
    GLKVector3 orthoVectorRotatedGLK = SCNVector3ToGLKVector3(orthoVectorRotated);
    
    // Project orthoVectorRotated onto axis normal
    GLKVector3 orthoVectorProjectedGLK = GLKVector3Subtract(orthoVectorRotatedGLK, GLKVector3Project(orthoVectorRotatedGLK, axisGLK));
    
    float angleAboutAxis = [self angleBetweenVector:SCNVector3FromGLKVector3(orthoVectorProjectedGLK) andVector:orthoVector];
    
    if (isnan(angleAboutAxis))
        return SCNMatrix4Identity;
    
    // Now to calculate angle sign:
    GLKVector3 crossProductResultGLK = GLKVector3CrossProduct(orthoVectorProjectedGLK, orthoVectorGLK);
    
    if (GLKVector3Length(crossProductResultGLK) == 0)
    {
        NSLog(@"isolateAxisRotationFromSCNMatrix4: no rotation found");
        [self logSCNMatrix4:rotationMatrix];
        [self logSCNVector3:orthoVectorRotated];
        
        return SCNMatrix4Identity;
    }

    // crossProductResult should be coincident with axis - sanity check
    SCNVector3 crossProductResult = SCNVector3FromGLKVector3(crossProductResultGLK);
    
    float dotProductResult = [self dotProduct:crossProductResult andVector:axis];
    if (dotProductResult < 0)
        angleAboutAxis *= -1;
    
    return SCNMatrix4MakeRotation(angleAboutAxis, axis.x, axis.y, axis.z);
}

+ (SCNMatrix4)isolateRotationFromSCNMatrix4:(SCNMatrix4)matrix
{
    SCNMatrix4 isolateRot = matrix;
    isolateRot.m41 = 0;
    isolateRot.m42 = 0;
    isolateRot.m43 = 0;
    return isolateRot;
}

+ (SCNMatrix4)convertSTTrackerPoseToSceneKitPose:(GLKMatrix4)stTrackerPose
{
    // The SceneKit and STTracker coordinate spaces have opposite Y and Z axes
    GLKMatrix4 flipYZ = GLKMatrix4MakeScale(1, -1, -1);
    GLKMatrix4 m = GLKMatrix4Multiply(flipYZ, stTrackerPose);
    m = GLKMatrix4Multiply(m, flipYZ);
    SCNMatrix4 SCNSceneKitCameraPose = SCNMatrix4FromGLKMatrix4(m);
    return SCNSceneKitCameraPose;
}

+ (GLKMatrix4) convertSceneKitPoseToSTTrackerPose:(SCNMatrix4)sceneKitPose_
{
    GLKMatrix4 sceneKitPose = GLKMatrix4FromSCNMatrix4(sceneKitPose_);
    // The SceneKit and STTracker coordinate spaces have opposite Y and Z axes
    GLKMatrix4 flipYZ = GLKMatrix4MakeScale(1, -1, -1);
    GLKMatrix4 m = GLKMatrix4Multiply(flipYZ, sceneKitPose);
    m = GLKMatrix4Multiply(m, flipYZ);
    return m;
}

+ (void) setCastShadow:(bool)castShadow ofNode:(SCNNode *)node {
    node.castsShadow = castShadow;
    for( SCNNode * child in node.childNodes ) {
        [SceneKitTools setCastShadow:castShadow ofNode:child];
    }
}

+ (void) setCategoryBitMask:(int)bitmask ofNode:(SCNNode *)node {
    node.categoryBitMask = bitmask;
    for( SCNNode * child in node.childNodes ) {
        [SceneKitTools setCategoryBitMask:bitmask ofNode:child];
    }
}

+ (void) setRenderingOrder:(int)order ofNode:(SCNNode *)node {
    node.renderingOrder = order;
    for( SCNNode * child in node.childNodes ) {
        [SceneKitTools setRenderingOrder:order ofNode:child];
    }
}

+ (void) setOpacity:(float)opacity ofNode:(SCNNode *)node {
    node.opacity = opacity;
    for( SCNNode * child in node.childNodes ) {
        [SceneKitTools setOpacity:opacity ofNode:child];
    }
}

@end
