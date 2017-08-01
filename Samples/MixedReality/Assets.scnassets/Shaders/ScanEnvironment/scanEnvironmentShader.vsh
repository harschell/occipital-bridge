/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

attribute vec4 a_position;
attribute vec3 a_normal;

uniform mat4 u_perspective_projection;
uniform mat4 u_modelview;

varying vec3 v_worldPos;

void main()
{
    gl_Position = u_perspective_projection * u_modelview * a_position;
    v_worldPos = a_position.xyz;
}
