// This work is licensed under the Creative Commons Attribution-NonCommercial 4.0 International License.
// To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/4.0/ or send a letter to
// Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Custom/FloorShaderIsland"
{
    Properties
    {
        _Color("Color", Color) = (1,1,1,1)
        _Color2("Color2", Color) = (1,1,1,1)
        _OffsetTex("Offset Tex", 2d) = "white" {}
        _StoneColor("Stone Color", Color) = (1,1,1,1)
        _StoneEdge("Stone Edge", Color) = (1,1,1,1)
        _EdgeColor("Edge Color", Color) = (1,1,1,1)
        _EdgeThickness("Edge Thickness", Float) = 0.1
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _SdfTex("Sdf Tex", 2D) = "white" {}
        _Glossiness("Smoothness", Range(0,1)) = 0.5
        _Metallic("Metallic", Range(0,1)) = 0.0

        _WaterColor("Water Color", Color) = (1,1,1,1)
        _OutlineWidth("Outline Width", Float) = 1
        _OutlineColor("Outline Color", Color) = (1,1,1,1)
        _FaceColor("Face Color", Color) = (1,1,1,1)
        _Rect("Rect", Vector) = (0,0,0,0)
        _IslandDownsize("Island Downsize", Float) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Unlit

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;
        sampler2D _OffsetTex;
        sampler2D _StoneTex;
        sampler2D _SdfTex;

        struct Input
        {
            float2 uv_MainTex;
            float3 worldPos;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;
        fixed4 _Color2;
        fixed4 _EdgeColor;
        fixed4 _StoneColor;
        fixed4 _StoneEdge;
        float _Scaling;

        float _WorldSizeIncrease;


        float4 _Rect;
        float4 _StoneRect;

        float _EdgeThickness;
        float4 _StoneRectOffset;
        float _StoneEdgeThickness;

        float _OutlineWidth;
        float4 _OutlineColor;
        float4 _FaceColor;
        float4 _WaterColor;

        float _IslandDownsize;

        fixed4 LightingUnlit(SurfaceOutput s, fixed3 lightDir, fixed atten)
        {
            fixed4 c;

            c.rgb = s.Albedo;
            c.a = s.Alpha;

            c.rgb *= atten;

            return c * _LightColor0;
        }

        float udRoundBox(float3 p, float3 b, float r)
        {
            return length(max(abs(p) - b, 0.0)) - r;
        }

        #define linearstep(edge0, edge1, x) clamp((x - (edge0)) / (edge1 - (edge0)), 0.0, 1.0)
        float rand(float n)
        {
            n = round(n * 150);
            float val = frac(sin(n) * 43758.5453123);
            return (val - 0.5);
        }

        float rand2(float n)
        {
            float val = frac(sin(n) * 43758.5453123);
            return (val - 0.5);
        }

        float invLerp(float from, float to, float value) {
            return (value - from) / (to - from);
        }



        void surf (Input IN, inout SurfaceOutput o)
        {
            float4 objectOrigin = -mul(unity_ObjectToWorld, float4(0.0, 0.0, 0.0, 1.0));
            objectOrigin.y = 0;
            float2 p = (IN.worldPos.xz + objectOrigin.xz) / _Scaling;

            //_WorldSizeIncrease = clamp(0.15, 2.5, _WorldSizeIncrease);


            _Rect.x += _WorldSizeIncrease;
            _Rect.z += _WorldSizeIncrease * 0.58;
            float3 p2 = IN.worldPos.xyz + float3(objectOrigin.x, 0, objectOrigin.z);

            p2.z += rand(p2.x * 4.) * 0.005;
            p2.x += rand(p2.z * 2.) * 0.005;

            float4 startCol = float4(1, 0, 0, 1);
            float4 col = startCol;// groundColor(IN.uv_MainTex.xy);// tex2D(_MainTex, float2(p2.x, p2.z) * 1.5);


            //col = round(col * 3) / 3;

            //col = saturate(col);


            float amount = 1 - udRoundBox(p2, _Rect, _Rect.w);

            float w = 0.03;
            float amount2 = 1 - udRoundBox(p2, _Rect + float3(w,w,w), _Rect.w + w);

            float3 p3 = IN.worldPos.xyz;

            float3 p4 = IN.worldPos.xyz;
            p3.z += rand(p2.x * 4.) * 0.005;
            p3.x += rand(p2.z * 2.) * 0.005;

            p4.z += rand(p2.x * 4.) * 0.002;
            p4.x += rand(p2.z * 2.) * 0.002;


            float stoneAmount = 0;

            float3 extrap = p2;
            float3 s = tex2D(_OffsetTex, float2(extrap.x, extrap.z) * 0.1 + _Time.x * 0.2);

            s = (s * 2.0) - float3(1, 1, 1);

            s *= 0.1;
            extrap.z += s.x;// sin(p2.x * 3 + _Time.y) * 0.03;
            extrap.x += s.y;// cos(p2.z * 3 + _Time.y) * 0.03;



            float3 off = p2 - float3(objectOrigin.x, 0, objectOrigin.z);

            float angle = atan2(off.z, off.x);
            float f = 0;// +sin(angle * 200. + _Time.x) * 0.05 + 0.03;


            float4 c = col;

            float www = 0.0;

            c = lerp(c, _OutlineColor, step(udRoundBox(extrap, _Rect + float3(1., 0, 1.), 0.5), 0.3));
            c = lerp(c, float4(1, 1, 1, 1), step(udRoundBox(extrap, _Rect + float3(0.7 + f, 0, 0.7 + f), www), 0.5));


            c = lerp(c, _Color2, step(udRoundBox(extrap, _Rect + float3(0.6, 0, 0.6), www), 0.5));

            //wit
            c = lerp(c, float4(1, 1, 1, 1), step(1 - amount2, 0.5));


            float d = fwidth(amount) * 0.5;

            //Highlighted grass
            c = lerp(c, _Color2, linearstep(0.5 - d, 0.5 + d, amount));

            float mid = _Rect.z - (2.5 - 1.6);
            c = lerp(c, _StoneColor, step(mid, p3.z) * step(0.5, amount));


            float midLineThickness = 0.01;
            float ddd = fwidth(p4);
            float linee = linearstep(mid - midLineThickness, mid - midLineThickness + ddd, p4.z) * (1 - linearstep( mid + midLineThickness, mid + midLineThickness + ddd, p4.z)) * step(0.5, amount);
            c = lerp(c, c * 0.0, linee);




            float tmp = 0.5 - _EdgeThickness;

            float grassEdge = linearstep(tmp - d, tmp + d, amount) * linearstep(tmp - d, tmp + d, 1 - amount);
            //Grass edge
            c = lerp(c, _EdgeColor, grassEdge);





            tmp = 0.5 - _StoneEdgeThickness;
            float stoneEdge = 0;

            float dotAmount = (1 - stoneEdge) * (1 - grassEdge) + step(stoneAmount, 0.99);
            dotAmount = saturate(dotAmount);

            if (c.r == startCol.r && c.g == startCol.g && c.b == startCol.b)
            {
                clip(-1);
            }

            o.Albedo = c.rgb;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
