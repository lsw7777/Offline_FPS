// Copyright Project WB. All Rights Reserved.
//
// Minimal firing component (docs section 6.1). Reads FWeaponData, performs the
// hitscan, applies recoil, tracks magazine/reload. Feedback (hitmarker / sound /
// animation twitch) is emitted via delegates so the presentation layer can hook in.

#pragma once

#include "CoreMinimal.h"
#include "Components/ActorComponent.h"
#include "Combat/WBWeaponTypes.h"
#include "Combat/WBRecoilModel.h"
#include "WBFiringComponent.generated.h"

DECLARE_DYNAMIC_MULTICAST_DELEGATE_TwoParams(FWBOnShotFired, const FWeaponData&, Weapon, int32, AmmoLeft);
DECLARE_DYNAMIC_MULTICAST_DELEGATE_TwoParams(FWBOnShotHit, const FWeaponData&, Weapon, bool, bKillingBlow);
DECLARE_DYNAMIC_MULTICAST_DELEGATE(FWBOnReloadComplete);

UCLASS(ClassGroup = (Combat), meta = (BlueprintSpawnableComponent))
class PROJECTWB_API UWBFiringComponent : public UActorComponent
{
	GENERATED_BODY()

public:
	UWBFiringComponent();

	virtual void TickComponent(float DeltaTime, ELevelTick TickType,
		FActorComponentTickFunction* ThisTickFunction) override;

	/** Equip a weapon (by value). Resets magazine to full. */
	UFUNCTION(BlueprintCallable, Category = "WB|Combat")
	void EquipWeapon(const FWeaponData& InWeapon);

	UFUNCTION(BlueprintCallable, Category = "WB|Combat")
	void TryFire();

	UFUNCTION(BlueprintCallable, Category = "WB|Combat")
	void BeginReload();

	UFUNCTION(BlueprintCallable, Category = "WB|Combat")
	void CancelReload();

	UFUNCTION(BlueprintPure, Category = "WB|Combat")
	bool HasWeapon() const { return bHasWeapon; }

	UFUNCTION(BlueprintPure, Category = "WB|Combat")
	int32 GetAmmoInMag() const { return AmmoInMag; }

	// --- feedback hooks ---
	UPROPERTY(BlueprintAssignable, Category = "WB|Combat")
	FWBOnShotFired OnShotFired;

	UPROPERTY(BlueprintAssignable, Category = "WB|Combat")
	FWBOnShotHit OnShotHit;

	UPROPERTY(BlueprintAssignable, Category = "WB|Combat")
	FWBOnReloadComplete OnReloadComplete;

protected:
	/** Spread in degrees for the current movement stance (running worst). */
	float ComputeSpreadDeg() const;

	/** Hitscan + damage resolution. Returns whether something was hit and if lethal. */
	bool TraceShot(float SpreadDeg, bool& bKillingBlow) const;

	float GetArmorMultiplier(int32 ArmorLevel) const;

private:
	UPROPERTY() FWeaponData Weapon;
	bool bHasWeapon = false;

	UPROPERTY() int32 AmmoInMag = 0;
	UPROPERTY() bool bReloading = false;
	UPROPERTY() float ReloadRemaining = 0.f;
	UPROPERTY() float ReloadProgress = 0.f;   // preserved on cancel

	UPROPERTY() float TimeSinceLastShot = 1.f; // first-shot accuracy gating
	FWBRecoilState Recoil;
	FRandomStream Rng;
};
