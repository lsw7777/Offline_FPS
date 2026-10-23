// Copyright Project WB. All Rights Reserved.
//
// Enemy perception (docs section 6.2). Sight cone + hearing radii; gunshot noise
// is the "white noise" gameplay core (30m unsuppressed, 8m suppressed).

#pragma once

#include "CoreMinimal.h"
#include "Components/ActorComponent.h"
#include "WBPerceptionComponent.generated.h"

USTRUCT(BlueprintType)
struct FWBPerceptionConfig
{
	GENERATED_BODY()

	UPROPERTY(EditAnywhere, BlueprintReadWrite) float SightConeDeg = 100.f;
	UPROPERTY(EditAnywhere, BlueprintReadWrite) float SightRangeM = 30.f;
	UPROPERTY(EditAnywhere, BlueprintReadWrite) float SightRangeDarkM = 12.f;
	UPROPERTY(EditAnywhere, BlueprintReadWrite) float HearingWalkM = 6.f;
	UPROPERTY(EditAnywhere, BlueprintReadWrite) float HearingRunM = 12.f;
	UPROPERTY(EditAnywhere, BlueprintReadWrite) float HearingGunM = 30.f;
	UPROPERTY(EditAnywhere, BlueprintReadWrite) float HearingGunSuppressedM = 8.f;
	UPROPERTY(EditAnywhere, BlueprintReadWrite) float ReactionTimeS = 0.55f;
	UPROPERTY(EditAnywhere, BlueprintReadWrite) float FirstShotAccuracyCap = 0.55f;
};

UCLASS(ClassGroup = (AI), meta = (BlueprintSpawnableComponent))
class PROJECTWB_API UWBPerceptionComponent : public UActorComponent
{
	GENERATED_BODY()

public:
	UWBPerceptionComponent();

	/** Register a noise event at a world location. Returns true if heard. */
	UFUNCTION(BlueprintCallable, Category = "WB|AI")
	bool ReportNoise(const FVector& NoiseLocation, float LoudnessM);

	/** Can this AI currently see the target (cone + range + line-of-sight)? */
	UFUNCTION(BlueprintCallable, Category = "WB|AI")
	bool CanSee(AActor* Target) const;

	UFUNCTION(BlueprintCallable, Category = "WB|AI")
	void SetConfig(const FWBPerceptionConfig& InConfig) { Config = InConfig; }

private:
	UPROPERTY() FWBPerceptionConfig Config;
};
