// Copyright Project WB. All Rights Reserved.

using UnrealBuildTool;
using System.Collections.Generic;

public class ProjectWBTarget : TargetRules
{
	public ProjectWBTarget(TargetInfo Target) : base(Target)
	{
		Type = TargetType.Game;
		DefaultBuildSettings = BuildSettingsVersion.V5;
		IncludeOrderVersion = EngineIncludeOrderVersion.Unreal5_5;
		ExtraModuleNames.Add("ProjectWB");
	}
}
