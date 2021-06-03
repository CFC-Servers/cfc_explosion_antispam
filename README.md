# cfc_explosion_antispam
Prevents too many explosions from happening in one place at one time

## Overview
Like with many things, the Source engine is poorly optimized when it comes to explosions and destructible props.  
Having a ton of barrels blowing up or hundreds of crates falling to pieces can do the same to your performance.  
Hell, having too many break in one spot at the same time can make the server hiccup or crash with ease.  
The trouble is, players love to spam both from time to time, especially barrels, which also create laggy fire.  
And as the cherry on top, the sounds of ceaseless barrel spam are exhausting in their own right.  

However, these props are vital for a lot of creations and GMod shenanigans, it'd be a shame to remove them outright.  
So, for a simple middle ground solution, this addon limits how often explosive and breakable props can combust.  
The limit is applied based on location, preventing too much spam in any given area instead of it being map-wide, so a massive pile of bombs in one place won't magically stop some lone barrel from detonating somewhere else entirely.  

Specifically, this addon limits damage dealt *by* explosive objects, such as barrels and prop_phyx rockets, so an explosive detonating won't cause every destructible object around it to detonate, ignite, or break.  
Giant piles of barrels will quickly die down instead of all going off at once, super dense stacks of boxes won't melt the server when a bomb gets launched at them, explosive chains won't rapidly blow up everything in sight, etc.  
On the other hand, sources of damage such as weapons, non-explosive-based fire spreading through props, physics damage, raw damage events from Wiremod or Starfall, and so on will be be completely ignored by this addon.  

## Config
For fine tuning, there's an assortment of convars at your disposal:
- `cfc_explosion_antispam_near_dist` - How close explosive damage events (EDEs) must be to get limited (default `250 ^ 2`).
 - For optimization concerns, this is recorded with the distance you want, put to the power of two.
 - A range of `10` becomes `100`, `50` becomes `2500`, and so on.
- `cfc_explosion_antispam_max_near` - The max number of EDEs allowed in an area (default `10`).
- `cfc_explosion_antispam_explosion_timeout` - How long EDEs will persist if they instantly break a prop, in seconds (default `1`).
- `cfc_explosion_antispam_barrel_timeout` - Same as above, but for when a prop is only ignited (default `2`).
- `cfc_explosion_antispam_barrel_timeout_offset_max` - Gives random lifetimes to props when ignited by EDEs to make their delayed combustion look more natural (default `2`).
  - When a prop is ignited (but not instantly destroyed) by an EDE, it will take `0` to `duration` seconds added to `cfc_explosion_antispam_barrel_timeout` for the prop to combust and for the EDE to be removed from the log.
- `cfc_explosion_antispam_stop_all_timeout` - The standard duration to stop all EDEs frokm occuring if `CFCExplosionAntispam.stopAllDamage()` is called (default `10`).

## Functions
While the vast majority of lag and crashes via explosives will be stopped by this addon, there are some cases where having too many bombs or breakable props inside one another can still get through, especially when they all get set on fire.  
To remedy this, you can use `CFCExplosionAntispam.stopAllDamage( duration )` to block any and all EDEs for `duration` seconds and instantly extinguish all entities.  
This function is not used by the addon itself and is intended to be called as you see fit.  
A good place to call it would be in a lag detection addon, when the server has a large difference between `CurTime()` and `RealTime()` for too long and thus is lagging behind.
