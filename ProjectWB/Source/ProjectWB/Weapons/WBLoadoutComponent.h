// Copyright Project WB. All Rights Reserved.
//
// Carrying rules (docs section 3.4): primary x2 (must differ in distance band),
// secondary x1, melee x1, throwables. Weight slows movement and swap time.

#pragma once

#include "CoreMinimal.h"
#include "Components/ActorComponent.h"
#include "Combat/WBWeaponTypes.h"
#include "WBLoadoutComponent.generated.h"

UCLASS(ClassGroup = (Weapons), meta = (BlueprintSpawnableComponent))
class PROJECTWB_API UWBLoadoutComponent : public UActorComponent
{
	GENERATED_BODY()

public:
	UWBLoadoutComponent();

	/** Attempt to add a weapon to an appropriate slot. Returns false if rejected. */
	UFUNCTION(BlueprintCallable, Category = "WB|Loadout")
	bool AddWeapon(const FWeaponData& Weapon);

	UFUNCTION(BlueprintCallable, Category = "WB|Loadout")
	void SetMelee(const FMeleeData& InMelee);

	UFUNCTION(BlueprintPure, Category = "WB|Loadout")
	float GetTotalWeight() const;

	UFUNCTION(BlueprintPure, Category = "WB|Loadout")
	float GetMoveSpeedMultiplier() const;

	UFUNCTION(BlueprintPure, Category = "WB|Loadout")
	float GetSwapTimeMultiplier() const;

	UFUNCTION(BlueprintPure, Category = "WB|Loadout")
	const TArray<FWeaponData>& GetPrimaries() const { return Primaries; }

	static constexpr float MaxWeight = 12.f;
	static constexpr float MoveSpeedWeightPenalty = 0.020f;
	static constexpr float SwapTimeWeightPenalty = 0.030f;

private:
	UPROPERTY() TArray<FWeaponData> Primaries;   // up to 2, distinct bands
	UPROPERTY() FWeaponData Secondary;
	UPROPERTY() bool bHasSecondary = false;
	UPROPERTY() FMeleeData Melee;
	UPROPERTY() bool bHasMelee = false;
	UPROPERTY() int32 FragGrenades = 2;
	UPROPERTY() int32 NoiseDecoys = 1;
};
