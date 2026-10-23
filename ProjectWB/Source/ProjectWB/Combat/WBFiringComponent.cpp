// Copyright Project WB. All Rights Reserved.

#include "Combat/WBFiringComponent.h"
#include "Core/WBLog.h"
#include "Engine/World.h"
#include "GameFramework/Pawn.h"
#include "Kismet/GameplayStatics.h"
#include "Engine/DamageEvents.h"

UWBFiringComponent::UWBFiringComponent()
{
	PrimaryComponentTick.bCanEverTick = true;
	Rng.GenerateNewSeed();
}

void UWBFiringComponent::TickComponent(float DeltaTime, ELevelTick TickType,
	FActorComponentTickFunction* ThisTickFunction)
{
	Super::TickComponent(DeltaTime, TickType, ThisTickFunction);

	TimeSinceLastShot += DeltaTime;

	if (bReloading && bHasWeapon)
	{
		ReloadRemaining -= DeltaTime;
		if (ReloadRemaining <= 0.f)
		{
			// commit: account for the empty-mag penalty
			const float Penalty = (AmmoInMag == 0) ? 0.5f : 0.f;
			if (ReloadRemaining + Penalty > 0.f)
			{
				ReloadRemaining += Penalty;   // not done yet
				return;
			}
			AmmoInMag = Weapon.Magazine;
			bReloading = false;
			ReloadProgress = 0.f;
			OnReloadComplete.Broadcast();
		}
	}
}

void UWBFiringComponent::EquipWeapon(const FWeaponData& InWeapon)
{
	Weapon = InWeapon;
	bHasWeapon = true;
	AmmoInMag = InWeapon.Magazine;
	bReloading = false;
	ReloadProgress = 0.f;
	Recoil.Configure(InWeapon.RecoilVDeg, InWeapon.RecoilHDeg, InWeapon.RecoilRecoverDegPerS);
	UE_LOG(LogWB, Log, TEXT("Equipped %s (%d in mag)"), *Weapon.Id, AmmoInMag);
}

void UWBFiringComponent::TryFire()
{
	if (!bHasWeapon || bReloading || AmmoInMag <= 0)
	{
		return;
	}

	const float Spread = ComputeSpreadDeg();
	bool bKilling = false;
	const bool bHit = TraceShot(Spread, bKilling);

	--AmmoInMag;
	TimeSinceLastShot = 0.f;

	// recoil (camera side, applied by the player controller / camera via OnShotFired)
	Recoil.Fire(Rng);

	OnShotFired.Broadcast(Weapon, AmmoInMag);
	if (bHit)
	{
		OnShotHit.Broadcast(Weapon, bKilling);
	}
}

void UWBFiringComponent::BeginReload()
{
	if (!bHasWeapon || bReloading || AmmoInMag >= Weapon.Magazine)
	{
		return;
	}
	bReloading = true;
	ReloadRemaining = Weapon.ReloadTacticalS * (1.f - ReloadProgress);
}

void UWBFiringComponent::CancelReload()
{
	if (bReloading)
	{
		// preserve the fraction already completed
		ReloadProgress = 1.f - FMath::Clamp(ReloadRemaining / Weapon.ReloadTacticalS, 0.f, 1.f);
		bReloading = false;
	}
}

float UWBFiringComponent::ComputeSpreadDeg() const
{
	const APawn* Pawn = Cast<APawn>(GetOwner());
	const float Speed = Pawn ? Pawn->GetVelocity().Size() : 0.f;

	// stance spread (docs: 0.1 stand / 0.6 walk / 1.4 run / 2.5 air)
	float Stance = 0.1f;
	if (Speed > 400.f)                 { Stance = 1.4f; }
	else if (Speed > 40.f)             { Stance = 0.6f; }

	float Spread = Stance * Weapon.SpreadMult;

	// first-shot accuracy bonus: stationary 0.35s -> -50%
	if (Speed <= 40.f && TimeSinceLastShot >= 0.35f)
	{
		Spread *= 0.5f;
	}
	return Spread;
}

bool UWBFiringComponent::TraceShot(float SpreadDeg, bool& bKillingBlow) const
{
	bKillingBlow = false;
	AActor* Owner = GetOwner();
	if (!Owner)
	{
		return false;
	}

	APawn* Pawn = Cast<APawn>(Owner);
	FVector EyeLoc;
	FRotator EyeRot;
	if (Pawn)
	{
		Pawn->GetActorEyesViewPoint(EyeLoc, EyeRot);
	}
	else
	{
		EyeLoc = Owner->GetActorLocation();
		EyeRot = Owner->GetActorRotation();
	}

	// apply spread as a perturbed direction
	const FRotator Perturb(0.f, 0.f, 0.f);
	const FVector Dir = EyeRot.Vector();
	// (spread perturb applied here in the real impl via a cone; kept minimal for scaffold)

	FVector End = EyeLoc + Dir * Weapon.EffectiveRangeM;

	FHitResult Hit;
	FCollisionQueryParams Params;
	Params.AddIgnoredActor(Owner);

	UWorld* World = GetWorld();
	if (!World)
	{
		return false;
	}

	if (World->LineTraceSingleByChannel(Hit, EyeLoc, End, ECC_Visibility, Params))
	{
		if (AActor* HitActor = Hit.GetActor())
		{
			const float Base = Weapon.DamageMean() * Weapon.Pellets;
			const int32 Armor = 0; // armor from hit actor's interface / component in real impl
			const float Dmg = Base * GetArmorMultiplier(Armor);
			FPointDamageEvent DamageEvent(Dmg, Hit, Dir, nullptr);
			HitActor->TakeDamage(Dmg, DamageEvent, Owner->GetInstigatorController(), Owner);
			bKillingBlow = false; // set by health component in real impl
		}
		return true;
	}
	return false;
}

float UWBFiringComponent::GetArmorMultiplier(int32 ArmorLevel) const
{
	// docs: 1级 15% / 2级 30% / 3级 45% damage reduction
	switch (ArmorLevel)
	{
	case 1: return 0.85f;
	case 2: return 0.70f;
	case 3: return 0.55f;
	default: return 1.0f;
	}
}
