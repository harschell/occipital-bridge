/*
 * This file is part of the Structure SDK.
 * Copyright © 2016 Occipital, Inc. All rights reserved.
 * http://structure.io
 *
 * Loss of Tracking Feedback. Fades in a notice to look back at scene.
 */

using UnityEngine;
using UnityEngine.UI;
using System.Collections;

using BEDummyGoogleVR;
namespace BEDummyGoogleVR {}

[RequireComponent(typeof(CanvasGroup))]
public class BETrackingUI : MonoBehaviour
{
	/**
	 * Track to the target alpha, incrementally adjusting the canvas transparency up or down.
	 */
    float targetAlpha = 0;

	void Start()
	{
		if (beUnity == null)
			beUnity = BridgeEngineUnity.main;
	}

	/**
	 * Parent level "LostTrackingCanvas" that we need to enable to see the canvas hierarchy.
	 */
	Canvas lostTrackingCanvas;

	/**
	 * This component's canvasGroup, that we fade in to show the warning.
	 */
	CanvasGroup canvasGroup;

	/**
	 * Cache of scene's main reticlePointer
	 */
	GvrReticlePointer reticlePointer;

	/**
	 * Only show/hide reticlePointer when its visibility changes
	 * within the context of this class.
	 */
	bool _reticlePointerVisible;
	bool reticlePointerVisible {
		set {
			if( _reticlePointerVisible != value && reticlePointer != null ) {
				_reticlePointerVisible = value;
				Renderer reticleRenderer = reticlePointer.GetComponent<Renderer>();
				reticleRenderer.enabled = value;
			}
		}
	}

	/**
	 * Make the tracking state be driven off BridgeEngineUnity dependency injection,
	 * Automatically register our TrackingStateChanged callback with BridgeEngineUnity.
	 */
	[SerializeField] BridgeEngineUnity _beUnity;
	public BridgeEngineUnity beUnity {
		set {
			if (_beUnity) {
				// Disconnect listener.
				_beUnity.onPoseAccuracyChanged.RemoveListener (TrackingStateChanged);
				TrackingStateChanged (BETrackerPoseAccuracy.Uninitialized);
			}

			_beUnity = value;

			if (_beUnity) {
				// Attach new listener.
				beUnity.onPoseAccuracyChanged.AddListener (TrackingStateChanged);

				// Initialize with current tracking state.
				TrackingStateChanged (beUnity.TrackerPoseAccuracy());

				// Jump directly to current state's alpha setting.
				canvasGroup.alpha = targetAlpha;
			}
		}
		get {
			return _beUnity;
		}
	}

    public void TrackingStateChanged(BETrackerPoseAccuracy state)
    {
		if( state == BETrackerPoseAccuracy.NotAvailable
		 || state == BETrackerPoseAccuracy.Uninitialized )
		{
			targetAlpha = 1;
		} else {
			targetAlpha = 0;
		}
    }

	void Awake()
	{
		canvasGroup = GetComponent<CanvasGroup>();
		lostTrackingCanvas = GameObject.Find("LostTrackingCanvas").GetComponent<Canvas>();
		reticlePointer = GameObject.FindObjectOfType<GvrReticlePointer>();
		if( reticlePointer ) {
			Renderer reticleRenderer = reticlePointer.GetComponent<Renderer>();
			_reticlePointerVisible = reticleRenderer.enabled;
		}
	}
	
	void Update ()
    {
		var canvasGroup = GetComponent<CanvasGroup>();
		var alpha = Mathf.MoveTowards(canvasGroup.alpha, targetAlpha, Time.deltaTime * 3.0f);
        canvasGroup.alpha = alpha;
		lostTrackingCanvas.enabled = alpha > 0;

		// Show/Hide specifically the Gaze Reticle, as the other pointer isn't stuck in your face.
		if( reticlePointer != null ) {
			reticlePointerVisible = (alpha < .25);
		}
	}
}
