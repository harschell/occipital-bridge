/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */
 
#pragma once

#import <GLKit/GLKit.h>

// AH: Remember to make all inline as static inline, or non-optimized builds will fail in pure C.
// http://clang.llvm.org/compatibility.html#inline

#ifdef __cplusplus
# include <cmath>
# define C_OR_CPP_INLINE inline
#else
# include <math.h>
# define C_OR_CPP_INLINE static inline
#endif

C_OR_CPP_INLINE double lerp(double a, double b, double t)
{
    return a + (b - a) * t;
}

C_OR_CPP_INLINE float lerpf(float a, float b, float t)
{
    return a + (b - a) * t;
}

C_OR_CPP_INLINE float clampf(float a, float b, float value)
{
    // Assure correct usage of clamping
    float minimum = fmin(a, b);
    float maximum = fmax(a, b);
    return fmax( fmin( maximum, value ), minimum );
}

C_OR_CPP_INLINE float saturatef(float a)
{
    return clampf(a, 0.f, 1.f);
}

C_OR_CPP_INLINE bool GLKVector3IsNan( GLKVector3 vec ) {
    return isnan( vec.x ) || isnan( vec.y ) || isnan( vec.z );
}

C_OR_CPP_INLINE float random01() {
    return (float)drand48();
}

C_OR_CPP_INLINE float random11() {
    return 1.f - 2.f * (float)drand48();
}

C_OR_CPP_INLINE float smoothstepf(float edge0, float edge1, float x) {
    // Scale, bias and saturate x to 0..1 range
    x = saturatef((x - edge0)/(edge1 - edge0));
    // Evaluate polynomial
    return x*x*(3 - 2*x);
}

/**
 * Calcualte the first derivative of smoothstepf above.
 */
C_OR_CPP_INLINE float smoothstepDxf(float edge0, float edge1, float x) {
    // Scale, bias and saturate x to 0..1 range
    x = saturatef((x - edge0)/(edge1 - edge0));
    
    // Evaluate the first derivative
    return -6*(x-1)*x;
}
