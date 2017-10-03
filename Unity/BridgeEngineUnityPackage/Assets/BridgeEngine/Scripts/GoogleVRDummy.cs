/*
 * This file is part of the Structure SDK.
 * Copyright © 2016 Occipital, Inc. All rights reserved.
 * http://structure.io
 *
 * When loading either Unity project the runtime scripts detect
 * and deletes GoogleVRDummy.cs
 *
 * This is a stub of GoogleVR classes, and is needed if GoogleVR is not present at install time of
 * the unitypackage. GoogleVR is detected and the script is deleted to clear up the warnings.
 * Because BridgeEngine requires a namespace stub for the GoogleVR related components,
 * automatic removal is needed to make the installed GoogleVR work correctly.
 */
using UnityEngine;
using UnityEngine.EventSystems;
using System;
using System.Collections;

namespace BEDummyGoogleVR
{
	
internal class GoogleVRDummy : MonoBehaviour {}

public class GvrCardboardHelpers {
    public static void SetViewerProfile(String viewerProfileUri) {}    
}

public class GvrViewer : MonoBehaviour
{
	public enum Eye {Right, Left}
	public bool Triggered;
	public Uri DefaultDeviceProfile = null;
    public bool VRModeEnabled = true;
}

[RequireComponent(typeof(LineRenderer))]
public class GvrLaserVisual : MonoBehaviour {
    public const float RETICLE_SIZE_METERS = 0.1f;
    public float maxLaserDistance = 0.75f;
    public Transform Reticle;
    public float ReticleMeshSizeMeters;

    public delegate Vector3 GetPointForDistanceDelegate(float distance);
    public GetPointForDistanceDelegate GetPointForDistanceFunction;

    public void SetDistance(float distance, bool immediate = false) { }
}

    internal class GvrHead
{
	public bool trackPosition = false;
	public bool trackRotation = false;
}

public class GvrPointerManager : MonoBehaviour {
    public static GvrBasePointer Pointer;
}

public class GvrPointerInputModule : UnityEngine.EventSystems.BaseInputModule {
    public override bool ShouldActivateModule() { return false; }
    public override void DeactivateModule() {}
    public override void Process() {}
    public static GvrBasePointer Pointer;
}

public abstract class GvrBasePointer : MonoBehaviour {
    public Transform PointerTransform { get; set; }
    public abstract float MaxPointerDistance { get; }
    public abstract void OnPointerEnter(RaycastResult raycastResult, bool isInteractive);
    public abstract void OnPointerHover(RaycastResult raycastResultResult, bool isInteractive);
    public abstract void OnPointerExit(GameObject targetObject);
    public abstract void OnPointerClickDown();
    public abstract void OnPointerClickUp();
    public abstract void GetPointerRadius(out float enterRadius, out float exitRadius);
    public Vector3 GetPointAlongPointer(float distance) {return Vector3.zero;}
    public virtual float CameraRayIntersectionDistance {
        get {
            return MaxPointerDistance;
        }
    }
    protected virtual void Start() {}
}

[RequireComponent(typeof(Renderer))]
public class GvrReticlePointer : GvrBasePointer
{
    public const float RETICLE_DISTANCE_MAX = 10.0f;
    public override float MaxPointerDistance { get { return RETICLE_DISTANCE_MAX; } }
    public override void OnPointerEnter(RaycastResult raycastResultResult, bool isInteractive) {}
    public override void OnPointerHover(RaycastResult raycastResultResult, bool isInteractive) {}
    public override void OnPointerExit(GameObject previousObject) {}
    public override void OnPointerClickDown() {}
    public override void OnPointerClickUp() {}
    public override void GetPointerRadius(out float enterRadius, out float exitRadius) {enterRadius=0; exitRadius=0;}
}
  
}

