// Copyright Project WB. All Rights Reserved.

#include "Save/WBSaveGameSubsystem.h"
#include "Core/WBLog.h"
#include "Misc/Paths.h"
#include "Misc/FileHelper.h"
#include "Serialization/ObjectAndNameAsStringProxyArchive.h"
#include "Serialization/MemoryReader.h"
#include "Serialization/MemoryWriter.h"
#include "Serialization/BufferArchive.h"

FString UWBSaveGameSubsystem::SlotPath(const FString& SlotName, bool bBackup) const
{
	// NOTE: absolute project-save path would come from FPaths::ProjectSavedDir() at runtime.
	const FString Dir = FPaths::ProjectSavedDir() / TEXT("SaveGames");
	const FString Ext = bBackup ? TEXT(".sav.bak") : TEXT(".sav");
	return Dir / SlotName + Ext;
}

bool UWBSaveGameSubsystem::SaveSlot(const FString& SlotName, UWBSaveGame* Save)
{
	if (!Save)
	{
		return false;
	}

	const FString Path = SlotPath(SlotName, false);
	const FString Backup = SlotPath(SlotName, true);

	// 1) back up the previous .sav (if any)
	if (FPaths::FileExists(Path))
	{
		IFileManager::Get().Copy(*Backup, *Path, true, true);
	}

	// 2) finalize CRC then serialize
	Save->Crc32 = Save->ComputeCrc();

	FBufferArchive Archive;
	Save->Serialize(Archive);
	Archive.Flush();

	const bool bOk = FFileHelper::SaveArrayToFile(Archive, *Path);
	OnSaveResult.Broadcast(bOk, SlotName);
	if (!bOk)
	{
		UE_LOG(LogWB, Error, TEXT("SaveSlot(%s): write failed"), *SlotName);
	}
	return bOk;
}

UWBSaveGame* UWBSaveGameSubsystem::LoadSlot(const FString& SlotName)
{
	const FString Path = SlotPath(SlotName, false);
	const FString Backup = SlotPath(SlotName, true);

	TArray<uint8> Bytes;
	if (!FFileHelper::LoadFileToArray(Bytes, *Path))
	{
		// try backup
		if (FFileHelper::LoadFileToArray(Bytes, *Backup))
		{
			UE_LOG(LogWB, Warning, TEXT("LoadSlot(%s): primary missing, using backup"), *SlotName);
		}
		else
		{
			return nullptr;
		}
	}

	FMemoryReader Reader(Bytes, true);
	UWBSaveGame* Save = NewObject<UWBSaveGame>();
	Save->Serialize(Reader);

	if (!Save->IsValid())
	{
		UE_LOG(LogWB, Error, TEXT("LoadSlot(%s): CRC mismatch - rolling back"), *SlotName);
		// rollback: restore from backup (which was written before the last save)
		if (FFileHelper::LoadFileToArray(Bytes, *Backup))
		{
			FMemoryReader Reader2(Bytes, true);
			UWBSaveGame* Rollback = NewObject<UWBSaveGame>();
			Rollback->Serialize(Reader2);
			return Rollback->IsValid() ? Rollback : nullptr;
		}
		return nullptr;
	}
	return Save;
}
