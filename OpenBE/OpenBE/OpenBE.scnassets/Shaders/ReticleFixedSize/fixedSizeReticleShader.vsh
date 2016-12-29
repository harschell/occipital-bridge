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

attribute vec3 position;

varying vec2 uv;

void main(void)
{
    vec3 pos = vec3(0);
    
    gl_Position =  modelViewProjection * vec4(pos, 1.0);
    
    vec2 offset = position.xy;
    offset.y *= abs(projection[1].y/projection[0].x); // aspect ratio
    
    gl_Position.xy += offset * gl_Position.w;
    
    gl_Position.z = 0.001;
    
    uv = sign(position.xy);
    
}
