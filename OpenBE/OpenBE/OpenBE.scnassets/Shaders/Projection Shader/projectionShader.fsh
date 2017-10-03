/*
 Bridge Engine Open Source
 This file is part of the Structure SDK.
 Copyright © 2016 Occipital, Inc. All rights reserved.
 http://structure.io
 */

// This shader is used to make an object look like a projection.

// IMPORTANT NOTE: this shader is actually inlined in CombinedShader
// to workaround a SceneKit issue.

varying lowp float rim;
void main()
{
    gl_FragColor = vec4(55.0/255.0, 179.0/255.0, 246.0/255.0, 1.0) * 0.2 + 2 * vec4(55.0/255.0, 179.0/255.0, 246.0/255.0, 1) * pow(rim, 1.5);
}
