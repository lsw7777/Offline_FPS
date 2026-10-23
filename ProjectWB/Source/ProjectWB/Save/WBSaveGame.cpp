// Copyright Project WB. All Rights Reserved.

#include "Save/WBSaveGame.h"
#include "Serialization/MemoryWriter.h"
#include "Misc/Crc.h"

uint32 UWBSaveGame::ComputeCrc() const
{
	uint32 Crc = 0;
	if (CompressedPayload.Num() > 0)
	{
		Crc = FCrc::MemCrc32(CompressedPayload.GetData(), CompressedPayload.Num(), Crc);
	}
	Crc = FCrc::MemCrc32(AmmoRedundant, sizeof(AmmoRedundant), Crc);
	return Crc;
}

bool UWBSaveGame::IsValid() const
{
	return Crc32 == ComputeCrc();
}
