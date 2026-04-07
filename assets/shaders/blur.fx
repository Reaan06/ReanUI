// assets/shaders/blur.fx
// Simple Box Blur Shader para MTA:SA

float blurFactor = 2.0;
float2 rectSize = float2(1, 1);

float4 PixelShaderFunction(float2 TexCoord : TEXCOORD0) : COLOR0 {
    float4 Color = 0;
    float2 TexelSize = 1.0 / rectSize;
    
    // Sampling 9 points surrounding the pixel
    for (float x = -1.0; x <= 1.0; x += 1.0) {
        for (float y = -1.0; y <= 1.0; y += 1.0) {
            Color += tex2D(gTextureSampler, TexCoord + float2(x, y) * TexelSize * blurFactor);
        }
    }
    
    return Color / 9.0;
}

technique Blur {
    pass P0 {
        PixelShader = compile ps_2_0 PixelShaderFunction();
    }
}
