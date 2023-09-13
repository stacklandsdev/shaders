// This work is licensed under the Creative Commons Attribution-NonCommercial 4.0 International License.
// To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/4.0/ or send a letter to
// Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Custom/FloorShader"
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
        _Glossiness("Smoothness", Range(0,1)) = 0.5
        _Metallic("Metallic", Range(0,1)) = 0.0

        _Rect("Rect", Vector) = (0,0,0,0)

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


        void surf (Input IN, inout SurfaceOutput o)
        {
            float4 objectOrigin = -mul(unity_ObjectToWorld, float4(0.0, 0.0, 0.0, 1.0));
            objectOrigin.y = 0;
            float2 p = (IN.worldPos.xz + objectOrigin.xz) / _Scaling;




            _Rect.x += _WorldSizeIncrease;
            _Rect.z += _WorldSizeIncrease * 0.58;
            float3 p2 = IN.worldPos.xyz + float3(objectOrigin.x, 0, objectOrigin.z);

            p2.z += rand(p2.x * 4.) * 0.005;
            p2.x += rand(p2.z * 2.) * 0.005;
            float4 col = tex2D(_MainTex, float2(p2.x, p2.z) * 1.5);

            float4 stoneCol = tex2D(_StoneTex, float2(p2.x, p2.z) * 1.5);

            //col = round(col * 3) / 3;

            col = saturate(col);


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

            //wit??
            float4 c = lerp(_Color, float4(1, 1, 1, 1), step(1 - amount2, 0.5));


            float d = fwidth(amount) * 0.5;

            //Highlighted grass
            c = lerp(c, _Color2 * col, linearstep(0.5 - d, 0.5 + d, amount));

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



            o.Albedo = c.rgb;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
