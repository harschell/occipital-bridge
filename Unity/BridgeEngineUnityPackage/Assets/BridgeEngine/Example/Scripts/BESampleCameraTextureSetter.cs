/*
 * This file is part of the Structure SDK.
 * Copyright © 2016 Occipital, Inc. All rights reserved.
 * http://structure.io
 *
 */

using UnityEngine;
using UnityEngine.UI;
using System.Collections;
using System;

[RequireComponent(typeof(RawImage))]
public class BESampleCameraTextureSetter : MonoBehaviour {
	BridgeEngineUnity beUnity;
	RawImage thisRawImage;
	/**
	 * Automatically attach to BEUnity on the default MainCamera, and add a listener for onControllerDidPressButton events.
	 */
	void Awake() {
		thisRawImage = GetComponent<RawImage>();
		beUnity = BridgeEngineUnity.main;
		if (beUnity == null) {
			Debug.LogWarning("Cannot connect to BridgeEngineUnity controller.");
		}
	}

	void Update() {
		thisRawImage.texture = beUnity.cameraTexture;
	}
}
