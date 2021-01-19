#include "Adjustments\ColorConverter.fxsub"
#include "Adjustments\hsv.fxsub"
#include "Adjustments\BrightnessContrast.fxsub"

////////////////////////////////////////////////////////////////////////////////////////////////
// �R���g���[��
#define CONTROLLER_NAME "iwColorAdjustmentController.pmx"

float mHuePlus  : CONTROLOBJECT < string name = CONTROLLER_NAME; string item = "�F��+"; >;
float mHueMinus : CONTROLOBJECT < string name = CONTROLLER_NAME; string item = "�F��-"; >;
float mSatPlus  : CONTROLOBJECT < string name = CONTROLLER_NAME; string item = "�ʓx+"; >;
float mSatMinus : CONTROLOBJECT < string name = CONTROLLER_NAME; string item = "�ʓx-"; >;
float mValPlus  : CONTROLOBJECT < string name = CONTROLLER_NAME; string item = "���x+"; >;
float mValMinus : CONTROLOBJECT < string name = CONTROLLER_NAME; string item = "���x-"; >;
float mCntPlus  : CONTROLOBJECT < string name = CONTROLLER_NAME; string item = "�R���g���X�g+"; >;
float mCntMinus : CONTROLOBJECT < string name = CONTROLLER_NAME; string item = "�R���g���X�g-"; >;

////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////

// �|�X�g�G�t�F�N�g�ł͕K���ȉ��̐ݒ������B
float Script : STANDARDSGLOBAL <
    string ScriptOutput = "color";
    string ScriptClass = "scene";
    string ScriptOrder = "postprocess";
> = 0.8;

// �X�N���[���T�C�Y
float2 ViewportSize : VIEWPORTPIXELSIZE;

// ���s�N�Z��
static float2 ViewportOffset = (float2(0.5,0.5)/ViewportSize);

// �w�i�̃N���A�l
float4 ClearColor = {1,1,1,0};
float ClearDepth  = 1.0;

// �I���W�i���̕`�挋�ʂ��L�^���邽�߂̃����_�[�^�[�Q�b�g
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

// �[�x�o�b�t�@
texture2D DepthBuffer : RENDERDEPTHSTENCILTARGET <
    float2 ViewPortRatio = {1.0,1.0};
    string Format = "D24S8";
>;

struct VS_OUTPUT {
    float4 Pos			: POSITION;
    float2 Tex			: TEXCOORD0;
};

////////////////////////////////////////////////////////////////////////////////////////////////
// �V�F�[�_

VS_OUTPUT VS_DrawBuffer( float4 Pos : POSITION, float4 Tex : TEXCOORD0 ){
    VS_OUTPUT Out = (VS_OUTPUT)0; 
    
    Out.Pos = Pos;
    Out.Tex = Tex + ViewportOffset;
    
    return Out;
}

float4 PS_DrawBuffer(float2 Tex: TEXCOORD0) : COLOR
{   
    float4 Color = tex2D( ScnSamp, Tex );
    
    Color = HSVFrom(Color);
    Color = hsvAdjustment(Color, mHuePlus - mHueMinus, 1.0 + (mSatPlus * 2 - mSatMinus), 1.0 + (mValPlus * 2 - mValMinus));
    Color = RGBFrom(Color);
    // Color = Contrast(Color, mCntPlus/2 - mCntMinus/2);

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
