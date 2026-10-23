// Copyright Project WB. All Rights Reserved.

#include "AI/WBPerceptionComponent.h"
#include "Engine/World.h"

UWBPerceptionComponent::UWBPerceptionComponent()
{
	PrimaryComponentTick.bCanEverTick = false;
}

bool UWBPerceptionComponent::ReportNoise(const FVector& NoiseLocation, float LoudnessM)
{
	const AActor* Owner = GetOwner();
	if (!Owner)
	{
		return false;
	}
	const float Dist = FVector::Dist(Owner->GetActorLocation(), NoiseLocation);
	return Dist <= LoudnessM;
}

bool UWBPerceptionComponent::CanSee(AActor* Target) const
{
	const AActor* Owner = GetOwner();
	if (!Owner || !Target)
	{
		return false;
	}

	const FVector EyeLoc = Owner->GetActorLocation();
	const FVector ToTarget = Target->GetActorLocation() - EyeLoc;
	const float Dist = ToTarget.Size();

	if (Dist > Config.SightRangeM)
	{
		return false;
	}

	const FVector Fwd = Owner->GetActorForwardVector();
	const FVector Dir = ToTarget.GetSafeNormal();
	const float AngleDeg = FMath::RadiansToDegrees(FMath::Acos(FVector::DotProduct(Fwd, Dir)));
	if (AngleDeg > Config.SightConeDeg * 0.5f)
	{
		return false;
	}

	// line-of-sight
	FHitResult Hit;
	FCollisionQueryParams Params;
	Params.AddIgnoredActor(Owner);
	if (Owner->GetWorld()->LineTraceSingleByChannel(Hit, EyeLoc, Target->GetActorLocation(),
		ECC_Visibility, Params))
	{
		return Hit.GetActor() == Target;
	}
	return false;
}
