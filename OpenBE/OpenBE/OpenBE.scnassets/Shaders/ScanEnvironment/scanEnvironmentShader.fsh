/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

precision mediump float;

varying vec3 v_worldPos;

uniform float u_scanTime;
uniform float u_scanDuration;
uniform float u_scanRadius;
uniform vec3 u_scanOrigin;

uniform sampler2D u_depthSampler;
uniform sampler2D u_colorSampler;
uniform vec2 u_resolution;

const float LinesPerMeter = 25.;
const float ScanSlewTimingRate = 0.015;

void main()
{
    float scanTime = u_scanTime;
    float duration = u_scanDuration;
    vec3 scanOrigin = u_scanOrigin;
    float scanRadius = u_scanRadius;
    
    vec4 fragPos = vec4(v_worldPos, 1.0);
    
    // Calculate the decay parameters related to scanning time (0 min, to 0.5 peak, to 1 min)
    float pulseTime = 1.;
    float strength = smoothstep( 0., .5, scanTime) * (1.- smoothstep( duration-.5, duration, scanTime));
    float maxDist = scanRadius * strength;
    float waveLength = .3;
    
    float disty = scanOrigin.y - fragPos.y;
    float dist = distance( fragPos.xz, scanOrigin.xz ) + (step(disty,-0.5)+step(0.5,disty))*10.;
    float lineDist = (disty - scanTime*ScanSlewTimingRate) * LinesPerMeter;
    
    float amount = clamp(1.-smoothstep(0.5 * maxDist,maxDist, dist), 0., 1.);
    
    float diffamount = (1.-.5*amount);
    
    float worldStableScanY = (fragPos.y/* - scanTime*ScanSlewTimingRate*/) * LinesPerMeter;
    float emissionAmount = amount * (1.-smoothstep( 0., 0.15, abs( fract( worldStableScanY ) - .5) ));
    
    vec2 uv = gl_FragCoord.xy/u_resolution;
    
    vec4 diffuse = texture2D( u_colorSampler, fract(uv) ) * diffamount;
    
    diffuse += vec4( .7,1.,.7, 1. ) * emissionAmount ;
//    diffuse.a = 1.;
    
    gl_FragColor = diffuse;
}
