Shader "Custom/Add"
{
    Properties
    {
		_MainTex("Albedo (RGB)", 2D) = "white" {}
		//_AddTex("Add",2D) = "white"{}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
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
				float4 vertex:POSITION;
				float2 uv:TEXCOORD;
			};
			sampler2D _MainTex;
			sampler2D _AddTex;
			v2f vert(appdata v)
			{
				v2f o;
				o.uv = v.uv;
				o.vertex = UnityObjectToClipPos(v.vertex);
				return o;
			}

			float4 blend(float4 main, float4 add)
			{
				float4 color = float4(0, 0, 0, 1);
				float l = max(max(main.r, main.g), main.b);
				color.r = main.r*(1 - add.a*saturate(main.r - add.a)) + add.r;
				color.g = main.g*(1 - add.a*saturate(main.g - add.a)) + add.g;
				color.b = main.b*(1 - add.a*saturate(main.b - add.a)) + add.b;
				return color;
			}

			float4 frag(v2f i):SV_TARGET
			{
				float4 main = tex2D(_MainTex,i.uv);
				float4 add = tex2D(_AddTex,i.uv);
				float l = max(max(main.r, main.g), main.b);
				main = blend(main, add);
				
				return main;
			}
			ENDCG
		}
    }
    FallBack "Diffuse"
}
