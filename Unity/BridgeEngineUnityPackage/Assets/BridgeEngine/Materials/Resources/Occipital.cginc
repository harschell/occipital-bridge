#include "UnityCG.cginc"

struct appdata
{
	float4 vertex : POSITION;
	float3 normal : NORMAL;
};

struct v2f
{
	float3 normal : NORMAL;
	float4 vertex : SV_POSITION;
	float3 worldPos : TEXCOORD1;
	float4 screenPos : TEXCOORD2;
};

sampler2D _CameraDepthTexture;
fixed _u_alpha_;
half _avoid_k;

v2f vertCollAvoid (appdata v)
{
	v2f o;
	o.worldPos = v.vertex;
	o.vertex = UnityObjectToClipPos(v.vertex);
	o.screenPos = ComputeScreenPos(o.vertex);
	COMPUTE_EYEDEPTH(o.screenPos.z);
	o.normal = normalize(abs(v.normal));
	return o;
}

float3 modGreenLine(float3 worldPos, float _gridSize_, float _radius_)
{
	float d_pos = length(fwidth(worldPos) /_gridSize_ );
	_radius_ *= d_pos;
	_radius_ = clamp(_radius_, 0.01, 0.2);
	float3 _p0_ = frac(worldPos / _gridSize_);
	
	// ramp and reversed ramp to make a bump
	return smoothstep(1. - _radius_, 1., _p0_) + (1. - smoothstep(0., _radius_, _p0_));
}

fixed4 fragGreenColl (v2f i) : SV_Target
{
	fixed4 _majorGridColor_ = fixed4(0.1, 1.0, 0.7, 1.0);
	fixed4 _minorGridColor_ = fixed4(0.1, 1.0, 0.7, 0.8);
	
	float3 _v_normal_ = i.normal;

	// control the falloff of the lines as surface stops being parallel
	float3 powNormal = float3(1.0, 1.0, 1.0) - _v_normal_ * _v_normal_;
	
	// dot these so that we can see the grid when normal dir is ortho to the grid
	float _maj_grid_ = dot( modGreenLine(i.worldPos, 0.15, 2.0), powNormal);
	float _min_grid_ = dot( modGreenLine(i.worldPos, 0.0375, 1.0), powNormal);
	
	float sceneZ = LinearEyeDepth (SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.screenPos)));
	float partZ = i.screenPos.z;
	float diff = saturate (4.0 * (_avoid_k + sceneZ - partZ));
	
	fixed4 _color_ = fixed4(1, 1, 1, 0);
	
	_color_ = (1. - _maj_grid_ - _min_grid_) * _color_ + _maj_grid_ * _majorGridColor_ + _min_grid_ * _minorGridColor_;
	
	_color_.a *= diff * _u_alpha_;
	
	return _color_;
}





float3 modPinkLine(float3 worldPos, float _gridSize_, float _radius_)
{
	// mod to repeat
	float3 p0 = frac(worldPos / _gridSize_);
	// ramp and reversed ramp to make a bump
	return smoothstep(1. - 0.1 - _radius_/2.0 , 1. - _radius_/2.0, p0) + (1. - smoothstep(_radius_/2.0, _radius_/2.0 + 0.1, p0));
}
    
float3 _hsv2rgb_(float3 c)
{
	float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * lerp(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

fixed4 fragPinkColl (v2f i) : SV_Target
{
	float _v_depth_meters_ = i.screenPos.z;
	
	float _squareSize_ = 0.05;
	float3 p0 = modPinkLine(i.worldPos, 0.1, _squareSize_);
	
	float3 _v_normal_ = i.normal;

	// overide grid dimension if the surface is parallel
	// prevents full blue on axis aligned surfaces
	float _n_thresh_ = 0.8;
	
	if (_v_normal_.x > _n_thresh_){ p0.x = 0.0;}
	if (_v_normal_.y > _n_thresh_){ p0.y = 0.0;}
	if (_v_normal_.z > _n_thresh_){ p0.z = 0.0;}
	
	float _inv_grid_ = 1. - clamp(dot(p0, float3(1.0, 1.0, 1.0)), 0.0, 1.0);
	
	float _opacity_ = _u_alpha_ * 0.5 * (0.8 - pow(smoothstep(_avoid_k - 0.8, _avoid_k, _v_depth_meters_), 2.0)) * _inv_grid_;
	
	return fixed4(_hsv2rgb_(float3(-_v_depth_meters_/(_avoid_k*5.0), 1., 1. )), _opacity_);
}