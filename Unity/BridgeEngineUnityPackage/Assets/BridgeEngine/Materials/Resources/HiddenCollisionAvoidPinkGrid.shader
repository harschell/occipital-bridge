Shader "Hidden/Occipital/CollisionAvoidPinkGrid"
{
Properties {
	_u_alpha_("Alpha", Range (0.0, 1.0)) = 1.0
	_avoid_k("Avoid Distance", Range (0.0, 3.0)) = 0.5
}
SubShader {
	Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
	LOD 100

	ZWrite Off
	Blend SrcAlpha OneMinusSrcAlpha 
	
	Pass
	{
		CGPROGRAM
		#include "Occipital.cginc"
		#pragma vertex vertCollAvoid
		#pragma fragment fragPinkColl
		ENDCG
	}
}
}
