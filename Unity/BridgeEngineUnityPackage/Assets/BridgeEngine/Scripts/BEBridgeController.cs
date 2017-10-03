/*
 * This file is part of the Structure SDK.
 * Copyright © 2016 Occipital, Inc. All rights reserved.
 * http://structure.io
 *
 * BEBridgeController listens for when a BridgeController is connected,
 * and provides the pointer input control for the GvrPointerInputModule.
 * The controller state, buttons down, trigger held, touch location on the touch pad,
 * and orientation is visually represented by the BridgeController.prefab.
 *
 * USAGE:
 *   Add BridgeEngine/Prefabs/BridgeController.prefab - put at root of your scene
 *   Add GoogleVR/Prefabs/UI/GvrEventSystem.prefab - put at root of your scene
 *   Add GoogleVR/Prefabs/UI/GvrReticlePointer.prefab - add under your Main Camera
 */
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

using BEDummyGoogleVR;
namespace BEDummyGoogleVR {}

[BEScriptOrder(10)]
[RequireComponent(typeof(BELaserPointer))]
public class BEBridgeController : MonoBehaviour {
	public Material activatedMaterial;

	BridgeEngineUnity beUnity;
	GameObject orientationFixNode;
	GameObject controllerReticle;
	BELaserPointer laserPointer;
	LineRenderer lineRenderer;
	GvrLaserVisual laserVisual;

	Material appButtonMaterial;
	Material homeButtonMaterial;
	Material triggerButtonMaterial;
	Material touchButtonMaterial;

	Transform appButton;
	Transform homeButton;
	Transform trigger;
	Transform touch;

	// Use this for initialization
	void Start () {
		orientationFixNode = transform.Find("OrientationFix").gameObject;
		controllerReticle = transform.Find("Reticle").gameObject;
		laserPointer = GetComponent<BELaserPointer>();
		lineRenderer = GetComponent<LineRenderer>();
		laserVisual = GetComponent<GvrLaserVisual>();

		beUnity = BridgeEngineUnity.main;
		if (beUnity) {
			beUnity.onControllerDidConnect.AddListener(OnConnectionChanged);
			beUnity.onControllerDidDisconnect.AddListener(OnConnectionChanged);
			beUnity.onControllerMotionEvent.AddListener(OnMotionEvent);
			beUnity.onControllerButtonEvent.AddListener(OnButtonEvent);
			beUnity.onControllerTouchEvent.AddListener(OnTouchEvent);
		}

		appButton = transform.Find("OrientationFix/AppButton");
		appButtonMaterial = appButton.GetComponent<MeshRenderer>().material;
		homeButton = transform.Find("OrientationFix/HomeButton");
		homeButtonMaterial = homeButton.GetComponent<MeshRenderer>().material;
		trigger = transform.Find("OrientationFix/Trigger");
		triggerButtonMaterial = trigger.GetComponent<MeshRenderer>().material;
		touch = transform.Find("OrientationFix/TrackPad/Touch");
		touchButtonMaterial = touch.GetComponent<MeshRenderer>().material;

		OnConnectionChanged();
	}
	
	// Update is called once per frame
	void Update () {
		if( beUnity == null ) {return;}
	}

	void OnConnectionChanged() {
		GvrReticlePointer reticlePointer = null;

		Transform mainReticleTransform = Camera.main.transform.Find("GvrReticlePointer");
		if( mainReticleTransform != null ) {
			reticlePointer = mainReticleTransform.GetComponent<GvrReticlePointer>();
		}

		if( beUnity.isBridgeControllerConnected() ) {
			GvrPointerInputModule.Pointer = laserPointer;
			orientationFixNode.SetActive( true );
			controllerReticle.SetActive( true );
			laserPointer.enabled = true;
			lineRenderer.enabled = true;
			laserVisual.enabled = true;
			
			if( reticlePointer ) {
				mainReticleTransform.gameObject.SetActive(false);
				reticlePointer.enabled = false;
			}
		} else {
			// Disconnected: Turn off controller, and hand back to reticle.
			orientationFixNode.SetActive( false );
			controllerReticle.SetActive( false );
			laserPointer.enabled = false;
			lineRenderer.enabled = false;
			laserVisual.enabled = false;

			if( reticlePointer ) {
				mainReticleTransform.gameObject.SetActive(true);
				reticlePointer.enabled = true;
				GvrPointerInputModule.Pointer = reticlePointer;
			}
		}
	}

	void OnMotionEvent( Vector3 position, Quaternion orientation ) {
		transform.position = position;
		transform.rotation = orientation;
	}

	void OnButtonEvent( BEControllerButtons buttons, BEControllerButtons buttonsDown, BEControllerButtons buttonsUp ) {
		appButton.GetComponent<MeshRenderer>().material = (buttons & BEControllerButtons.ButtonSecondary) > 0 ? activatedMaterial : appButtonMaterial;
		homeButton.GetComponent<MeshRenderer>().material = (buttons & BEControllerButtons.ButtonHomePower) > 0 ? activatedMaterial : homeButtonMaterial;
		trigger.GetComponent<MeshRenderer>().material = (buttons & BEControllerButtons.ButtonPrimary) > 0 ? activatedMaterial : triggerButtonMaterial;

		if((buttons & BEControllerButtons.ButtonTouchContact) > 0) {
			touch.gameObject.SetActive(true);
			touch.GetComponent<MeshRenderer>().material = (buttons & BEControllerButtons.ButtonTouchpad) > 0 ? activatedMaterial : touchButtonMaterial;
		} else {
			touch.gameObject.SetActive(false);
		}
	}

	void OnTouchEvent( Vector2 position, BEControllerTouchStatus touchStatus ) {
		Vector3 touchPosition = touch.localPosition;
		touchPosition.x = -position.x;
		touchPosition.y = position.y;
		touch.localPosition = touchPosition;
	}
}
