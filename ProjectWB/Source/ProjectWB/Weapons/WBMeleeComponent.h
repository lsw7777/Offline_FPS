// Copyright Project WB. All Rights Reserved.
//
// Melee = rhythm controller, not a fallback (docs section 3.3). Light attack,
// backstab execution, parry window, on-kill mobility. Shared stamina: 100 / 1.2s.

#pragma once

#include "CoreMinimal.h"
#include "Components/ActorComponent.h"
#include "Combat/WBWeaponTypes.h"
#include "WBMeleeComponent.generated.h"

DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FWBOnMeleeHit, const FMeleeData&, Melee);

UCLASS(ClassGroup = (Weapons), meta = (BlueprintSpawnableComponent))
class PROJECTWB_API UWBMeleeComponent : public UActorComponent
{
	GENERATED_BODY()

public:
	UWBMeleeComponent();

	UFUNCTION(BlueprintCallable, Category = "WB|Melee")
	void EquipMelee(const FMeleeData& InMelee);

	/** Light attack. Returns true if it connected. */
	UFUNCTION(BlueprintCallable, Category = "WB|Melee")
	bool LightAttack();

	/** Attempt a stealth execution (requires unalerted target within backstab cone). */
	UFUNCTION(BlueprintCallable, Category = "WB|Melee")
	bool TryExecute(AActor* Target);

	/** Enter parry stance; returns true if a perfect parry window is active this call. */
	UFUNCTION(BlueprintCallable, Category = "WB|Melee")
	bool BeginParry();

	UFUNCTION(BlueprintPure, Category = "WB|Melee")
	bool HasMelee() const { return bHasMelee; }

	UPROPERTY(BlueprintAssignable, Category = "WB|Melee")
	FWBOnMeleeHit OnMeleeHit;

private:
	UPROPERTY() FMeleeData Melee;
	UPROPERTY() bool bHasMelee = false;
	UPROPERTY() float Stamina = 100.f;
	UPROPERTY() float LastAttackTime = -1.f;
};
