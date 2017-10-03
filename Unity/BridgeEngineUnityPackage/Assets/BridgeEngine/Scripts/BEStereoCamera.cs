/*
 * This file is part of the Structure SDK.
 * Copyright © 2017 Occipital, Inc. All rights reserved.
 * http://structure.io
 *
 * Provides the stereo camera rendering infrastructure at runtime.
 * Intercepts the mainCamera rendering, so we can manually drive the left/right
 * stereo pair and lens distortion camera pair rendering.
 */
using UnityEngine;
using System.Collections.Generic;

using BEDummyGoogleVR;
namespace BEDummyGoogleVR {}

public class BEStereoCamera : MonoBehaviour {
    private Camera mainCamera;

    public Camera leftCamera;
    public Camera rightCamera;
    public Camera lensDistortionEffectLeftCamera;
    public Camera lensDistortionEffectRightCamera;

    private int cullingMask;
    private List<Canvas> mainScreenCanvas;

    void Awake() {
        mainCamera = GetComponent<Camera>();

        // Find all the screen space overlays, and pull them into our stereo rendering control.
        var allCanvases = GameObject.FindObjectsOfType<Canvas>();
        var nCanvas = allCanvases.Length;
        mainScreenCanvas = new List<Canvas>();
        for( int i=0; i<nCanvas; i++) {
            var canvas = allCanvases[i];
            if( canvas.renderMode == RenderMode.ScreenSpaceOverlay
            && canvas.enabled == true
            && canvas.worldCamera == null ) {
                mainScreenCanvas.Add(canvas);
                canvas.renderMode = RenderMode.ScreenSpaceCamera;
                canvas.enabled = false;
            }
        }
    }

    void OnPreCull() {
        cullingMask = mainCamera.cullingMask;
        mainCamera.cullingMask = 0;
    }

    void OnPostRender() {
        mainCamera.cullingMask = cullingMask;

        // Turn all the canvas overlays on, for rendering into each eye.
        var nCanvas = mainScreenCanvas.Count;
        for( int i=0; i<nCanvas; i++ ) {
            var canvas = mainScreenCanvas[i];
            canvas.enabled = true;
        }

        RenderCamera(leftCamera, lensDistortionEffectLeftCamera);
        RenderCamera(rightCamera, lensDistortionEffectRightCamera);

        // Turn all the canvas off again.
        for( int i=0; i<nCanvas; i++ ) {
            var canvas = mainScreenCanvas[i];
            canvas.enabled = false;
        }
    }

    /// Prepare the stereo cameras as a replacemetn for the main camera.
    void Start() {
        // Prevent AllowMSAA which results in black rendering.
        Camera.main.allowMSAA = false;
        
        leftCamera = CreateEyeCamera("Left Eye");
        lensDistortionEffectLeftCamera = CreateLensDistortionEffectCamera("Left Lens Distortion", BEEyeSide.Left, leftCamera);

        rightCamera = CreateEyeCamera("Right Eye");
        lensDistortionEffectRightCamera = CreateLensDistortionEffectCamera("Right Lens Distortion", BEEyeSide.Right, rightCamera);
    }

    // Update the tracking and projection of the cameras
    bool firstShot = true;
    internal void UpdateStereoSetup( BEStereoSetup stereoSetup ) {
        // Get the Camera FOV setting and print it.
        if( firstShot ) {
            firstShot = false;
            float fov = calculateFovFromMatrix(stereoSetup.leftProjection.ToMatrix());
            Debug.Log("Left Camera FOV: " + fov);
        }

        leftCamera.transform.SetPositionAndRotation(stereoSetup.leftPosePosition.ToVector3(), stereoSetup.leftPoseRotation.ToQuaternion());
        leftCamera.projectionMatrix = stereoSetup.leftProjection.ToMatrix();

        rightCamera.transform.SetPositionAndRotation(stereoSetup.rightPosePosition.ToVector3(), stereoSetup.rightPoseRotation.ToQuaternion());
        rightCamera.projectionMatrix = stereoSetup.rightProjection.ToMatrix();
    }
    //  ------------------ Private Methods --------------

    private float calculateFovFromMatrix( Matrix4x4 mat ){
        float a = mat[0];
        float b = mat[5];
        float c = mat[10];
        float d = mat[14];
        
        float aspect_ratio = b / a;
        
        float k = (c - 1.0f) / (c + 1.0f);
        float clip_min = (d * (1.0f - k)) / (2.0f * k);
        float clip_max = k * clip_min;
        
        float RAD2DEG = 180.0f / 3.14159265358979323846f;
        float fov = RAD2DEG * (2.0f * (float)Mathf.Atan(1.0f / b));
        return fov;
    }

    /// Convenience to create an Eye Camera for rendering into.
    private Camera CreateEyeCamera( string name ) {
        var cameraGO = new GameObject();
        var camera = cameraGO.AddComponent<Camera>();

        camera.CopyFrom(mainCamera);
        camera.name = name;
        camera.depth = -1;
        camera.enabled = false;

        camera.clearFlags = CameraClearFlags.SolidColor;
        camera.backgroundColor = Color.black;
        return camera;
    }

    // Set up a lens distortion camera to manually render a single mesh - inside LensDistortionMesh.OnPostRender
    private Camera CreateLensDistortionEffectCamera( string gameObjectName, BEEyeSide side, Camera eyeCamera ) {
        var lensCameraGO = new GameObject(gameObjectName);
        var lensCamera = lensCameraGO.AddComponent<Camera>();

        float halfPixelOffset = 1.0f / (2 * mainCamera.pixelWidth);
        if( side == BEEyeSide.Left ) {
            lensCamera.rect = new Rect(0.0f, 0.0f, 0.5f - halfPixelOffset, 1.0f);
        } else {
            lensCamera.rect = new Rect(0.5f + halfPixelOffset, 0.0f, 0.5f - halfPixelOffset, 1.0f);
        }

        lensCamera.cullingMask = 0;
        lensCamera.clearFlags = CameraClearFlags.SolidColor;
        lensCamera.backgroundColor = Color.black;
        lensCamera.allowHDR = false;
        lensCamera.allowMSAA = false;
        lensCamera.renderingPath = RenderingPath.VertexLit;
        lensCamera.useOcclusionCulling = false;
        lensCamera.depth = eyeCamera.depth + 1.0f; // after eyeCamera
        lensCamera.enabled = false; // manually triggered rendering.

        eyeCamera.targetTexture = new RenderTexture(mainCamera.pixelWidth/2, mainCamera.pixelHeight, 32, RenderTextureFormat.Default);

        var lensDistortionMesh = lensCamera.gameObject.AddComponent<LensDistortionMesh>();
        lensDistortionMesh.sourceCamera = eyeCamera;
        lensDistortionMesh.side = side;
        lensDistortionMesh.CreateMesh();

        return lensCamera;
    }

    private void RenderCamera( Camera eyeCamera, Camera lensCamera ) {
        eyeCamera.cullingMask = cullingMask;

        // Set the canvas to render into our eyeCamera.
        var nCanvas = mainScreenCanvas.Count;
        for( int i=0; i<nCanvas; i++ ) {
            var canvas = mainScreenCanvas[i];
            canvas.worldCamera = eyeCamera;
        }
        Canvas.ForceUpdateCanvases();

        // Render the eyeCamera
        eyeCamera.Render();

        // Set the canvas back to normal.
        for( int i=0; i<nCanvas; i++ ) {
            var canvas = mainScreenCanvas[i];
            canvas.worldCamera = null;
        }

        if( lensCamera != null ) {
            lensCamera.Render();
        }
    }
}