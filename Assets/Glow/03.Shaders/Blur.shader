Shader "Custom/GlowBlur"
{
    Properties
    {
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
		_Width("宽度",Float) = 5
		_SamplingIteration("采样次数", Int) = 3
		_Strength("强度",Range(0,2)) = 0.2
    }
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
				float2 texcoord:TEXCOORD;
			};
			struct v2f
			{
				float4 vertex:POSITION;
				float2 uv:TEXCOORD;
				float4 uv01 : TEXCOORD1;	//一个vector4存储两个纹理坐标
				float4 uv23 : TEXCOORD2;	//一个vector4存储两个纹理坐标
				float4 uv45 : TEXCOORD3;	//一个vector4存储两个纹理坐标
			};
			sampler2D _MainTex;
			float4 _MainTex_TexelSize;
			float _Width;
			float _SamplingIteration;
			float _Strength;
			float2 _Dir;
			v2f vert(appdata v)
			{
				v2f o;
				o.uv = v.texcoord;
				o.vertex = UnityObjectToClipPos(v.vertex);
				float4 _offsets = float4(_Width, _Width, 0, 0);
				
				//计算一个偏移值，offset可能是（0，1，0，0）也可能是（1，0，0，0）这样就表示了横向或者竖向取像素周围的点
				_offsets *= _MainTex_TexelSize.xyxy;
				_offsets.xy *= _Dir;
				//由于uv可以存储4个值，所以一个uv保存两个vector坐标，_offsets.xyxy * float4(1,1,-1,-1)可能表示(0,1,0-1)，表示像素上下两个
				//坐标，也可能是(1,0,-1,0)，表示像素左右两个像素点的坐标，下面*2.0，*3.0同理
				o.uv01 = v.texcoord.xyxy + _offsets.xyxy * float4(1, 1, -1, -1);
				o.uv23 = v.texcoord.xyxy + _offsets.xyxy * float4(1, 1, -1, -1) * 2.0;
				o.uv45 = v.texcoord.xyxy + _offsets.xyxy * float4(1, 1, -1, -1) * 3.0;
				return o;
			}

			float4 frag(v2f i) :SV_TARGET
			{
				fixed4 color = fixed4(0, 0, 0, 0);
				//将像素本身以及像素左右（或者上下，取决于vertex shader传进来的uv坐标）像素值的加权平均
				color += 0.3 * tex2D(_MainTex, i.uv);
				color += 0.2 * tex2D(_MainTex, i.uv01.xy);
				color += 0.2 * tex2D(_MainTex, i.uv01.zw);
				color += 0.10 * tex2D(_MainTex, i.uv23.xy);
				color += 0.10 * tex2D(_MainTex, i.uv23.zw);
				color += 0.05 * tex2D(_MainTex, i.uv45.xy);
				color += 0.05 * tex2D(_MainTex, i.uv45.zw);
				float4 main = tex2D(_MainTex, i.uv);
				color *= _Strength;
				return color;
			}
			ENDCG
		}
    }
    FallBack "Diffuse"
}
