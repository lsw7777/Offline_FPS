// Copyright Project WB. All Rights Reserved.

using UnrealBuildTool;

public class ProjectWB : ModuleRules
{
	public ProjectWB(ReadOnlyTargetRules Target) : base(Target)
	{
		PCHUsage = PCHUsageMode.UseExplicitOrSharedPCHs;

		PublicDependencyModuleNames.AddRange(new string[]
		{
			"Core",
			"CoreUObject",
			"Engine",
			"InputCore",
			"EnhancedInput",
			"Json",
			"JsonUtilities"
		});

		PrivateDependencyModuleNames.AddRange(new string[] { });

		// NOTE: no netcode, no EOS, no EAC (single-player only, see docs section 7).
	}
}
