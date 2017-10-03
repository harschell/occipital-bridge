/*
 * This file is part of the Structure SDK.
 * Copyright © 2016 Occipital, Inc. All rights reserved.
 * http://structure.io
 *
 * Provides the base runtime interop data structures that
 * match BEUnityBaseInterop.h in BridgeEngine native code.
 */

using UnityEngine;
using System.Collections;
using System.Runtime.InteropServices;

using BEDummyGoogleVR;
namespace BEDummyGoogleVR {}

// these are simplified vectors to match up with
// the data coming in from the obj-c plugin
[StructLayout(LayoutKind.Sequential)]
internal struct beVector2
{
    public float x;
    public float y;
    
    public Vector2 ToVector2() { return new Vector2(x, y); }
    public beVector2(Vector2 v) { x = v.x; y = v.y; }
    public void Set(Vector2 v)  { x = v.x; y = v.y; }
};

[StructLayout(LayoutKind.Sequential)]
internal struct beVector3
{
    public float x;
    public float y;
    public float z;

    public Vector3 ToVector3() { return new Vector3(x, y, z); }
    public beVector3(Vector3 v) { x = v.x; y = v.y; z = v.z; }
    public void Set(Vector3 v)  { x = v.x; y = v.y; z = v.z; }
};

[StructLayout(LayoutKind.Sequential)]
internal struct beVector4
{
    public float x;
    public float y;
    public float z;
    public float w;

    public Quaternion ToQuaternion() { return new Quaternion(x, y, z, w); }
    public beVector4(Quaternion v) { x = v.x; y = v.y; z = v.z; w = v.w; }
    public void Set(Quaternion v)  { x = v.x; y = v.y; z = v.z; w = v.w; }
};

[StructLayout(LayoutKind.Sequential)]
internal struct beMatrix4
{
    public float m1;
    public float m2;
    public float m3;
    public float m4;
    public float m5;
    public float m6;
    public float m7;
    public float m8;
    public float m9;
    public float m10;
    public float m11;
    public float m12;
    public float m13;
    public float m14;
    public float m15;
    public float m16;

    public Matrix4x4 ToMatrix()
    { 
        Matrix4x4 res = new Matrix4x4();
        res.m00 = m1;
        res.m10 = m2;
        res.m20 = m3;
        res.m30 = m4;
        res.m01 = m5;
        res.m11 = m6;
        res.m21 = m7;
        res.m31 = m8;
        res.m02 = m9;
        res.m12 = m10;
        res.m22 = m11;
        res.m32 = m12;
        res.m03 = m13;
        res.m13 = m14;
        res.m23 = m15;
        res.m33 = m16;

        return res; 
    }

    public void Set(Matrix4x4 m)
    {
        m1  = m.m00;
        m2  = m.m10;
        m3  = m.m20;
        m4  = m.m30;
        m5  = m.m01;
        m6  = m.m11;
        m7  = m.m21;
        m8  = m.m31;
        m9  = m.m02;
        m10 = m.m12;
        m11 = m.m22;
        m12 = m.m32;
        m13 = m.m03;
        m14 = m.m13;
        m15 = m.m23;
        m16 = m.m33;
    }

    public beMatrix4(Matrix4x4 m)
    {
        m1  = m.m00;
        m2  = m.m10;
        m3  = m.m20;
        m4  = m.m30;
        m5  = m.m01;
        m6  = m.m11;
        m7  = m.m21;
        m8  = m.m31;
        m9  = m.m02;
        m10 = m.m12;
        m11 = m.m22;
        m12 = m.m32;
        m13 = m.m03;
        m14 = m.m13;
        m15 = m.m23;
        m16 = m.m33;
    }
};
