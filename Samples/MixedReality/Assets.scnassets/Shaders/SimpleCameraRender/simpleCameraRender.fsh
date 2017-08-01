/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

// IMPORTANT NOTE: this shader is actually inlined in CombinedShader
// to workaround a SceneKit issue.

precision mediump float;

uniform vec2 u_resolution;
uniform sampler2D cameraSampler;

void main(void)
{
    vec2 uv = gl_FragCoord.xy / u_resolution;
    vec4 col = texture2D(cameraSampler, fract(uv));
    
    gl_FragColor = col;
}
