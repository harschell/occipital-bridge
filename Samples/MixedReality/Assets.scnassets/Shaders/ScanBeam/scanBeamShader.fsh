/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

// IMPORTANT NOTE: this shader is actually inlined in CombinedShader
// to workaround a SceneKit issue.

precision mediump float;

varying vec2 uv;
uniform float active;

void main(void)
{
    vec2 alpha  = smoothstep( vec2(0.), vec2(.1,.4), uv) * smoothstep( vec2(1.), vec2(.8, .6), uv);
    float lum = smoothstep( 0., .2, active) * smoothstep( 1., .5, active);

    gl_FragColor = vec4( .7,1.,.7, .025 ) * (alpha.x * alpha.y * lum);
}
