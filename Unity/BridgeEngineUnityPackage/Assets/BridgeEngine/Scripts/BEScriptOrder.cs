/*
 * This file is part of the Structure SDK.
 * Copyright © 2016 Occipital, Inc. All rights reserved.
 * http://structure.io
 */
 
using System;
using System.Collections.Generic;
using UnityEngine;

using BEDummyGoogleVR;
namespace BEDummyGoogleVR {}

/**
 * Enforce script execution order
 * For example tell Unity to run the script at -10 order by prefacing the MonoBehaviour class with:
 * [BEScriptOrder(-10)]
 */
public class BEScriptOrder:Attribute {
	public int order;

	public BEScriptOrder(int order) {
		this.order = order;
	}
}
