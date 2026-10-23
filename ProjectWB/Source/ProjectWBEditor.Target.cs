// Copyright Project WB. All Rights Reserved.

using UnrealBuildTool;
using System.Collections.Generic;

public class ProjectWBEditorTarget : TargetRules
{
	public ProjectWBEditorTarget(TargetInfo Target) : base(Target)
	{
		Type = TargetType.Editor;
		DefaultBuildSettings = BuildSettingsVersion.V5;
		IncludeOrderVersion = EngineIncludeOrderVersion.Unreal5_5;
		ExtraModuleNames.Add("ProjectWB");
	}
}
