// Copyright Project WB. All Rights Reserved.
//
// Runtime mirror of Config/Data/*.json. The JSON files are the single source of
// truth; these structs are deserialized from them at runtime (never hardcoded,
// per docs rule R3). Field semantics mirror Tools/validate_data.py v1 model.

#pragma once

#include "CoreMinimal.h"
#include "WBWeaponTypes.generated.h"

USTRUCT(BlueprintType)
struct FWeaponData
{
	GENERATED_BODY()

	// identity
	UPROPERTY(BlueprintReadOnly) FString Id;                    // "AK-47" (resource name, verbatim)
	UPROPERTY(BlueprintReadOnly) FString Class;                 // AssaultRifle / SMG / ...
	UPROPERTY(BlueprintReadOnly) FString DisplayNameZh;         // player-facing (see Docs/LEGAL.md)
	UPROPERTY(BlueprintReadOnly) FString Ammo;

	// damage & cadence
	UPROPERTY(BlueprintReadOnly) TArray<float> Damage;          // [min, max]
	UPROPERTY(BlueprintReadOnly) int32 Pellets = 1;
	UPROPERTY(BlueprintReadOnly) float RPM = 600.f;
	UPROPERTY(BlueprintReadOnly) float HandlingTimeS = 0.25f;

	// magazine & reload
	UPROPERTY(BlueprintReadOnly) int32 Magazine = 30;
	UPROPERTY(BlueprintReadOnly) float ReloadTacticalS = 2.0f;

	// recoil / spread (degrees)
	UPROPERTY(BlueprintReadOnly) float RecoilVDeg = 1.0f;
	UPROPERTY(BlueprintReadOnly) float RecoilHDeg = 0.3f;
	UPROPERTY(BlueprintReadOnly) float RecoilRecoverDegPerS = 9.0f;
	UPROPERTY(BlueprintReadOnly) float SpreadMult = 1.0f;

	// range / penetration / stealth
	UPROPERTY(BlueprintReadOnly) float EffectiveRangeM = 90.f;
	UPROPERTY(BlueprintReadOnly) int32 Penetration = 1;
	UPROPERTY(BlueprintReadOnly) bool  bSuppressorSupport = false;
	UPROPERTY(BlueprintReadOnly) float NoiseRadiusM = 30.f;

	// meta (balance / economy)
	UPROPERTY(BlueprintReadOnly) float AreaSuppression = 0.f;  // only used by "clear" scenes
	UPROPERTY(BlueprintReadOnly) float Weight = 4.f;
	UPROPERTY(BlueprintReadOnly) FString DistanceBand;          // near / mid / far
	UPROPERTY(BlueprintReadOnly) int32 AmmoCapGlobal = 0;       // 0 = unlimited scavenge
	UPROPERTY(BlueprintReadOnly) FString Supply;                // scavenge / checkpoint_only
	UPROPERTY(BlueprintReadOnly) TArray<FString> FeedbackTags;

	float DamageMean() const
	{
		return Damage.Num() == 2 ? (Damage[0] + Damage[1]) * 0.5f : 0.f;
	}

	float IntervalSeconds() const
	{
		return RPM > 0.f ? 60.f / RPM : 0.f;
	}
};

USTRUCT(BlueprintType)
struct FMeleeData
{
	GENERATED_BODY()

	UPROPERTY(BlueprintReadOnly) FString Id;
	UPROPERTY(BlueprintReadOnly) FString DisplayNameZh;
	UPROPERTY(BlueprintReadOnly) FString Role;                  // stealth_execution / front_parry / mobility
	UPROPERTY(BlueprintReadOnly) float DamageLight = 30.f;
	UPROPERTY(BlueprintReadOnly) float ExecuteMultiplier = 1.f;
	UPROPERTY(BlueprintReadOnly) float IntervalS = 0.4f;
	UPROPERTY(BlueprintReadOnly) float RangeM = 1.4f;
	UPROPERTY(BlueprintReadOnly) float StaminaCost = 10.f;
	UPROPERTY(BlueprintReadOnly) int32 AmmoRefundPerExecute = 0;
	UPROPERTY(BlueprintReadOnly) float ParryPerfectWindowS = 0.f;   // 0 = no parry
	UPROPERTY(BlueprintReadOnly) float BackstabConeDeg = 0.f;       // 0 = no backstab
	UPROPERTY(BlueprintReadOnly) float OnKillSpeedBonusPct = 0.f;
	UPROPERTY(BlueprintReadOnly) TArray<FString> Specials;
};
