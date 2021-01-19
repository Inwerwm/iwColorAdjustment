#define EFFECT_MAIN

#include "Adjustments\ColorConverter.fxsub"
#include "Adjustments\HueSaturation.fxsub"
#include "Adjustments\BrightnessContrast.fxsub"

// コントローラ
#define CONTROLLER_NAME "iwColorAdjustmentController.pmx"

float mHuePlus  : CONTROLOBJECT < string name = CONTROLLER_NAME; string item = "色相+"; >;
float mHueMinus : CONTROLOBJECT < string name = CONTROLLER_NAME; string item = "色相-"; >;
float mSatPlus  : CONTROLOBJECT < string name = CONTROLLER_NAME; string item = "彩度+"; >;
float mSatMinus : CONTROLOBJECT < string name = CONTROLLER_NAME; string item = "彩度-"; >;
float mValPlus  : CONTROLOBJECT < string name = CONTROLLER_NAME; string item = "明度+"; >;
float mValMinus : CONTROLOBJECT < string name = CONTROLLER_NAME; string item = "明度-"; >;
float mCntPlus  : CONTROLOBJECT < string name = CONTROLLER_NAME; string item = "コントラスト+"; >;
float mCntMinus : CONTROLOBJECT < string name = CONTROLLER_NAME; string item = "コントラスト-"; >;

// ポストエフェクト設定
float Script : STANDARDSGLOBAL <
    string ScriptOutput = "color";
    string ScriptClass = "scene";
    string ScriptOrder = "postprocess";
> = 0.8;

// スクリーンサイズ
float2 ViewportSize : VIEWPORTPIXELSIZE;

// 半ピクセル
static float2 ViewportOffset = (float2(0.5,0.5)/ViewportSize);

// 背景のクリア値
float4 ClearColor = {1,1,1,0};
float ClearDepth  = 1.0;

// オリジナルの描画結果を記録するためのレンダーターゲット
texture2D ScnMap : RENDERCOLORTARGET <
    float2 ViewPortRatio = {1.0,1.0};
    int MipLevels = 1;
    string Format = "A8R8G8B8" ;
>;
sampler2D ScnSamp = sampler_state {
    texture = <ScnMap>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = NONE;
    AddressU  = CLAMP;
    AddressV = CLAMP;
};

texture2D ScnMap2 : RENDERCOLORTARGET <
    float2 ViewPortRatio = {1.0,1.0};
>;
sampler2D ScnSamp2 = sampler_state {
    texture = <ScnMap2>;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = NONE;
};

// 深度バッファ
texture2D DepthBuffer : RENDERDEPTHSTENCILTARGET <
    float2 ViewPortRatio = {1.0,1.0};
    string Format = "D24S8";
>;

struct VS_OUTPUT {
    float4 Pos			: POSITION;
    float2 Tex			: TEXCOORD0;
};

// シェーダ
VS_OUTPUT VS( float4 Pos : POSITION, float4 Tex : TEXCOORD0 ){
    VS_OUTPUT Out = (VS_OUTPUT)0; 
    
    Out.Pos = Pos;
    Out.Tex = Tex + ViewportOffset;
    
    return Out;
}

float4 PS_HSVScaling(float2 Tex: TEXCOORD0) : COLOR
{   
    float4 Color = tex2D( ScnSamp, Tex );
    
    Color = AdjustHueSaturation(Color, mHuePlus - mHueMinus,mSatPlus - mSatMinus);

    return Color;
}

float4 PS_BrightnessContrast(float2 Tex: TEXCOORD0) : COLOR{
    float4 Color = tex2D( ScnSamp2, Tex );
    
    Color = ScaleBrightnessContrast(Color, mValPlus - mValMinus, (1 + mCntPlus - mCntMinus) / 4);

    return Color;

}


technique PostEffect <
    string Script = 
        "RenderColorTarget0=ScnMap;"
        "RenderDepthStencilTarget=DepthBuffer;"
        "ClearSetColor=ClearColor;"
        "ClearSetDepth=ClearDepth;"
        "Clear=Color;"
        "Clear=Depth;"
        "ScriptExternal=Color;"

        "RenderColorTarget0=ScnMap2;"
        "RenderDepthStencilTarget=DepthBuffer;"
        "ClearSetColor=ClearColor;"
        "ClearSetDepth=ClearDepth;"
        "Clear=Color;"
        "Clear=Depth;"
        "Pass=HSVScaling;"

        "RenderColorTarget0=;"
        "RenderDepthStencilTarget=;"
        "Pass=BrightnessContrast;"
    ;
> {
    pass HSVScaling < string Script= "Draw=Buffer;"; > {
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_2_0 VS();
        PixelShader  = compile ps_2_0 PS_HSVScaling();
    }
    pass BrightnessContrast < string Script= "Draw=Buffer;"; > {
        AlphaBlendEnable = FALSE;
        VertexShader = compile vs_2_0 VS();
        PixelShader  = compile ps_2_0 PS_BrightnessContrast();
    }
}
