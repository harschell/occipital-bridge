/*
 * This file is part of the Structure SDK.
 * Copyright © 2016 Occipital, Inc. All rights reserved.
 * http://structure.io
 *
 * Simulates camera movement and basic controller button events
 * when using only the keyboard and mouse.
 *
 * USAGE:
 *  Simulator functionality is part of BridgeEngineUnity.cs, and started only in Unity Editor.
 *  Use keyboard WASD for movement and QE for up/down, and mouse to look around.
 *  Primary mouse click is the primary bridge controller button.
 * 
 *  Tracking Pose Accuracy can be toggled using the numbers:
 *  1 - No Pose Available (3-DoF tracking fallback)
 *  2 - Low quality  (6-DoF tracking, but showing warning indicator)
 *  3 - High quality  (normal 6-DoF tracking, no warnings)
 */
#if UNITY_EDITOR

using UnityEngine;

using BEDummyGoogleVR;
namespace BEDummyGoogleVR {}

class BESimulatorPoseController
{
    // Public Assignable Properties
    public BridgeEngineUnityInterop.trackerUpdateInterop trackerUpdateCallback;
    public BridgeEngineUnityInterop.controllerMotionInterop controllerMotionEventCallback;
    public BridgeEngineUnityInterop.controllerButtonsInterop controllerButtonEventCallback;
    public BridgeEngineUnityInterop.controllerTouchInterop controllerTouchEventCallback;

    /**
     * Movement speed in meters per second
     */
    public float speed = 1.5f;

    /**
     * Mouse aim sensitivity
     */
    public float sensitivity = 3f;

    /**
     * Start at the middle, at 1.5m high.
     */
    public BESimulatorPoseController()
    {
        this.position = new Vector3(0, 1.5f, 0);
        this.yaw = 0;
        this.pitch = 0;
        
        trackerUpdateInterop.trackerPoseAccuracy = BETrackerPoseAccuracy.High;
    }

    // ---- Tracker Updating ----
    BETrackerUpdateInterop trackerUpdateInterop = new BETrackerUpdateInterop();
    private BETrackerPoseAccuracy trackerPoseAccuracy;
    private Vector3 position;
    private float yaw;
    private float pitch;

    public void StartWithMainCameraTransform( Transform mainCamTransform ) {
        position = mainCamTransform.position;
        yaw = mainCamTransform.eulerAngles.y;
        pitch = mainCamTransform.eulerAngles.x;
    }

    internal void UpdateTracker() 
    {
        Quaternion orientation;
        
        var leftShiftButtonPressed = Input.GetKey(KeyCode.LeftShift);
        if (leftShiftButtonPressed) 
        {
            float mouseX = Input.GetAxisRaw("Mouse X");
            float mouseY = Input.GetAxisRaw("Mouse Y");
            
            float upDown = (Input.GetKey(KeyCode.E)?1:0) - (Input.GetKey(KeyCode.Q)?1:0);
            float fwdBack = (Input.GetKey(KeyCode.W)?1:0) - (Input.GetKey(KeyCode.S)?1:0);
            float leftRight = (Input.GetKey(KeyCode.D)?1:0) - (Input.GetKey(KeyCode.A)?1:0);
            
            yaw += mouseX * sensitivity;
            yaw = Mathf.Repeat(yaw, 360);
            pitch += -mouseY * sensitivity;
            pitch = Mathf.Clamp(pitch, -80, 80);
            
            orientation = Quaternion.Euler(pitch, yaw, 0.0f);
            Vector3 worldForward = orientation * Vector3.forward;
            Vector3 worldRight = orientation * Vector3.right;
            Vector3 worldUp = Vector3.up;

            position += worldForward * (Time.deltaTime * fwdBack * speed);
            position += worldRight * (Time.deltaTime * leftRight * speed);
            position += worldUp * (Time.deltaTime * upDown * speed);

            UpdateButtonState(Input.GetMouseButton(0));

            Cursor.lockState = CursorLockMode.Locked;
        }
        else 
        {
            Cursor.lockState = CursorLockMode.None;
            orientation = Quaternion.Euler(pitch, yaw, 0.0f);
            UpdateButtonState(false);
        }

        trackerUpdateInterop.rot = new beVector4(orientation);
        trackerUpdateInterop.pos = new beVector3(position);
        
        trackerUpdateInterop.cameraTextureInfo.textureId = 0;
        trackerUpdateInterop.cameraTextureInfo.height = 0;
        trackerUpdateInterop.cameraTextureInfo.width = 0;
        
        var eyeDistance = 0.064f;  // Mean IPD for a male is 64mm wide
        var halfEyeDistance = eyeDistance * 0.5f;
        var right = orientation * Vector3.right * halfEyeDistance;

        trackerUpdateInterop.stereoSetup.leftPosePosition = new beVector3(position - right);
        trackerUpdateInterop.stereoSetup.rightPosePosition = new beVector3(position + right);

        trackerUpdateInterop.stereoSetup.leftPoseRotation = new beVector4(orientation);
        trackerUpdateInterop.stereoSetup.rightPoseRotation = new beVector4(orientation);

        float aspect = Camera.main.pixelWidth / Camera.main.pixelHeight;
        // if( BridgeEngineUnityInterop.be_isStereoMode() ) {
        //    aspect *= 0.5f; // Stereo is half-aspect.
        // }

        float fov = 78.57858f; // Derived FOV from actual on-device measure of camera FoV.
        var projection = Matrix4x4.Perspective(fov, aspect, Camera.main.nearClipPlane, Camera.main.farClipPlane);
        trackerUpdateInterop.stereoSetup.leftProjection = new beMatrix4(projection);
        trackerUpdateInterop.stereoSetup.rightProjection = new beMatrix4(projection);

        UpdatePoseAccuracy();

        trackerUpdateCallback(trackerUpdateInterop);
    }

    internal void UpdatePoseAccuracy()
    {
        if (Input.GetKey(KeyCode.Alpha1)) 
        {
            trackerUpdateInterop.trackerPoseAccuracy = BETrackerPoseAccuracy.NotAvailable;
        }
        else if (Input.GetKey(KeyCode.Alpha2))
        {
            trackerUpdateInterop.trackerPoseAccuracy = BETrackerPoseAccuracy.Low;
        }
        else if (Input.GetKey(KeyCode.Alpha3))
        {
            trackerUpdateInterop.trackerPoseAccuracy = BETrackerPoseAccuracy.High;
        }
    }

    // ---- Button State Tracking ----
    private bool currentButtonState = false;

    /**
     * Track the current button state and report button events to the callbacks.
     */
    void UpdateButtonState(bool button) {
        if(currentButtonState == button) return;
        if(controllerButtonEventCallback == null) return;

        currentButtonState = button;
        if( button )
        {
            controllerButtonEventCallback(BEControllerButtons.ButtonPrimary, BEControllerButtons.ButtonPrimary, 0 );
        } else {
            controllerButtonEventCallback(0, 0, BEControllerButtons.ButtonPrimary);
        }
    }
}
#endif
