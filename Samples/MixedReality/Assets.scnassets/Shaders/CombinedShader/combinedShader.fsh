/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

precision mediump float;

varying vec2 uv;
varying float fragmentShaderType;

uniform float active;

void main(void)
{
    if( fragmentShaderType < .5 ) {
        // scanBeamShader.fsh
        
        vec2 alpha  = smoothstep( vec2(0.), vec2(.1,.4), uv) * smoothstep( vec2(1.), vec2(.8, .6), uv);
        float lum = smoothstep( 0., .2, active) * smoothstep( 1., .5, active);

        gl_FragColor = vec4( .5, .7, 1., .5 ) * (alpha.x * alpha.y * lum);
    }
    
    else if( fragmentShaderType < 1.5 ) {
        // fixedSizeReticleShader.fsh
        
        float r = length(uv);
        
        vec3 col = mix( active>.5?vec3( .7,1.,.7):vec3(1.), vec3(0.), smoothstep( .6, .7, r));
        float alpha = 1. - smoothstep(.8, .9, r);
        
        //   if( alpha < .5 ) discard;
        
        gl_FragColor = vec4(col,alpha);
    }

    else if( fragmentShaderType < 2.5 ) {
        // hudShader
        
        float r = length(uv);
        
        vec3 col = mix( active>.5?vec3( .7,1.,.7):vec3(1.), vec3(0.), smoothstep( .6, .7, r));
        float alpha = 1. - smoothstep(.8, .9, r);
        
        //   if( alpha < .5 ) discard;
        
        gl_FragColor = vec4(col,alpha);
    }
}
