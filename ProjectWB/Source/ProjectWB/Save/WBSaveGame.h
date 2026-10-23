// Copyright Project WB. All Rights Reserved.
//
// Progress save (docs section 6.4). Compressed payload + CRC32 + schema version.
// Tamper model: stop hand-edits, not hackers. Corrupt CRC -> rollback, never wipe.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/SaveGame.h"
#include "WBSaveGame.generated.h"

UCLASS()
class PROJECTWB_API UWBSaveGame : public USaveGame
{
	GENERATED_BODY()

public:
	UPROPERTY() int32 SchemaVersion = 1;
	UPROPERTY() FString ChapterId;
	UPROPERTY() float PlayTimeSec = 0.f;
	UPROPERTY() TArray<uint8> CompressedPayload;   // LZ4-compressed state blob
	UPROPERTY() int32 AmmoRedundant[4];            // cross-check fields (anti hand-edit)
	UPROPERTY() uint32 Crc32 = 0;

	/** Recompute CRC over CompressedPayload + AmmoRedundant. */
	uint32 ComputeCrc() const;

	/** True when stored CRC matches recomputed. */
	bool IsValid() const;
};
