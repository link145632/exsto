# Installing Exsto #

Installing Exsto is the same as installing any other addon that you may use.  It is incredibly simple with Garry's Mod, and just requires a drag and drop action.

To install Exsto in a listen or single player environment, follow these instructions.
  1. Move the exsto addon folder (either named exsto by svn, or exsto\_exported by zip) into your Steam/steamapps/**USERNAME**/garrysmod/garrysmod/addons folder.
  1. Open up the modules folder, and double click install\_modules.bat.  That will automatically move  the modules to the correct locations for Exsto.
  1. That is it for outside of Garry's Mod setup.  Please move down to the Inside Exsto section for help on setting up Exsto in game.

To install Exsto in a dedicated server environment, follow these instructions.
  1. Move the exsto addon folder (either named exsto by svn, or exsto\_exported by zip) into your garrysmod/addons folder.
  1. Open up the modules folder, and read the instructions in there on where to place each module.
  1. That is it for dedicated server setup.  Please move down to the Inside Exsto section for help on setting up Exsto in game.

# Inside Exsto #

Exsto automatically sets the users up default to rank guest.  Exsto also automatically creates the data tables, default ranks, and default variables for you, so you do not have to worry about setting up SQL.  However, there are a few things that require setting up, like making yourself a superadmin!

To make yourself superadmin in a listen server, run the following console command.
```
exsto rank *USERNAME* superadmin
```

To make yourself superadmin in a dedicated server, run the following command as RCON, or through a provided console terminal given to you by your server host.
```
exsto rank *USERNAME* superadmin
```


It is that simple; you are now done with setting up your rank.

## Immunity ##

Unlike other admin modifications, Exsto's immunity is inversed - that is to say that the lower the immunity, the more powerful. Say you're an admin, but your immunity is 0, this is the best, nobody can affect you, but if your immunity is 100, everyone can affect you.