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

using BEDummyGoogleVR;
namespace BEDummyGoogleVR {}

public class BESampleCycleMaterialsOnClick : MonoBehaviour {
	BEScene beScene;

    /**
     * Choose from these render material styles.
     */
    [SerializeField]
    public Material[] renderMaterials;

	/// Current rendering material to use.
	int materialIndex = 0;

	/**
	 * Automatically attach to BEUnity on the default MainCamera, and add a listener for onControllerDidPressButton events.
	 */
	void Awake() {
		BridgeEngineUnity.main.onControllerButtonEvent.AddListener(OnButtonEvent);
	}

	void Start() {
		beScene = BEScene.FindBEScene();
		beScene.renderMaterial = renderMaterials[materialIndex];
		Debug.Log("Initial Material: <b>"+beScene.renderMaterial.name+"</b>"); 
	}

	/// Advanced the selected material, returning the newly selected material.
	[ContextMenu("Switch Material")]
	Material SwitchMaterial()
	{
		materialIndex++;
		if (materialIndex >= renderMaterials.Length) {
			materialIndex = 0;
		}

		var material = renderMaterials[materialIndex];
		beScene.renderMaterial = material;
		return material;
	}

	/**
	 * Primary Button should advance which render material is shown, and loop back to None.
	 */
	public void OnButtonEvent(BEControllerButtons current, BEControllerButtons down, BEControllerButtons up) {
		if( down == BEControllerButtons.ButtonPrimary ) {
			var material = SwitchMaterial();
			Debug.Log("Button Pressed, Advancing Material: <b>"+material.name+"</b>");
		}
	}
}
