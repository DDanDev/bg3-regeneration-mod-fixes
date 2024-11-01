# bg3-regeneration-mod-fixes

While playing Baldur's Gate 3 and using [this Regeneration mod](https://www.nexusmods.com/baldursgate3/mods/11184/?tab=description&BH=0) I found bugs with it and decided to fix them. I ended up optimizing and rewriting most of it so I am saving this here for others to copy and for the original mod author to get my changes if he wants to.

### For users who might want to use it:

Use [BG3 Modders Multitool](https://github.com/ShinyHobo/BG3-Modders-Multitool) or similar to unpack the original mod, then replace BoostrapServer.lua with mine and pack it back.

### For users and for Mithras666 (original mod author):

I have left several prints along the code that I used to debug and observe the mod functioning. You can remove all `print` statements to keep a cleaner console. For a released version I would expect these to be moved behind an MCM debug level setting or removed entirely.

### Extra:

I and other users have felt the 30 rounds maximumm cooldown was way too small, it is only 3 minutes out of combat. In MCM_blueprint.json I have changed all `"Max": 30` with `"Max": 1200`. 1200 rounds out of combat is 2 hours so I don't imagine anyway would set it this high. I am sharing this changed file too in case someone wants it.

### Note:

I am not sharing the paked and zipped mod ready to use because this is not my own work. I will allow time for Mithras666 to fix his mod himself and in the future if the mod is still not updated I could branch it and release my version for others to use, or just upload the zip here.
