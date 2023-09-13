// This work is licensed under the Creative Commons Attribution-NonCommercial 4.0 International License.
// To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/4.0/ or send a letter to
// Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.

Shader "Custom/ConflictOutlineSdfShader"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        [PerRendererData] _Size("Size", Vector) = (1,1,1,1)

        _OutlineColor ("Outline Color", Color) = (1,1,1,1)
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

        float4 _Size;
        float _OutlineThickness;

        fixed4 LightingUnlit(SurfaceOutput s, fixed3 lightDir, fixed atten)
        {
            fixed4 c;

            c.rgb = s.Albedo;
            c.a = s.Alpha;


            c.rgb *= atten;

            return c * _LightColor0;
        }

        float udBox(float2 p, float2 b)
        {
            return length(max(abs(p) - b, 0.0));
        }

        float rand(float n)
        {
            n = round(n * 200.);
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



            wp.y += rand(wp.x * 4.) * 0.007;
            wp.x += rand(wp.y * 2.) * 0.007;



            //wp.x += tri(owp.y * 7.) * 0.01;
            //wp.y += tri(owp.x * 5.) * 0.01;

            wp.x += rand(round(wp.y * 10.) + _Time.x) * 0.01;
            wp.y += rand(round(wp.x * 10.) + _Time.x) * 0.01;



            float b = udBox(wp + objectOrigin.xz, _Size.xy * 0.5);

            float d = fwidth(b) * 0.5;

            c = _Color;

            float v = linearstep(_OutlineThickness - d, _OutlineThickness + d, b);
            c = lerp(c, _OutlineColor, v);

            v = linearstep(_OutlineThickness * 2 - d, _OutlineThickness * 2 + d, b);
            c = lerp(c, float4(0, 0, 0, 0), v);

            o.Albedo = c;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
