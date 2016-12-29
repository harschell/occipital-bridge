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
    float r = length(uv);
    
    vec3 col = mix( active>.5?vec3( .7,1.,.7):vec3(1.), vec3(0.), smoothstep( .6, .7, r));
    float alpha = 1. - smoothstep(.8, .9, r);
    
 //   if( alpha < .5 ) discard;
    
    gl_FragColor = vec4(col,alpha);
}
