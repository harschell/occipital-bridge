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

varying vec2 uv;

void main(void)
{
    
    gl_Position =  modelViewProjection * vec4(position, 1.0);

    uv = sign(position.xy);
}
