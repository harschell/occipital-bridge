Shader "Hidden/Occipital/LiveCamProjection"
{
	SubShader
	{
		Tags { "RenderType"="Transparent" }
		LOD 100
		Blend SrcAlpha OneMinusSrcAlpha

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float4 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 uv : TEXCOORD1;
				float4 vertex : SV_POSITION;
			};

			sampler2D _u_CameraTex;
			float4x4 _cameraProjMatrix;

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = mul(mul(_cameraProjMatrix, unity_ObjectToWorld), v.vertex);
				return o;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = 0;
				if (i.uv.w > 0.0)
				{
					bool isVisible = i.uv.x >= 0.0 && i.uv.x <= i.uv.w && i.uv.y >= 0.0 && i.uv.y <= i.uv.w;
					// Weight of this keyframe. 0.0 if not visible or out of bounds, 1.0 otherwise.
					float w0 = float(isVisible);

					col = tex2Dproj(_u_CameraTex, i.uv);
					col.a = w0;// * _u_alpha_;
				} else {
					col = fixed4(i.colorWithDiffuse);
				}

				return col;
			}
			ENDCG
		}
	}
}
