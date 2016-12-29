/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

// IMPORTANT NOTE: this shader is actually inlined in CombinedShader
// to workaround a SceneKit issue.

uniform mat4 modelViewProjection;
uniform mat4 projection;

uniform vec3 startPos;
uniform vec3 endPos;

attribute vec3 position;
varying vec2 uv;

#define HASHSCALE3 vec3(443.897, 441.423, 437.195)

//----------------------------------------------------------------------------------------
//  2 out, 1 in...
vec2 hash21(float p)
{
    vec3 p3 = fract(vec3(p) * HASHSCALE3);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract(vec2((p3.x + p3.y)*p3.z, (p3.x+p3.z)*p3.y));
}



void main(void)
{
    
    vec4 startPosScreen = modelViewProjection * vec4(startPos, 1.0);
    
    
    vec3 pos = endPos;
    vec3 forward = normalize(endPos-startPos);
    
    vec3 up = normalize( cross( forward, vec3(0,1,0) ) );
    vec3 right = normalize( cross( up, forward ));
    up = normalize( cross( forward, right ) );
    
    vec2 h = 2.*(hash21(position.z + position.y)-.5);
    
    pos += up * (height * h.x) + right * (width * h.y);
    
    vec4 endPosScreen = modelViewProjection * vec4(pos, 1.0);
    
    
    gl_Position = mix( startPosScreen, endPosScreen, position.x );
    
 //   gl_Position.z = 0.001;
    
    uv = position.xy;
    
}
