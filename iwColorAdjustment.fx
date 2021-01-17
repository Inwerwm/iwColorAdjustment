////////////////////////////////////////////////////////////////////////////////////////////////

// 背景のクリア値
float4 ClearColor = {1,1,1,0};
float ClearDepth  = 1.0;

////////////////////////////////////////////////////////////////////////////////////////////////

// ポストエフェクトでは必ず以下の設定をする。
float Script : STANDARDSGLOBAL <
    string ScriptOutput = "color";
    string ScriptClass = "scene";
    string ScriptOrder = "postprocess";
> = 0.8;


// オリジナルの描画結果を記録するためのレンダーターゲット
texture ScnMap : RENDERCOLORTARGET <
    float2 ViewPortRatio = {1.0,1.0};
>;
sampler ScnSamp = sampler_state {
    texture = <ScnMap>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = NONE;
};

// 深度バッファ
texture DepthBuffer : RENDERDEPTHSTENCILTARGET <
    float2 ViewPortRatio = {1.0,1.0};
>;


// スクリーンサイズ
float2 ViewportSize : VIEWPORTPIXELSIZE;

// 半ピクセル
static float2 ViewportOffset = (float2(0.5,0.5)/ViewportSize);


struct VS_OUTPUT {
    float4 Pos			: POSITION;
    float2 Tex			: TEXCOORD0;
};

////////////////////////////////////////////////////////////////////////////////////////////////
// シェーダ

VS_OUTPUT VS_DrawBuffer( float4 Pos : POSITION, float4 Tex : TEXCOORD0 ){
    VS_OUTPUT Out; 
    
    Out.Pos = Pos;
    Out.Tex = Tex + ViewportOffset;
    
    return Out;
}

float4 PS_DrawBuffer(float2 Tex: TEXCOORD0) : COLOR
{   
    float4 Color = tex2D( ScnSamp, Tex );
    
    // 何か処理
    
    return Color;
}

////////////////////////////////////////////////////////////////////////////////////////////////

technique PostEffect <
    string Script = 
        "RenderColorTarget0=ScnMap;"
        "RenderDepthStencilTarget=DepthBuffer;"
        "ClearSetColor=ClearColor;"
        "ClearSetDepth=ClearDepth;"
        "Clear=Color;"
        "Clear=Depth;"
        "ScriptExternal=Color;"
        "RenderColorTarget0=;"
        "RenderDepthStencilTarget=;"
        "Pass=DrawBuffer;"
    ;
> {
    pass DrawBuffer < string Script= "Draw=Buffer;"; > {
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_2_0 VS_DrawBuffer();
        PixelShader  = compile ps_2_0 PS_DrawBuffer();
    }
}
////////////////////////////////////////////////////////////////////////////////////////////////
