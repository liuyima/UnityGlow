using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Profiling;
using UnityEngine.Rendering;

public class GlowPost : MonoBehaviour
{
    /// <summary>
    /// 采样次数，消耗GPU性能
    /// </summary>
    [Range(2, 5)]
    public int samplingIteration = 3;
    [Range(0, 2)]
    public float glowStrength = 1;
    [Range(1, 5)]
    public float glowWidth = 3;
    [Range(0, 2)]
    public float glowAdd = 1;
    [Tooltip("是否使用unity的depth获取方式")]
    public bool useUnityDepthMode = true;
    /// <summary>
    /// 作为光辉的renderer
    /// </summary>
    [HideInInspector]
    public List<GlowRenderer> renderers = new List<GlowRenderer>();
    public Shader postRenderColor, blur, add;
    Material blurMat,
        addMat;
    Camera cam;
    CommandBuffer blendCmd;
    CommandBuffer drawObjsCmd;
    CommandBuffer blurCmd;
    RenderTexture colorTexture;


    // Update is called once per frame
    void Update()
    {
        SetProperties();
    }
    private void OnPostRender()
    {
        DrawObjects();
    }
    void SetProperties()
    {

        blurMat.SetInt("_SamplingIteration", samplingIteration);
        blurMat.SetFloat("_Width", glowWidth);
        blurMat.SetFloat("_Strength", glowStrength);
    }
    private void OnEnable()
    {
        Init();
    }
    void Init()
    {
        cam = GetComponent<Camera>();

        if (useUnityDepthMode)
            cam.depthTextureMode = DepthTextureMode.Depth;
        blurMat = new Material(blur);
        addMat = new Material(add);

        int Width = cam.pixelWidth;
        int Height = cam.pixelHeight;
        colorTexture = RenderTexture.GetTemporary(Width, Height, 0, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Default);
        AddGlowCommand();
        AddBlendGlowCommand();
    }

    private void OnDisable()
    {
        CleanUp();
    }
    /// <summary>
    /// 将模糊效果进行混合
    /// </summary>
    void AddBlendGlowCommand()
    {
        blendCmd = new CommandBuffer();
        blendCmd.name = "叠加颜色";

        blendCmd.Blit(BuiltinRenderTextureType.CameraTarget, BuiltinRenderTextureType.CameraTarget, addMat);
        cam.AddCommandBuffer(CameraEvent.BeforeImageEffects, blendCmd);
    }
    /// <summary>
    /// 绘制需要有模糊效果的物体
    /// </summary>
    void DrawObjects()
    {
        drawObjsCmd = new CommandBuffer();
        drawObjsCmd.name = "绘制发光物体";
        //绘制到一个RenderTexture上
        drawObjsCmd.SetRenderTarget(colorTexture);
        drawObjsCmd.ClearRenderTarget(true, true, Color.clear);

        //绘制所有发光物体
        foreach (var item in renderers)
        {
            if (!item.enabled)
                continue;

            //设置材质球参数
            var colorMat = new Material(postRenderColor);
            colorMat.SetFloat("_Scale", item.scale);
            colorMat.SetColor("_Color", item.color);
            drawObjsCmd.DrawRenderer(item.meshRenderer, colorMat, 0, 0);
        }
        //执行CommandBuffer
        Graphics.ExecuteCommandBuffer(drawObjsCmd);
    }
    /// <summary>
    /// 模糊效果
    /// </summary>
    private void AddGlowCommand()
    {
        blurCmd = new CommandBuffer();
        blurCmd.name = "模糊处理";
        //创建一个纹理，用于绘制模糊效果
        int temp = Shader.PropertyToID("_TempImage");
        blurCmd.GetTemporaryRT(temp, -1, -1, 0, FilterMode.Bilinear);

        float dir = 1;
        for (int i = 0; i < samplingIteration; i++)
        {
            //竖向采样一次
            blurCmd.SetGlobalVector("_Dir", new Vector4(0, dir, 0, 0));
            blurCmd.Blit(colorTexture, temp, blurMat);
            //横向采样一次
            blurCmd.SetGlobalVector("_Dir", new Vector4(dir, 0, 0, 0));
            blurCmd.Blit(temp, colorTexture, blurMat);
            //每次采样后，扩展一次模糊中的采样距离，这样效果会更好
            dir += glowAdd;
        }
        blurCmd.SetGlobalTexture("_AddTex", colorTexture);
        cam.AddCommandBuffer(CameraEvent.BeforeImageEffects, blurCmd);
    }

    void CleanUp()
    {
        blendCmd.Dispose();
        blurCmd.Dispose();
        RenderTexture.ReleaseTemporary(colorTexture);
        cam.RemoveAllCommandBuffers();
    }
}


