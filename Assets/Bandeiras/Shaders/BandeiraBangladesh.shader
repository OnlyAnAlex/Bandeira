// Bangladesh c/ vento forte e agitado
Shader "Bandeiras/Bangladesh"
{
    Properties
    {
        _BaseMap    ("Textura", 2D) = "white" {}
        _Tamanho    ("Tamanho da bandeira em metros (u, v)", Vector) = (1, 0.6, 0, 0)

        [Header(Onda 1)]
        _Amplitude  ("Amplitude", Float) = 0.035
        _Frequency  ("Frequencia", Float) = 12
        _Speed      ("Velocidade", Float) = 8
        _Direction  ("Direcao (UV)", Vector) = (1, 0.5, 0, 0)

        [Header(Onda 2)]
        _Amplitude2 ("Amplitude", Float) = 0.015
        _Frequency2 ("Frequencia", Float) = 9
        _Speed2     ("Velocidade", Float) = 11

        [Header(Iluminacao falsa)]
        _LightPos     ("Posicao da luz (mundo)", Vector) = (-3, 3, -3, 0)
        _LightColor   ("Cor da luz", Color) = (1, 1, 1, 1)
        _Ambient      ("Luz ambiente", Range(0, 1)) = 0.3
        _Shininess    ("Brilho (expoente)", Float) = 64
        _SpecStrength ("Forca do especular", Range(0, 1)) = 0.4
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "Queue" = "Geometry" }
        Cull Off

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                float4 tangentOS  : TANGENT;
                float2 uv         : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv         : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                float3 normalWS   : TEXCOORD2;
            };

            sampler2D _BaseMap;

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                float4 _Tamanho;
                float  _Amplitude, _Frequency, _Speed;
                float4 _Direction;
                float  _Amplitude2, _Frequency2, _Speed2;
                float4 _LightPos;
                float4 _LightColor;
                float  _Ambient, _Shininess, _SpecStrength;
            CBUFFER_END

            float Deslocamento (float2 uv)
            {
                float2 dir  = normalize(_Direction.xy);
                float onda1 = sin(dot(uv, dir) * _Frequency  - _Time.y * _Speed)  * _Amplitude;

                float onda2 = sin(uv.y          * _Frequency2 - _Time.y * _Speed2) * _Amplitude2;

                return (onda1 + onda2) * uv.x * uv.x;
            }

            Varyings vert (Attributes v)
            {
                Varyings o;

                VertexNormalInputs base = GetVertexNormalInputs(v.normalOS, v.tangentOS);
                float3 posWS = TransformObjectToWorld(v.positionOS.xyz);

                float d = Deslocamento(v.uv);
                posWS += base.normalWS * d;

                const float e = 0.01;
                float inclinacaoU = (Deslocamento(v.uv + float2(e, 0)) - d) / (e * _Tamanho.x);
                float inclinacaoV = (Deslocamento(v.uv + float2(0, e)) - d) / (e * _Tamanho.y);
                float3 normal = base.normalWS
                              - base.tangentWS   * inclinacaoU
                              - base.bitangentWS * inclinacaoV;

                o.positionCS = TransformWorldToHClip(posWS);
                o.positionWS = posWS;
                o.normalWS   = normalize(normal);
                o.uv = TRANSFORM_TEX(v.uv, _BaseMap);
                return o;
            }

            half4 frag (Varyings i, FRONT_FACE_TYPE frente : FRONT_FACE_SEMANTIC) : SV_Target
            {
                float3 N = normalize(i.normalWS) * IS_FRONT_VFACE(frente, 1, -1);
                float3 L = normalize(_LightPos.xyz - i.positionWS);
                float3 V = normalize(_WorldSpaceCameraPos - i.positionWS);
                float3 H = normalize(L + V);

                float difusa    = saturate(dot(N, L));
                float especular = pow(saturate(dot(N, H)), _Shininess) * _SpecStrength;

                float3 cor = tex2D(_BaseMap, i.uv).rgb;
                float3 luz = cor * (_Ambient + difusa * _LightColor.rgb) + especular * _LightColor.rgb;
                return half4(luz, 1);
            }
            ENDHLSL
        }
    }
}
