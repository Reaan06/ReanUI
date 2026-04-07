texture gTexture;

sampler2D TextureSampler = sampler_state
{
    Texture = <gTexture>;
    MinFilter = Linear;
    MagFilter = Linear;
    MipFilter = Linear;
    AddressU = Clamp;
    AddressV = Clamp;
};

float4 gColor = float4(1, 1, 1, 1);

float4 PSMain(float2 uv : TEXCOORD0) : COLOR0
{
    return tex2D(TextureSampler, uv) * gColor;
}

technique ReanUIRoundedRect
{
    pass P0
    {
        PixelShader = compile ps_2_0 PSMain();
    }
}
