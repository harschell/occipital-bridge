/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

#pragma once

#import <BridgeEngine/BridgeEngineAPI.h>

#import <GLKit/GLKMatrix4.h>
#import <SceneKit/SceneKit.h>

#include <algorithm>

NSString* NSStringFromSCNVector3(SCNVector3 vector);
NSString* NSStringFromSCNMatrix4(SCNMatrix4 matrix);

NSString* PrettyNSStringFromGLKMatrix4(GLKMatrix4 matrix);

NSString* NSStringFromHomogenousGLKVector4(GLKVector4 vector);

bool GLKMatrix4Equals(GLKMatrix4 m1, GLKMatrix4 m2);
bool SCNMatrix4Equals(SCNMatrix4 m1, SCNMatrix4 m2);

GLKMatrix4 GLKMatrix4FromSCNMatrix4(SCNMatrix4 matrix);
inline GLKVector3 GLKVector3FromSCNVector3(const SCNVector3& v) { return {v.x, v.y, v.z}; }

bool hasnan(SCNVector3 v);
bool hasnan(SCNMatrix4 m);
bool hasnan(GLKVector3 v);
bool hasnan(GLKMatrix4 m);

inline SCNVector3 operator - (const SCNVector3& vec) { return SCNVector3Make(-vec.x, -vec.y, -vec.z); }

inline SCNVector3 operator + (const SCNVector3& lhs, const SCNVector3 rhs) { return SCNVector3Make(lhs.x + rhs.x, lhs.y + rhs.y, lhs.z + rhs.z); }
inline SCNVector3 operator - (const SCNVector3& lhs, const SCNVector3 rhs) { return SCNVector3Make(lhs.x - rhs.x, lhs.y - rhs.y, lhs.z - rhs.z); }
inline SCNVector3 operator * (const SCNVector3& lhs, CGFloat val) { return SCNVector3Make(lhs.x * val, lhs.y * val, lhs.z * val); }
inline SCNVector3 operator / (const SCNVector3& lhs, CGFloat val) { return SCNVector3Make(lhs.x / val, lhs.y / val, lhs.z / val); }


//------------------------------------------------------------------------------
@interface SceneKitTools : NSObject

#pragma mark - Math and Transforms

+ (SCNVector3) addVector:(SCNVector3)a toVector:(SCNVector3) b;
+ (SCNVector3) subtractVector:(SCNVector3)b fromVector:(SCNVector3) a;

+ (SCNVector3) lerpVector:(SCNVector3)start toVector:(SCNVector3)end fraction:(float)fraction;

+ (float) vectorMagnitude:( SCNVector3 ) vectorA;
+ (SCNVector3)normalizedVector:(SCNVector3)vectorA;

+ (float) distanceFromVector:( SCNVector3 ) vectorA toVector: ( SCNVector3 ) vectorB;
+ (SCNVector3) directionFromVector:( SCNVector3 ) vectorA toVector: ( SCNVector3 ) vectorB;

+ (SCNVector3) multiplyVector:( SCNVector3 ) vectorA byFloat: ( float ) factor;
+ (SCNVector3) multiplyVector:(SCNVector3)vector bySCNMatrix4:(SCNMatrix4)matrix;
+ (SCNVector3) divideVector:( SCNVector3 ) vectorA byDouble: ( double ) value;

+ (float) dotProduct:(SCNVector3)vectorA andVector:(SCNVector3)vectorB;
+ (float) angleBetweenVector:(SCNVector3)vectorA andVector:(SCNVector3)vectorB;

+ (SCNVector3)capSCNVector3Length:(SCNVector3)vector atFloat:(float) length;

+ (void)logSCNVector3:(SCNVector3)vector;
+ (void)logSCNVector4:(SCNVector4)vector;
+ (void)logSCNMatrix4:(SCNMatrix4)matrix;
+ (void)logGLKMatrix4:(GLKMatrix4)matrix;

+ (void)printParentHierarchyOfNode:(SCNNode*)node;

+ (SCNVector3) getPositionFromTransform:(SCNMatrix4)m;
+ (SCNVector4) getRotationFromTransform:(SCNMatrix4)m;
+ (SCNVector3) getWorldPos:(SCNNode *)n;
+ (SCNVector4) getWorldRot:(SCNNode *)n;
+ (SCNVector3) vectorFromNode:(SCNNode *)fromNode toNode:(SCNNode*)toNode;
+ (float) distancefromNode:(SCNNode *)fromNode toNode:(SCNNode*)toNode;

+ (SCNVector3) getLookAtVectorOfNodeLocal:(SCNNode*)n;
+ (SCNVector3) getLookAtVectorOfNode:(SCNNode*)n;

+ (SCNVector3) crossProductOfSCNVector3:(SCNVector3)vectorA with:(SCNVector3)vectorB;
+ (SCNMatrix4) isolateAxisRotationFromSCNMatrix4:(SCNMatrix4)rotationMatrix axis:(SCNVector3)axis orthoVector:(SCNVector3)orthoVector;

+ (float)randf;
+ (SCNMatrix4) isolateRotationFromSCNMatrix4:(SCNMatrix4)matrix;
+ (SCNMatrix4) convertSTTrackerPoseToSceneKitPose:(GLKMatrix4)stTrackerPose;
+ (GLKMatrix4) convertSceneKitPoseToSTTrackerPose:(SCNMatrix4)stTrackerPose;

+ (void) setCastShadow:(bool)castShadow ofNode:(SCNNode *)node;
+ (void) setCategoryBitMask:(int)bitmask ofNode:(SCNNode *)node;
+ (void) setRenderingOrder:(int)order ofNode:(SCNNode *)node;
+ (void) setOpacity:(float)opacity ofNode:(SCNNode *)node;

@end

//------------------------------------------------------------------------------

namespace BE {

struct WidthOrHeight
{
    enum Type { WidthType, HeightType };

    WidthOrHeight (Type type, CGFloat value) : type(type), value(value) {}
    
    static WidthOrHeight width  (CGFloat value) { return WidthOrHeight(WidthType , value); }
    static WidthOrHeight height (CGFloat value) { return WidthOrHeight(HeightType, value); }

    void imageAspectPreservingSizes(CGFloat imageWidth, CGFloat imageHeight, CGFloat& width, CGFloat& height) const
    {
        CGFloat imageAspect = imageWidth / imageHeight;
        
        if (WidthOrHeight::WidthType == type)
        {
            width  = value;
            height = width * (1.0 / imageAspect);
        }
        else
        {
            height = value;
            width  = height * imageAspect;
        }
    }
    void imageAspectPreservingSizes(UIImage* image, CGFloat& width, CGFloat& height) const
    {
        if (image)
        {
            return imageAspectPreservingSizes(image.size.width, image.size.height, width, height);
        }
        
        NSLog(@"Invalid image passed to imageAspectPreservingSizes.");
        width = height = -1;
    }

    Type    type;
    CGFloat value;
};

inline float linearInterpolate (float t, float lhs, float rhs)
{
    return lhs + t * (rhs - lhs);
}

struct OneVariableAnimator
{
public:
    OneVariableAnimator () = default;
    
    OneVariableAnimator (float value)
    {
        _startValue = value;
        _endValue = value;
        _currentValue = value;
    }
    
    void start (CFTimeInterval startTime, float startValue, float endValue, CFTimeInterval duration)
    {
        _startTime = startTime;
        _duration = duration;
        _startValue = startValue;
        _endValue = endValue;
    }
    
    void updateAtTime (CFTimeInterval currentTime)
    {
        // oc_dbg ("Updating game animator, duration=%f startTime=%f deltaT=%f", _duration, _startTime, currentTime - _startTime);
        
        _step = 1.0;
        
        if (_duration > 1e-5)
        {
            _step = (currentTime - _startTime) / _duration;
            _step = std::min (_step, 1.0f);
        }
        
        _currentValue = linearInterpolate(_step, _startValue, _endValue);
    }
    
    bool isFinished () const { return _step > 0.9999; }
    
    float currentValue() const { return _currentValue; }
    
private:
    CFTimeInterval _duration = 0.;
    CFTimeInterval _startTime = 0.;
    float _startValue = 1.0;
    float _endValue = 1.0;
    float _currentValue = 1.f;
    float _step = 1.0f;
};

} // BE namespace
