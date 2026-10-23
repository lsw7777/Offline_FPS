// Copyright Project WB. All Rights Reserved.

#include "Weapons/WBMeleeComponent.h"
#include "Core/WBLog.h"
#include "Engine/World.h"
#include "Engine/DamageEvents.h"

UWBMeleeComponent::UWBMeleeComponent()
{
	PrimaryComponentTick.bCanEverTick = true;
}

void UWBMeleeComponent::EquipMelee(const FMeleeData& InMelee)
{
	Melee = InMelee;
	bHasMelee = true;
	Stamina = 100.f;
}

bool UWBMeleeComponent::LightAttack()
{
	if (!bHasMelee)
	{
		return false;
	}

	const UWorld* World = GetWorld();
	if (!World || World->TimeSeconds - LastAttackTime < Melee.IntervalS)
	{
		return false;   // attack on cooldown
	}

	if (Stamina < Melee.StaminaCost)
	{
		return false;   // no stamina
	}
	Stamina -= Melee.StaminaCost;
	LastAttackTime = World->TimeSeconds;

	// simple forward sweep via overlap would live here; scaffold performs a short trace
	AActor* Owner = GetOwner();
	if (!Owner)
	{
		return false;
	}

	const FVector Start = Owner->GetActorLocation();
	const FVector End = Start + Owner->GetActorForwardVector() * Melee.RangeM;

	FHitResult Hit;
	FCollisionQueryParams Params;
	Params.AddIgnoredActor(Owner);
	if (World->LineTraceSingleByChannel(Hit, Start, End, ECC_Visibility, Params))
	{
		if (AActor* Target = Hit.GetActor())
		{
			FPointDamageEvent Evt(Melee.DamageLight, Hit, Owner->GetActorForwardVector(), nullptr);
			Target->TakeDamage(Melee.DamageLight, Evt, nullptr, Owner);
			OnMeleeHit.Broadcast(Melee);
			return true;
		}
	}
	return false;
}

bool UWBMeleeComponent::TryExecute(AActor* Target)
{
	// real impl: verify unalerted state + backstab cone (Melee.BackstabConeDeg) + range.
	// execute damage = DamageLight * ExecuteMultiplier, plus ammo refund hook.
	if (!bHasMelee || !Target)
	{
		return false;
	}
	const float ExecuteDamage = Melee.DamageLight * Melee.ExecuteMultiplier;
	FPointDamageEvent Evt(ExecuteDamage, FHitResult(), GetOwner()->GetActorForwardVector(), nullptr);
	Target->TakeDamage(ExecuteDamage, Evt, nullptr, GetOwner());
	OnMeleeHit.Broadcast(Melee);
	return true;
}

bool UWBMeleeComponent::BeginParry()
{
	return bHasMelee && Melee.ParryPerfectWindowS > 0.f && Stamina >= 25.f;
}
