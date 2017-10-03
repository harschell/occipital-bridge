/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

// This shader is used to make an object look like a projection.

// IMPORTANT NOTE: this shader is actually inlined in CombinedShader
// to workaround a SceneKit issue.

attribute vec3 position;
attribute vec3 normal;

uniform mat4 modelViewProjection;
uniform mat4 modelViewTransform;

varying lowp float rim;

void main()
{
    gl_Position =  modelViewProjection * vec4(position, 1.0);
    
    vec3 n = normalize(modelViewTransform * vec4(normal, 0)).xyz;  // convert normal to view space
    vec3 viewPos = (modelViewTransform * vec4(position, 1.0)).xyz; // convert position to view space
    vec3 v = normalize(-viewPos);                                  // vector towards eye
    rim = (1.0 - max(dot(v, n), 0.0)) * length(normal);             // rim shading (w/fallback if normal isn't set)
}
