Shader "Custom/PostRenderColor"
{
    SubShader
    {
        Tags { "RenderType"="Transparent" }
        LOD 200
		Pass
		{

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex:POSITION;
				float2 uv:TEXCOORD;
			};

			struct v2f
			{
				float4 pos:POSITION;
				float2 uv:TEXCOORD;
				float eye_depth : TEXCOORD1;
				float4 screenPos:TEXCOORD2;
			};
			sampler2D _CameraDepthTexture;
			float4 _Color;
			float _Scale;
			v2f vert(appdata v)
			{
				v2f o;
				v.vertex *= _Scale;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				o.screenPos = ComputeScreenPos(o.pos);//获取顶点在屏幕上的位置
				COMPUTE_EYEDEPTH(o.eye_depth);//获取顶点的深度，如果不把顶点着色器的参数命名为v会报错
				return o;
			}

			float4 frag(v2f i):SV_TARGET
			{
				float screenZ = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture,UNITY_PROJ_COORD(i.screenPos)));//获取相机渲染出的深度
				float4 color = _Color;
				clip(screenZ- i.eye_depth);//将相机渲染出的深度和自身深度对比
				return color;
			}
			ENDCG
		}
    }
    FallBack "Diffuse"
}
