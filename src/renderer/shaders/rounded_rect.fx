// src/renderer/shaders/rounded_rect.fx
// Shader de MTA para rectángulos con bordes redondeados (HLSL)

float2 screenSize;
float4 color = float4(1, 1, 1, 1);
float radius = 0.0;
float2 rectPos;
float2 rectSize;

struct VSInput {
    float4 Position : POSITION0;
    float2 TexCoord : TEXCOORD0;
};

struct PSInput {
    float4 Position : POSITION0;
    float2 TexCoord : TEXCOORD0;
};

PSInput VertexShaderFunction(VSInput input) {
    PSInput output;
    output.Position = input.Position;
    output.TexCoord = input.TexCoord;
    return output;
}

float4 PixelShaderFunction(PSInput input) : COLOR0 {
    // Convertir coordenadas de textura (0-1) a píxeles locales del rectángulo
    float2 pixelPos = input.TexCoord * rectSize;
    
    // Distancia al centro ajustable para bordes redondeados
    // Algoritmo de SDF (Signed Distance Field) para rectángulos redondeados
    float2 d = abs(pixelPos - rectSize / 2.0) - (rectSize / 2.0 - radius);
    float dist = length(max(d, 0.0)) + min(max(d.x, d.y), 0.0) - radius;
    
    // Antialiasing simple con smoothstep
    float alpha = 1.0 - smoothstep(-1.0, 1.0, dist);
    
    return float4(color.rgb, color.a * alpha);
}

technique RoundedRect {
    pass P0 {
        PixelShader = compile ps_2_0 PixelShaderFunction();
    }
}
