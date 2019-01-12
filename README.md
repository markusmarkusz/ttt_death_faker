# TTT: Death Faker

Nothing special.  
Just a death faker for the famous gamemode Trouble in Terroristtown.

You can change the death reason by clicking the Reload-Key.
Primary Key will throw the fake body.
If you enable role changing, then your Secondary-Key 

This death faker works even if you are using addons like the Spectator Deathmatch or any other addon that modifies the scoreboard!  
It should work with almost every addon.
If you encounter any problems with some addons, contact me and I'll see what I can do to fix the problems.

Steam Workshop: http://steamcommunity.com/sharedfiles/filedetails/?id=785423990

## ConVars
#### ttt_df_allow_role_change
Set to `1` if you want to enable that traitors can change their role.

## Hooks
#### FakedDeath(Player, Role)
Player is the player who used the Death Faker.
Role is the role of the body (important, if the change of the role has been allowed).
The hook is internally used for the DamageLog Message for Tommys DamageLog.

## Tommy228's TTTDamageLogs
You can find his DamageLog Addon here:
https://github.com/Tommy228/TTTDamagelogs
http://facepunch.com/showthread.php?t=1416843