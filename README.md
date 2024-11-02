# bg3-regeneration-mod-fixes

While playing Baldur's Gate 3 and using [this Regeneration mod](https://www.nexusmods.com/baldursgate3/mods/11184/?tab=description&BH=0) I found bugs with it and decided to fix them. I ended up optimizing and rewriting most of it so I am saving this here for others to copy and for the original mod author to get my changes if he wants to.

### For users who might want to use it:

Use [BG3 Modders Multitool](https://github.com/ShinyHobo/BG3-Modders-Multitool) or similar to unpack the original mod, then replace BoostrapServer.lua and MCM_Blueprint.json with mine and pack it back.

### For users and for Mithras666 (original mod author):

Changes are:

- Fixed bug where out of combat regeneration continued to happen during combat.
- Fixed bug when script extender resets the timer was cleaned but not started again
    - Refactored the whole thing so its consistent and stable no matter what happens or order of events, the behavior is always the same.
- **Feature** Added commands, which are available in BG3SE console if you have it enabled:
    - `!inspectAllCharsResources` => lists the names of common resources, and all party characters and their specific resources. Useful to find stuff the mod still doesn't support and to make usage of the next command easier by remembering the names of resources. If you find a resource that says its missing from the mod, and you want to regenerate it, just add it to MCM_Blueprint and to Vars in lua, same as the others.
    - `!giveResourceXToChar <ResourceName> <optional, character>` => example `!giveResourceXToChar ActionPoint` Adds one of the resource given immediatelly to the character the game is currently in control of. Optionally, give the uid or full id with prefixes of another character to give the resource to a specific entity.
    - `!resetLongRestCooldowns <optional, any string> <optional, character>` => example `!resetLongRestCooldowns` will reenable everything on the character currently in control that has a "Long Rest" cooldown. This does not mean executing a long rest! Only that anything that has a "Long Rest" cooldown and is not a resource, for example certain items that give a once per long rest spell. Resources, such as spell slots, rage, etc, are not a Long Rest cooldown even though a long rest regenerates them.
    - `!resetShortRestCooldowns` (same as above)
- **Feature** Added Luck of far realms and entropic ward reactions to resources that can regenerate, just because I have these at my current gameplay. There are probably other specific resources that are still not being tracked. Current implementation only tracks and regenerates resources that have a explicit setting available in MCM (other than short/long rest cooldowns, which are not resources and aren't tracked individually).
- Added DebugMode option in MCM to enable printing (a lot) of messages to the BG3S3 console to be able to keep track of what is the mod doing. Is it paused? Is it regenerating anything? Is it counting? Enable DebugMode and keep an eye at the console!
- **Feature** During dialogue and during turn based mode, the out of combat timer is now stopped, meaning the cooldowns will not be counted and no regeneration will happen. In fact, nothing will happen during these moments. Out of combat regen happens during exploration, Combat regen happens on each character's turn during combat. Outside of these, the mod will just sit still.
- **Feature** Increased maximum cooldown settings to 1200. I and other users have felt the 30 rounds maximumm cooldown was way too small, since it is only 3 minutes out of combat. I have changed all settings maximums to 1200, which out of combat is 2 hours. I don't imagine anyway would set it this high.

### Note:

I am not sharing the paked and zipped mod ready to use because this is not my own work. I will allow time for Mithras666 to fix his mod himself and in the future if the mod is still not updated I could branch it and release my version for others to use, or just upload the zip here.
