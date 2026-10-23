// Copyright Project WB. All Rights Reserved.

#include "Weapons/WBLoadoutComponent.h"
#include "Core/WBLog.h"

UWBLoadoutComponent::UWBLoadoutComponent()
{
	PrimaryComponentTick.bCanEverTick = false;
}

bool UWBLoadoutComponent::AddWeapon(const FWeaponData& Weapon)
{
	// two primaries must fall in different distance bands (docs 3.4)
	for (const FWeaponData& Existing : Primaries)
	{
		if (Existing.DistanceBand == Weapon.DistanceBand)
		{
			UE_LOG(LogWB, Warning, TEXT("Loadout: rejected %s - band '%s' already occupied"),
				*Weapon.Id, *Weapon.DistanceBand);
			return false;
		}
	}

	if (Primaries.Num() < 2)
	{
		Primaries.Add(Weapon);
		return true;
	}

	// secondary fallback (pistol-class only)
	if (!bHasSecondary && Weapon.Class == TEXT("HeavyPistol"))
	{
		Secondary = Weapon;
		bHasSecondary = true;
		return true;
	}

	UE_LOG(LogWB, Warning, TEXT("Loadout: rejected %s - no free slot"), *Weapon.Id);
	return false;
}

void UWBLoadoutComponent::SetMelee(const FMeleeData& InMelee)
{
	Melee = InMelee;
	bHasMelee = true;
}

float UWBLoadoutComponent::GetTotalWeight() const
{
	float W = 0.f;
	for (const FWeaponData& P : Primaries) { W += P.Weight; }
	if (bHasSecondary) { W += Secondary.Weight; }
	if (bHasMelee)     { W += 0.5f; }
	return FMath::Min(W, MaxWeight);
}

float UWBLoadoutComponent::GetMoveSpeedMultiplier() const
{
	return 1.0f - MoveSpeedWeightPenalty * GetTotalWeight();
}

float UWBLoadoutComponent::GetSwapTimeMultiplier() const
{
	return 1.0f + SwapTimeWeightPenalty * GetTotalWeight();
}
