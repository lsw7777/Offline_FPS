// Copyright Project WB. All Rights Reserved.
//
// Loads Config/Data/*.json (snake_case keys) into the runtime structs.
// Kept as explicit field mapping instead of FJsonObjectConverter so the JSON
// schema (owned by Tools/validate_data.py) never has to be renamed for the engine.

#pragma once

#include "CoreMinimal.h"
#include "WBWeaponTypes.h"
#include "Kismet/BlueprintFunctionLibrary.h"
#include "WBWeaponDataLibrary.generated.h"

UCLASS()
class PROJECTWB_API UWBWeaponDataLibrary : public UBlueprintFunctionLibrary
{
	GENERATED_BODY()

public:
	/** Parse the whole weapons.json document. Returns false and logs on error. */
	UFUNCTION(BlueprintCallable, Category = "WB|Data")
	static bool LoadWeaponDataFromString(const FString& JsonString, TArray<FWeaponData>& OutWeapons);

	/** Convenience: read + parse a file (Content-independent path, e.g. Config/Data/weapons.json). */
	UFUNCTION(BlueprintCallable, Category = "WB|Data")
	static bool LoadWeaponDataFromFile(const FString& FilePath, TArray<FWeaponData>& OutWeapons);

	UFUNCTION(BlueprintCallable, Category = "WB|Data")
	static bool LoadMeleeDataFromString(const FString& JsonString, TArray<FMeleeData>& OutMelee);

	static const FWeaponData* FindWeaponById(const TArray<FWeaponData>& In, const FString& Id);
};
