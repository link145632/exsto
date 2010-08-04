-- Clear plugin
local PLUGIN = exsto.CreatePlugin()

    Shortcuts = {}
        Shortcuts[1] = "props,prop_physics"
        Shortcuts[2] = "wire,Any_wire_crap"
        Shortcuts[3] = "e2,gmod_wire_expression2"
        Shortcuts[4] = "ragdoll,prop_ragdoll"
        Shortcuts[5] = "vehicle,prop_vehicle"

PLUGIN:SetInfo({
	Name = "Clear",
	ID = "clear",
	Desc = "Clear's players crap.",
	Owner = "Hobo",
} )

function PLUGIN:Clear( owner, targ, clr, show )
-- Only works for Falco's Prop Protection at the moment.
    if FPP then
        targ = string.lower(targ)
        ply = exsto.FindPlayer(targ)
        entz = string.Explode(",",targ)
        ent = Entity( tonumber( string.Replace(tostring(entz[1]),"+","") ) ) -- Removes entity ID 'targ' and + does    v
        that = targ == "that" || targ == "that+"  -- 'that' will remove the aimed entity and 'that+' includes constrained entities.
        wld = targ == "world"
        
        if (ply == owner && not string.match(string.lower(owner:Name()),targ)) || 
            targ == "" || type(ply) ~= "Player" && not (targ == "all" || wld || that || ent) then
                return { owner,COLOR.NORM,"Player ",COLOR.NAME,ply,COLOR.NORM," not found." }
                
        elseif ent && ValidEnt(ent) then
                for cnt,e in pairs(entz) do
                    item = Entity( tonumber( string.Replace(tostring(e),"+","") ) )
                    if ValidEnt(item) then
                        if string.Right(tostring(entz[cnt]),1) == "+" then
                            for _,const in pairs (constraint.GetAllConstrainedEntities(item)) do
                                const:Remove()
                            end
                        else Entity(e):Remove() end
                    end 
                end
                return { COLOR.NAME,owner,COLOR.NORM, " just removed entit"..((table.Count(entz) > 1) and "ies " or "y "),COLOR.NAME,targ }
                
        elseif that then
            local e = owner:GetEyeTraceNoCursor().Entity
            if targ == "that" then
                if ValidEnt(e) then
                    e:Remove()
                end
            else
                for _,const in pairs (constraint.GetAllConstrainedEntities(e)) do
                    const:Remove()
                end
            end
            local show = show or 1
            if show > 0 then
                clr = targ
                return { COLOR.NAME,owner,COLOR.NORM, " just removed ",COLOR.NAME,tostring(e) }
            end
            
        else
            for c,l in pairs(Shortcuts) do
                local expl = string.Explode(",",Shortcuts[c])
                if clr == expl[1] then clr = expl[2] end
            end
                if(string.Left(clr,4) ~= "mdl-") then
                    for i,e in pairs(ents.GetAll()) do
                        if ValidEnt(e) && (e.Owner == ply || targ == "all"|| (wld && not e.Owner)) then
                            if(string.match(e:GetClass(),clr) or clr == "" or clr == "all") && (not e:IsWeapon() || (clr == "weapon" || wld)) then
                                e:Remove()
                            end
                        end
                    end
                    
                else
                    clr = string.sub(clr,5) or ""
                for i,e in pairs(ents.GetAll()) do
                    if ValidEnt(e) && (e.Owner == ply || targ == "all"|| (wld && not e.Owner)) then
                        if(string.match(e:GetModel() or "",clr) or clr == "") && (not e:IsWeapon() || (clr == "weapon" || wld)) then
                            e:Remove()
                        end
                    end
                end
            end
            
        local show = show or 1
            if show > 0 then
                if clr == "" then clr = "stuff" end
                    return { COLOR.NAME,owner,COLOR.NORM, " just removed ",COLOR.NAME,ply or targ,COLOR.NORM,type(ply)=="Player" and "'s " or " ",COLOR.NAME,clr }
            end
        end
    else
        return { owner,COLOR.NORM,"Sorry, this command only works for Falco's Prop Protection atm." }
    end
end

PLUGIN:AddCommand( "clear", {
	Call = PLUGIN.Clear,
	Desc = "Clear's things. Egs: !clear Hobo, !clear Hobo e2 or !clear all props. \n"..table.ToString(Shortcuts,"  Shortcuts:",true),
	FlagDesc = "Allows a user to clear someone's stuff.",
	Console = { "clear" },
	Chat = { "!clear" },
	ReturnOrder = "Player-Clearing-Show",
	Args = { Player = "STRING", Clearing = "STRING", Show = "NUMBER" },
    Optional = {Player = nil, Clearing = "", Show = 1},
	Category = "Administration",
})

function ValidEnt( entity )
       -- Exlcludes essentials
    if entity:IsValid() then
        cl = entity:GetClass()
        if (
            string.Left(cl,5) != "class" &&
            string.Left(cl,4) != "env_" &&
            string.Left(cl,5) != "func_" &&
            string.Left(cl,5) != "info_" &&
            cl != "beam" &&
            cl != "bodyque" &&
            cl != "darkrp_console" &&
            cl != "gmod_camera" &&
            cl != "gmod_tool" &&
            cl != "laserpointer" &&
            cl != "light_dynamic" &&
            cl != "network" &&
            cl != "physgun_beam" &&
            cl != "prop_door_rotating" &&
            cl != "phys_bone_follower" &&
            cl != "player" &&
            cl != "player_manager" &&
            cl != "point_camera" &&
            cl != "predicted_viewmodel" &&
            cl != "prop_dynamic" &&
            cl != "soundent" &&
            cl != "scene_manager" &&
            cl != "viewmodel" &&
            cl != "worldspawn"
            ) then return true
        end
    end
end

PLUGIN:Register()