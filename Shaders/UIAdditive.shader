/// original by mob-sakai
/// Universal Rendering Pipeline (urp) ported by shaochun

Shader "UI/Additive"
{
	Properties
	{
		_BaseMap ("Sprite Texture", 2D) = "white" {}
		_BaseColor ("Tint", Color) = (1,1,1,1)
		_StencilComp ("Stencil Comparison", Float) = 8
		_Stencil ("Stencil ID", Float) = 0
		_StencilOp ("Stencil Operation", Float) = 0
		_StencilWriteMask ("Stencil Write Mask", Float) = 255
		_StencilReadMask ("Stencil Read Mask", Float) = 255
		_ColorMask ("Color Mask", Float) = 15
		_ClipRect ("Clip Rect", Vector) = (-32767, -32767, 32767, 32767)
	}
	SubShader
	{
		Tags
		{ 
			"Queue"="Transparent" 
			"IgnoreProjector"="True" 
			"RenderType"="Transparent" 
			"PreviewType"="Plane"
			"CanUseSpriteAtlas"="True"
			"RenderPipeline" = "UniversalPipeline"
		}
		Stencil
		{
			Ref [_Stencil]
			Comp [_StencilComp]
			Pass [_StencilOp] 
			ReadMask [_StencilReadMask]
			WriteMask [_StencilWriteMask]
		}
		Cull Off
		Lighting Off
		ZWrite Off
		ZTest [unity_GUIZTestMode] 
		Fog { Mode Off }
		Blend One One
		ColorMask [_ColorMask]
		Pass
		{
		HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile __ UNITY_UI_CLIP_RECT
			#pragma multi_compile __ UNITY_UI_ALPHACLIP
			#include "Packages/com.unity.render-pipelines.universal/Shaders/UnLitInput.hlsl"
			struct appdata_t
			{
				float4 positionOS : POSITION;
				float4 color	  : COLOR;
				float2 texcoord   : TEXCOORD0;
			};
			struct v2f
			{
				float4 vertex        : SV_POSITION;
				half4  color         : COLOR;
				half2  texcoord      : TEXCOORD0;  
				float4 worldPosition : TEXCOORD1;
				float4 mask			 : TEXCOORD2;
			};
			float4    _ClipRect;
			float     _MaskSoftnessX;
			float     _MaskSoftnessY;
			v2f vert(appdata_t IN)
			{
				v2f OUT = (v2f)0;
				VertexPositionInputs vertexInput = GetVertexPositionInputs(IN.positionOS.xyz);
				OUT.worldPosition.xyz = vertexInput.positionWS;
				OUT.worldPosition.w   = 1.0;
				OUT.vertex            = vertexInput.positionCS;
				OUT.texcoord = TRANSFORM_TEX(IN.texcoord, _BaseMap);
				#ifdef UNITY_HALF_TEXEL_OFFSET
					OUT.vertex.xy += (_ScreenParams.zw - 1.0) * float2(-1,1);
				#endif
				OUT.color = IN.color * _BaseColor;
				#if UNITY_UI_CLIP_RECT
					float2 pixelSize = OUT.vertex.w;
					float4 clampedRect = clamp(_ClipRect, -2e10, 2e10);
					OUT.mask = float4(  OUT.vertex.xy * 2 - clampedRect.xy - clampedRect.zw, 
										0.25 / (0.25 * half2(_MaskSoftnessX, _MaskSoftnessY) + pixelSize.xy)
									 );
				#endif
				return OUT;
			}
			half4 frag(v2f IN) : SV_Target
			{
				half4 color = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.texcoord) * IN.color;
				#if UNITY_UI_CLIP_RECT
					half2 m = saturate((_ClipRect.zw - _ClipRect.xy - abs(IN.mask.xy)) * IN.mask.zw);
					color.a *= m.x * m.y;
				#endif
				color.rgb *= color.a;
				#ifdef UNITY_UI_ALPHACLIP
					clip (color.a - 0.01);
				#endif
				return color;
			}
		ENDHLSL
		}
	}
}