// Copyright Project WB. All Rights Reserved.

#include "Combat/WBWeaponDataLibrary.h"
#include "Core/WBLog.h"
#include "Misc/FileHelper.h"
#include "Misc/Paths.h"
#include "Serialization/JsonReader.h"
#include "Serialization/JsonSerializer.h"

namespace
{
	float GetNum(const TSharedPtr<FJsonObject>& Obj, const TCHAR* Key, float Def)
	{
		double V = Def;
		if (Obj->TryGetNumberField(Key, V))
		{
			return static_cast<float>(V);
		}
		return Def;
	}

	int32 GetInt(const TSharedPtr<FJsonObject>& Obj, const TCHAR* Key, int32 Def)
	{
		return Obj->GetIntegerField(Key) != 0 || Obj->HasField(Key)
			? Obj->GetIntegerField(Key) : Def;
	}

	FString GetStr(const TSharedPtr<FJsonObject>& Obj, const TCHAR* Key)
	{
		return Obj->GetStringField(Key);
	}

	bool GetBool(const TSharedPtr<FJsonObject>& Obj, const TCHAR* Key)
	{
		return Obj->GetBoolField(Key);
	}
}

bool UWBWeaponDataLibrary::LoadWeaponDataFromString(const FString& JsonString, TArray<FWeaponData>& OutWeapons)
{
	TSharedPtr<FJsonObject> Root;
	const TSharedRef<TJsonReader<>> Reader = TJsonReaderFactory<>::Create(JsonString);
	if (!FJsonSerializer::Deserialize(Reader, Root) || !Root.IsValid())
	{
		UE_LOG(LogWB, Error, TEXT("weapons.json: failed to parse JSON"));
		return false;
	}

	const TArray<TSharedPtr<FJsonValue>>* Items = nullptr;
	if (!Root->TryGetArrayField(TEXT("items"), Items))
	{
		UE_LOG(LogWB, Error, TEXT("weapons.json: missing 'items' array"));
		return false;
	}

	OutWeapons.Reset();
	for (const TSharedPtr<FJsonValue>& ItemValue : *Items)
	{
		const TSharedPtr<FJsonObject>& O = ItemValue->AsObject();
		if (!O.IsValid())
		{
			continue;
		}

		FWeaponData W;
		W.Id = GetStr(O, TEXT("id"));
		W.Class = GetStr(O, TEXT("class"));
		W.DisplayNameZh = GetStr(O, TEXT("display_name_zh"));
		W.Ammo = GetStr(O, TEXT("ammo"));

		const TArray<TSharedPtr<FJsonValue>>* Dmg = nullptr;
		if (O->TryGetArrayField(TEXT("damage"), Dmg))
		{
			for (const TSharedPtr<FJsonValue>& V : *Dmg)
			{
				W.Damage.Add(static_cast<float>(V->AsNumber()));
			}
		}

		W.Pellets = GetInt(O, TEXT("pellets"), 1);
		W.RPM = GetNum(O, TEXT("rpm"), 600.f);
		W.HandlingTimeS = GetNum(O, TEXT("handling_time_s"), 0.25f);
		W.Magazine = GetInt(O, TEXT("magazine"), 30);
		W.ReloadTacticalS = GetNum(O, TEXT("reload_tactical_s"), 2.f);
		W.RecoilVDeg = GetNum(O, TEXT("recoil_v_deg"), 1.f);
		W.RecoilHDeg = GetNum(O, TEXT("recoil_h_deg"), 0.3f);
		W.RecoilRecoverDegPerS = GetNum(O, TEXT("recoil_recover_deg_per_s"), 9.f);
		W.SpreadMult = GetNum(O, TEXT("spread_mult"), 1.f);
		W.EffectiveRangeM = GetNum(O, TEXT("effective_range_m"), 90.f);
		W.Penetration = GetInt(O, TEXT("penetration"), 1);
		W.bSuppressorSupport = GetBool(O, TEXT("suppressor_support"));
		W.NoiseRadiusM = GetNum(O, TEXT("noise_radius_m"), 30.f);
		W.AreaSuppression = GetNum(O, TEXT("area_suppression"), 0.f);
		W.Weight = GetNum(O, TEXT("weight"), 4.f);
		W.DistanceBand = GetStr(O, TEXT("distance_band"));
		W.AmmoCapGlobal = GetInt(O, TEXT("ammo_cap_global"), 0);
		W.Supply = GetStr(O, TEXT("supply"));

		const TArray<TSharedPtr<FJsonValue>>* Tags = nullptr;
		if (O->TryGetArrayField(TEXT("feedback_tags"), Tags))
		{
			for (const TSharedPtr<FJsonValue>& V : *Tags)
			{
				W.FeedbackTags.Add(V->AsString());
			}
		}

		OutWeapons.Add(W);
	}

	UE_LOG(LogWB, Log, TEXT("Loaded %d weapon(s)"), OutWeapons.Num());
	return OutWeapons.Num() > 0;
}

bool UWBWeaponDataLibrary::LoadWeaponDataFromFile(const FString& FilePath, TArray<FWeaponData>& OutWeapons)
{
	FString Content;
	if (!FFileHelper::LoadFileToString(Content, *FilePath))
	{
		UE_LOG(LogWB, Error, TEXT("weapons.json: cannot read file '%s'"), *FilePath);
		return false;
	}
	return LoadWeaponDataFromString(Content, OutWeapons);
}

bool UWBWeaponDataLibrary::LoadMeleeDataFromString(const FString& JsonString, TArray<FMeleeData>& OutMelee)
{
	TSharedPtr<FJsonObject> Root;
	const TSharedRef<TJsonReader<>> Reader = TJsonReaderFactory<>::Create(JsonString);
	if (!FJsonSerializer::Deserialize(Reader, Root) || !Root.IsValid())
	{
		UE_LOG(LogWB, Error, TEXT("melee.json: failed to parse JSON"));
		return false;
	}

	const TArray<TSharedPtr<FJsonValue>>* Items = nullptr;
	if (!Root->TryGetArrayField(TEXT("items"), Items))
	{
		return false;
	}

	OutMelee.Reset();
	for (const TSharedPtr<FJsonValue>& ItemValue : *Items)
	{
		const TSharedPtr<FJsonObject>& O = ItemValue->AsObject();
		if (!O.IsValid())
		{
			continue;
		}

		FMeleeData M;
		M.Id = GetStr(O, TEXT("id"));
		M.DisplayNameZh = GetStr(O, TEXT("display_name_zh"));
		M.Role = GetStr(O, TEXT("role"));
		M.DamageLight = GetNum(O, TEXT("damage_light"), 30.f);
		M.ExecuteMultiplier = GetNum(O, TEXT("execute_multiplier"), 1.f);
		M.IntervalS = GetNum(O, TEXT("interval_s"), 0.4f);
		M.RangeM = GetNum(O, TEXT("range_m"), 1.4f);
		M.StaminaCost = GetNum(O, TEXT("stamina_cost"), 10.f);
		M.AmmoRefundPerExecute = GetInt(O, TEXT("ammo_refund_per_execute"), 0);

		const TSharedPtr<FJsonObject>* Parry = nullptr;
		if (O->TryGetObjectField(TEXT("parry"), Parry))
		{
			M.ParryPerfectWindowS = GetNum(*Parry, TEXT("perfect_window_s"), 0.f);
		}
		const TSharedPtr<FJsonObject>* Backstab = nullptr;
		if (O->TryGetObjectField(TEXT("backstab"), Backstab))
		{
			M.BackstabConeDeg = GetNum(*Backstab, TEXT("cone_deg"), 0.f);
		}
		const TSharedPtr<FJsonObject>* OnKill = nullptr;
		if (O->TryGetObjectField(TEXT("on_kill"), OnKill))
		{
			M.OnKillSpeedBonusPct = GetNum(*OnKill, TEXT("speed_bonus_pct"), 0.f);
		}

		const TArray<TSharedPtr<FJsonValue>>* Specials = nullptr;
		if (O->TryGetArrayField(TEXT("specials"), Specials))
		{
			for (const TSharedPtr<FJsonValue>& V : *Specials)
			{
				M.Specials.Add(V->AsString());
			}
		}

		OutMelee.Add(M);
	}

	return OutMelee.Num() > 0;
}

const FWeaponData* UWBWeaponDataLibrary::FindWeaponById(const TArray<FWeaponData>& In, const FString& Id)
{
	for (const FWeaponData& W : In)
	{
		if (W.Id == Id)
		{
			return &W;
		}
	}
	return nullptr;
}
