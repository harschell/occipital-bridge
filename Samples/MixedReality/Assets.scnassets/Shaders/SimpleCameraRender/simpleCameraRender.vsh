/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

// IMPORTANT NOTE: this shader is actually inlined in CombinedShader
// to workaround a SceneKit issue.

uniform mat4 modelViewProjection;
attribute vec3 position;
attribute vec3 a_color;

varying vec2 uv;
varying vec3 v_color;

void main(void)
{
    
    gl_Position =  modelViewProjection * vec4(position, 1.0);

    v_color = a_color;

    uv = sign(position.xy);
}
