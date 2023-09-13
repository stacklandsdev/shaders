// This work is licensed under the Creative Commons Attribution-NonCommercial 4.0 International License.
// To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/4.0/ or send a letter to
// Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.

Shader "Custom/ArrowSdfShader"
{
    Properties
    {
        [PerRendererData] _Color("Color", Color) = (1,1,1,1)
        [PerRendererData] _Start("Start", Vector) = (1,1,1,1)
        [PerRendererData] _End("End", Vector) = (1,1,1,1)
        _SideLength("Side Length", Float) = 0.5

        _Noise("Noise", Float) = 1
        _OutlineColor ("Outline Color", Color) = (1,1,1,1)
        _LineThickness ("Line Thickness", float) = 0.1
        _OutlineThickness ("Outline Thickness", float) = 0.1
    }
    SubShader
    {
        Tags{ "RenderType" = "Transparent" "Queue" = "Transparent"}

        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off
        LOD 200

        CGPROGRAM

        #pragma surface surf Unlit fullforwardshadows alpha
        #pragma target 3.0


        struct Input
        {
            float2 uv_MainTex;
            float3 worldPos;
        };

        fixed4 _Color;
        fixed4 _OutlineColor;

        float4 _Start, _End;
        float _LineThickness, _OutlineThickness;
        float _SideLength;
        float _Noise;

        fixed4 LightingUnlit(SurfaceOutput s, fixed3 lightDir, fixed atten)
        {
            fixed4 c;

            c.rgb = s.Albedo;
            c.a = s.Alpha;


            c.rgb *= atten;

            return c * _LightColor0;
        }

        float lineSegment(float2 p, float2 a, float2 b)
        {
            float2 ba = b - a;
            float2 pa = p - a;
            float h = clamp(dot(pa, ba) / dot(ba, ba), 0., 1.);
            return length(pa - h * ba);
        }


        float rand(float n)
        {
            n = round(n * 250.);
            float val = frac(sin(n) * 43758.5453123);
            return (val - 0.5);
        }

        float tri(float f)
        {
            return abs(frac(f) - 0.5) * 4. - 1.;
        }

        #define linearstep(edge0, edge1, x) clamp((x - (edge0)) / (edge1 - (edge0)), 0.0, 1.0)

        void surf (Input IN, inout SurfaceOutput o)
        {
            float4 objectOrigin = -mul(unity_ObjectToWorld, float4(0.0, 0.0, 0.0, 1.0));
            objectOrigin.y = 0;

            fixed4 c;

            float2 wp = IN.worldPos.xz;
            float2 owp = wp;



            wp.y += rand(wp.x * 4.) * 0.005 * _Noise;
            wp.x += rand(wp.y * 2.) * 0.005 * _Noise;

            wp.x += rand(round(wp.y * 10.) + _Time.x) * 0.005;
            wp.y += rand(round(wp.x * 10.) + _Time.x) * 0.005;


            float2 s = _Start.xy;
            float2 e = _End.xy;

            float2 dir = normalize(e - s);
            float3 perp3d = cross(float3(dir.x, 0.0, dir.y), float3(0, 1, 0));

            float2 perp = float2(perp3d.x, perp3d.z);

            float2 end1 = e - (dir + perp) * _SideLength;
            float2 end2 = e - (dir - perp) * _SideLength;

            float b = lineSegment(wp, s, e);
            b = min(b, lineSegment(wp, e, end1));
            b = min(b, lineSegment(wp, e, end2));


            float d = fwidth(b) * 0.5;

            c = _Color;

            float v = linearstep(_LineThickness + _OutlineThickness - d, _LineThickness + _OutlineThickness + d, b);
            c = lerp(c, _OutlineColor, v);

            v = linearstep(_LineThickness + _OutlineThickness * 2 - d, _LineThickness + _OutlineThickness * 2 + d, b);
            c = lerp(c, float4(0, 0, 0, 0), v);

            o.Albedo = c;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
