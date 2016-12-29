/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

precision mediump float;

attribute vec4 a_position;
attribute vec3 a_normal;

uniform mat4 u_perspective_projection;
uniform mat4 u_modelview;
uniform vec3 u_scanOrigin;
uniform float u_scanTime;
uniform float u_scanRadius;

varying vec3 v_worldPos;
varying vec2 v_uv;

void main()
{
    float distortionAmount = 0.1 * ( 1.0 / (10.0 * length(a_position.xyz - u_scanOrigin)));
    
    distortionAmount = clamp(distortionAmount, 0.0, 0.15);
    
    vec3 distortedPos = a_position.xyz +
    cos((a_position.xyz - u_scanOrigin) * 25.0 + u_scanTime) * distortionAmount;
    
    // see where in NDC the pixel would have landed before distortion
    vec4 tmp_pos = (u_perspective_projection * u_modelview * a_position);
    v_uv = tmp_pos.xy / tmp_pos.w;
    
    // NDC to slip space
    v_uv += 1.0;
    v_uv /= 2.0;
    
    v_worldPos = a_position.xyz;
                                                    
    gl_Position = u_perspective_projection * u_modelview * vec4(distortedPos, 1.0);
}
