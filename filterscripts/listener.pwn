#include <a_samp>
#include <KeyListener>

public void:OnPlayerKeyDown(player, key)
{
	if(key == 77)
	{
  		CallRemoteFunction("Handphone", "i", player);
	}
	if(key == 113)
	{
		CallRemoteFunction("Inventory", "i", player);
	}
	if(key == 90)
    {
        CallRemoteFunction("Voice", "i", player);
    }
	if(key == 88)
	{
	    CallRemoteFunction("StopAnim", "i", player);
	}
	if(key >= 49 && key <= 52) 
    {
        new slot = key - 48;
        CallRemoteFunction("UseItemFromSlot", "ii", player, slot);
    }
}

public void:OnPlayerKeyUp(player, key)
{

}
