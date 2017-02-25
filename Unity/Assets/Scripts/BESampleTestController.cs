/*
 * This file is part of the Structure SDK.
 * Copyright © 2016 Occipital, Inc. All rights reserved.
 * http://structure.io
 *
 * Test Button Press event interaction by:
 *  - automatically attaching to BEUnity
 *  - adding a listener for onControllerDidPressButton events
 *  - and advancing the renderMaterial
 */

using UnityEngine;
using System.Collections;
using System.Linq;
using System;

public class BESampleTestController : MonoBehaviour {
	BridgeEngineUnity beUnity;

	/**
	 * Automatically attach to BEUnity on the default MainCamera, and add a listener for onControllerDidPressButton events.
	 */
	void Awake() {
		beUnity = GameObject.FindObjectOfType<BridgeEngineUnity>();
		if (beUnity) {
			beUnity.onControllerDidPressButton.AddListener (OnButtonPress);
		} else {
			Debug.LogFormat ("Cannot connect to BridgeEngineUnity controller.", beUnity.renderMaterial); 
		}
	}

	void Start() {
		Debug.LogFormat ("Initial Material: <b>{0}</b>", beUnity.renderMaterial); 
	}

	/**
	 * ButtonPress should advance which render material is shown, and loop back to None.
	 */
	public void OnButtonPress() {
		// Advance the material rendering.
		var materialId = beUnity.renderMaterial;
		materialId++;

		var MaxMaterialID = Enum.GetValues(typeof(BridgeEngineUnity.BERenderMaterial)).Cast<BridgeEngineUnity.BERenderMaterial> ().Max ();
		if (materialId > MaxMaterialID) {
			materialId = BridgeEngineUnity.BERenderMaterial.None;
		}

		Debug.LogFormat ("Button Pressed, Advancing Material: <b>{0}</b>", materialId); 
		beUnity.renderMaterial = materialId;
	}
}
