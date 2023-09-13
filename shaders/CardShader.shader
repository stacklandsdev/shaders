// This work is licensed under the Creative Commons Attribution-NonCommercial 4.0 International License.
// To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/4.0/ or send a letter to
// Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.

Shader "Custom/CardShader"
{
    Properties
    {
        [PerRendererData] _Color("Color", Color) = (1,1,1,1)
        [PerRendererData] _Color2("Color2", Color) = (1,1,1,1)
        [PerRendererData] _Foil("Foil", Float) = 0
        [PerRendererData] _IconColor("Icon Color", Color) = (1,1,1,1)
        [PerRendererData] _ShineStrength("Shine Strength", Float) = 1
        [PerRendererData] _BigShineStrength("Big Shine Strength", Float) = 1
        [PerRendererData] _HasSecondaryIcon("_HasSecondaryIcon", Float) = 0

        _MainTex("Albedo (RGB)", 2D) = "white" {}
        [PerRendererData] _IconTex("Icon Texture", 2D) = "white" {}

        [PerRendererData]_SecondaryTex("SecondaryIcon", 2D) = "white" {}
        _RainbowTex("Rainbow Tex", 2D) = "white" {}
        _Glossiness("Smoothness", Range(0,1)) = 0.5
        _Metallic("Metallic", Range(0,1)) = 0.0
        _SparkleIntensity("Sparkle Intensity", Float) = 1
        //_SmallCirclePosition("Small Circle Position", Vector) = (1,1,1,1)
        //_SmallCircleSize("Small Circle Size", Float) = 1
        _BorderColor("Border Color", Color) = (1,1,1,1)
    }
        SubShader
        {
            Tags { "RenderType" = "Opaque" }
            LOD 200

            CGPROGRAM
            // Physically based Standard lighting model, and enable shadows on all light types
            #pragma surface surf Standard vertex:vert addshadow

            // Use shader model 3.0 target, to get nicer looking lighting
            #pragma target 3.0

            sampler2D _MainTex;
            sampler2D _IconTex;
            sampler2D _RainbowTex;
            sampler2D _SecondaryTex;

            struct Input
            {
                float2 uv_MainTex;
                float3 viewDir;
                float3 worldPos;
                float3 worldNormal;
            };

            half _Glossiness;
            half _Metallic;
            fixed4 _Color;
            fixed4 _Color2;
            fixed4 _BorderColor;
            fixed4 _IconColor;


            float rand(float n)
            {
                n = round(n * 150);
                return frac(sin(n) * 43758.5453123);
            }


            void vert(inout appdata_full v, out Input o)
            {
                //v.vertex.y += rand(v.vertex.x * 0.001 + _Time.z) * 0.1;

                UNITY_INITIALIZE_OUTPUT(Input, o);


                o.viewDir = WorldSpaceViewDir(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex.xyz);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);


            }


            float _Foil;
            float _SmallCircleSize;
            float4 _SmallCirclePosition;
            float _ShineStrength;
            float _BigShineStrength;

            float _HasSecondaryIcon;

            // linear step between edge0 (value=0.) and edge1 (value=1.)
            #define linearstep(edge0, edge1, x) clamp((x - (edge0)) / (edge1 - (edge0)), 0.0, 1.0)

            void surf(Input IN, inout SurfaceOutputStandard o)
            {
                float2 uv = IN.uv_MainTex.xy;

                uv.x += rand(uv.y) * 0.005;
                uv.y += rand(uv.x) * 0.005;
                float2 duv = fwidth(uv);

                float2 iconUV = IN.uv_MainTex.xy;
                iconUV.y = 1. - iconUV.y;
                iconUV.x = 1. - iconUV.x;


                float2 offset = float2(0.5, 0.45);
                float scale = 1.75;

                if (_HasSecondaryIcon > 0.5)
                {
                    offset.y += 0.05;
                    scale = 2.;
                }




                iconUV -= offset;
                iconUV *= scale;
                iconUV += offset;

                float iconBounds = step(0, iconUV.x) * step(iconUV.x, 1) * step(0, iconUV.y) * step(iconUV.y, 1);


                float4 iconCol = tex2D(_IconTex, iconUV);
                float4 chestCol = tex2D(_SecondaryTex, iconUV);

                iconCol = lerp(iconCol, float4(0, 0, 0, 0), 1. - iconBounds);
                chestCol = lerp(chestCol, float4(0, 0, 0, 0), 1. - iconBounds);



                fixed4 c = _Color;


                float middleLinePos = 0.2;
                float middleLineThickness = 0.01;
                float edgeThickness = 0.03;
                float asp = (1 / 1.21) * 0.5;
                float circleRadius = 820.0 / 1024.0 * 0.5;


                half3 viewDirection = normalize(IN.worldPos - _WorldSpaceCameraPos);
                float2 p = IN.uv_MainTex + IN.uv_MainTex.y - viewDirection.xz * 5.;
                p.x += sin(p.y * 10.) * 0.02;
                p.y += cos(p.x * 30.) * 0.02;

                fixed3 noise = tex2D(_RainbowTex, p).xyz;

                float xy = IN.uv_MainTex.x + IN.uv_MainTex.y;
                float v = step(0.99, frac((xy + _Time.z * 2.) * 0.02));


                if (_Foil > 0.5)
                    c.rgb += v * _BigShineStrength;




                float2 middle = float2(0.5, 0.5);
                float distanceToMiddle = distance(iconUV, middle);

                if (_HasSecondaryIcon > 0.5)
                {

                    distanceToMiddle = max(abs(iconUV.x - middle.x), abs(iconUV.y - middle.y));
                }
                else
                {


                    //Circle
                    //c = lerp(c, _Color2, 1 - linearstep(circleRadius, circleRadius + duv.x, distanceToMiddle));
                }



                c = lerp(c, _Color2, 1 - linearstep(circleRadius, circleRadius + duv.x, distanceToMiddle));



                float a = 0.5 - asp + edgeThickness;

                c = lerp(c, _Color2, 1 - step(middleLinePos, uv.y));



                float4 targetCol = lerp(_Color, _IconColor, 1. - iconCol.r);



                if (_HasSecondaryIcon)
                {
                    targetCol += lerp(_Color, _IconColor, 1. - chestCol.r);
                    iconCol.a = max(iconCol.a, chestCol.a);
                }

                c = lerp(c, targetCol, iconCol.a);





                float top = middleLinePos - middleLineThickness;
                float bottom = middleLinePos + middleLineThickness;
                float duvy = duv.y * 0.5;
                float border2 = 1 - (linearstep(top - duvy, top + duvy, uv.y) * (1 - linearstep(bottom - duvy, bottom + duvy, uv.y)));

                float border = linearstep(a, a + duv.x, uv.x) *
                               linearstep(a, a + duv, 1 - uv.x) *
                               linearstep(edgeThickness, edgeThickness + duv.y, uv.y) *
                               linearstep(edgeThickness, edgeThickness + duv.y, 1 - uv.y) *
                               border2;

                if (_Foil > 0.5)
                    c.rgb += noise * _ShineStrength;

                c = lerp(_BorderColor, c, border);





                o.Albedo = c.rgb;
                // Metallic and smoothness come from slider variables
                o.Metallic = _Metallic;
                o.Smoothness = _Glossiness;
                o.Alpha = c.a;
            }
            ENDCG
        }
            FallBack "Diffuse"
}
