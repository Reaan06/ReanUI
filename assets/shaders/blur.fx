texture gTexture;
float gBlurAmount = 0.0;

sampler2D TextureSampler = sampler_state
{
    Texture = <gTexture>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    AddressU = Clamp;
    AddressV = Clamp;
};

float4 PSMain(float2 uv : TEXCOORD0) : COLOR0
{
    float2 texel = float2(gBlurAmount, gBlurAmount) / 1024.0;

    float4 c = tex2D(TextureSampler, uv) * 0.4;
    c += tex2D(TextureSampler, uv + float2(texel.x, 0.0)) * 0.15;
    c += tex2D(TextureSampler, uv - float2(texel.x, 0.0)) * 0.15;
    c += tex2D(TextureSampler, uv + float2(0.0, texel.y)) * 0.15;
    c += tex2D(TextureSampler, uv - float2(0.0, texel.y)) * 0.15;
    return c;
}

technique ReanUIBlur
{
    pass P0
    {
        PixelShader = compile ps_2_0 PSMain();
    }
}
