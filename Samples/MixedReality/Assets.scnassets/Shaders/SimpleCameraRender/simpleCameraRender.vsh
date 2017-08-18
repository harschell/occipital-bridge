/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

// IMPORTANT NOTE: this shader is actually inlined in CombinedShader
// to workaround a SceneKit issue.

uniform mat4 modelViewProjection;
uniform mat4 modelTransform;
uniform mat4 viewTransform;
uniform mat4 projectionTransform;
attribute vec3 position;
attribute vec3 a_color;

varying vec2 uv;
varying vec4 v_positionClipSpace;

void main(void)
{
    
    gl_Position =  modelViewProjection * vec4(position, 1.0);
    //gl_Position = projectionTransform * viewTransform * vec4(a_color, 1.0);
    //gl_Position = modelViewProjection * vec4(position, 1.0);

    v_positionClipSpace = projectionTransform * viewTransform * vec4(a_color, 1.0);

    uv = sign(position.xy);
}
