// Copyright Project WB. All Rights Reserved.
//
// Save/load + rollback policy (docs section 6.4 / 7.3):
//   .sav + .sav.bak double backup, write-after-backup, CRC fail -> rollback.
// No encryption; XOR obfuscation + field reorder only.

#pragma once

#include "CoreMinimal.h"
#include "Subsystems/GameInstanceSubsystem.h"
#include "Save/WBSaveGame.h"
#include "WBSaveGameSubsystem.generated.h"

DECLARE_DYNAMIC_MULTICAST_DELEGATE_TwoParams(FWBOnSaveResult, bool, bSuccess, const FString&, SlotName);

UCLASS()
class PROJECTWB_API UWBSaveGameSubsystem : public UGameInstanceSubsystem
{
	GENERATED_BODY()

public:
	/** Serialize a save object to a slot path. Creates/updates .bak first. */
	UFUNCTION(BlueprintCallable, Category = "WB|Save")
	bool SaveSlot(const FString& SlotName, UWBSaveGame* Save);

	/** Load a slot. Returns a valid save, or a rollback candidate; null on hard failure. */
	UFUNCTION(BlueprintCallable, Category = "WB|Save")
	UWBSaveGame* LoadSlot(const FString& SlotName);

	UPROPERTY(BlueprintAssignable, Category = "WB|Save")
	FWBOnSaveResult OnSaveResult;

private:
	FString SlotPath(const FString& SlotName, bool bBackup) const;
};
