// This work is licensed under the Creative Commons Attribution-NonCommercial 4.0 International License.
// To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/4.0/ or send a letter to
// Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.

Shader "Custom/GridShader"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        _LineWidth( "Line Width", Float) = 0.1
    }
    SubShader
    {
        Tags { "Queue" = "Transparent" "RenderType" = "Opaque" }
        ZWrite Off

        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard alpha fullforwardshadows

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0



        struct Input
        {
            float2 uv_MainTex;
            float3 worldPos;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;

        float _LineWidth;
        float _GridWidth;
        float _GridHeight;
        float _GridAlpha;

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            float2 wp = float2(IN.worldPos.x, IN.worldPos.z);
            wp.x = frac(wp.x / _GridWidth);
            wp.y = frac(wp.y / _GridHeight);

            wp = fmod(wp + 0.5, 1);

            float blur = 0.01;
            float v = smoothstep(_LineWidth - blur, _LineWidth + blur, wp.x) *
                      smoothstep(_LineWidth - blur, _LineWidth + blur, wp.y) *
                      smoothstep(_LineWidth - blur, _LineWidth + blur, 1. - wp.x) *
                      smoothstep(_LineWidth - blur, _LineWidth + blur, 1. - wp.y);




            fixed4 c = _Color;// float4(wp.x, wp.y, 0, 1.);
            o.Albedo = c.rgb;
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = (1 - v) * 0.5 * _GridAlpha;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
