// Copyright Project WB. All Rights Reserved.
//
// Recoil model mirroring docs section 6.1:
//   60% fixed pattern + 40% random, recover 9 deg/s toward first-shot origin.
// Camera recoil and actual spread are separated channels.

#pragma once

#include "CoreMinimal.h"

struct FWBRecoilState
{
	// accumulated camera pitch/yaw offset (degrees)
	float Pitch = 0.f;
	float Yaw = 0.f;

	float RecoilVDeg = 1.f;
	float RecoilHDeg = 0.3f;
	float RecoverDegPerS = 9.f;

	// fixed:random mix
	static constexpr float FixedRatio = 0.6f;

	void Configure(float InV, float InH, float InRecover)
	{
		RecoilVDeg = InV;
		RecoilHDeg = InH;
		RecoverDegPerS = InRecover;
	}

	/** Apply one shot. Returns the delta to add to the camera. */
	FVector2D Fire(FRandomStream& Rng)
	{
		const float DirV = Rng.FRandRange(-1.f, 1.f);
		const float DirH = Rng.FRandRange(-1.f, 1.f);
		const float V = RecoilVDeg * (FixedRatio + (1.f - FixedRatio) * DirV);
		const float H = RecoilHDeg * (FixedRatio + (1.f - FixedRatio) * DirH);
		Pitch += V;
		Yaw += H;
		return FVector2D(H, V);   // (yaw, pitch)
	}

	/** Recover toward origin. Returns remaining pitch to apply as easing cue. */
	float Recover(float DeltaSeconds)
	{
		const float Step = RecoverDegPerS * DeltaSeconds;
		Pitch = FMath::MoveToward(Pitch, 0.f, Step);
		Yaw = FMath::MoveToward(Yaw, 0.f, Step);
		return Pitch;
	}
};
