#if UNITY_EDITOR
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.SceneManagement;
using System.IO;

[InitializeOnLoad]
public static class FreeLifeProjectSetup
{
    const string ScenePath = "Assets/Scenes/FreeLife.unity";

    static FreeLifeProjectSetup()
    {
        EditorApplication.delayCall += EnsureProjectSetup;
    }

    static void EnsureProjectSetup()
    {
        if (!Directory.Exists("Assets/Scenes")) Directory.CreateDirectory("Assets/Scenes");
        if (!File.Exists(ScenePath))
        {
            var scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
            EditorSceneManager.SaveScene(scene, ScenePath);
        }
        EditorBuildSettings.scenes = new[]
        {
            new EditorBuildSettingsScene(ScenePath, true)
        };
        PlayerSettings.productName = "FreeLife RP";
        PlayerSettings.companyName = "FreeLife Studio";
        PlayerSettings.defaultInterfaceOrientation = UIOrientation.LandscapeLeft;
        PlayerSettings.SetApplicationIdentifier(BuildTargetGroup.Android, "org.freelife.roleplay");
        PlayerSettings.Android.minSdkVersion = AndroidSdkVersions.AndroidApiLevel23;
        AssetDatabase.SaveAssets();
    }
}
#endif
