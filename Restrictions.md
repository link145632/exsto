# Without the GUI #
There is currently two ways you can use the restriction system in Exsto; through the data folder, and through console/chat commands.

## Chat/Console Commands ##
Exsto supplies 4 commands for denying, and 4 commands for allowing.  The following commands that you can use to deny, or allow is-
  * deny(allow)prop
  * deny(allow)entity
  * deny(allow)swep
  * deny(allow)stool

Using any of those commands, you can restrict the respected item.  Each of the arguments for all of those commands are as the following.
> _Rank-(PropModel, EntityClass, SwepClass, StoolClass)_

For example, if I wanted to restrict the bouncy ball entity from the rank guest, I would do the following.
> _!denyentity guest sent\_ball_

That command would restrict the guest from the bouncy ball, and they can no longer spawn it.  To allow that entity back into the available things guests can spawn, just change it to allowentity.
> _!allowentity guest sent\_ball_


Same thing applies with other deny or allow commands.

## Data Folder ##
For large amounts of restrictions needed, Exsto supports loading restriction data through the data/exsto\_restrictions/ folder.  Once it loads the data, the file is deleted and transfered into the Exsto SQL database.  To restrict through the data folder, you need to follow these instructions;

  1. Create a file with the name `exsto_*TYPE*_restrict_*RANK*.txt`.  Replace **TYPE** with the object type you want to restrict.  Examples are swep, stool, entity, or prop.  Replace **RANK** with the rank you want to restrict it from.
  1. Place all objects you want restricted inside the text file, each on their own lines.  For Example;
```
    weapon_tmp
    weapon_glock
    weapon_something
```
  1. Load up Exsto.  It will automatically load the file and delete it, after it stores its information in the SQL database.

# With the GUI #
**Currently, there is no way to use the restriction system with the GUI.**