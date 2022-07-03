using System.Collections;
using System.Collections.Generic;
using UnityEngine;
[RequireComponent(typeof(MeshRenderer))]
public class GlowRenderer : MonoBehaviour
{
    public Color color = Color.red;
    /// <summary>
    /// 渲染的网格的缩放
    /// </summary>
    [Range(1, 2)]
    public float scale = 1;
    [HideInInspector]
    public MeshRenderer meshRenderer;
    [HideInInspector]
    public Material colorMaterial;
    private void Awake()
    {
        meshRenderer = GetComponent<MeshRenderer>();
    }

    private void OnEnable()
    {
        FindObjectOfType<GlowPost>().renderers.Add(this);
    }

    private void OnDisable()
    {
        FindObjectOfType<GlowPost>().renderers.Remove(this);
    }
}
