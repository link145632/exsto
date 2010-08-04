-- Own plugin
local PLUGIN = exsto.CreatePlugin()

PLUGIN:SetInfo({
    Name = "Own",
    ID = "own",
    Desc = "Sets the owner of a prop/entity.",
    Owner = "Hobo",
} )

function PLUGIN:Own( owner, ply, const )
-- Only works for Falco's Prop Protection at the moment.
    if FPP then
        local e = owner:GetEyeTraceNoCursor().Entity
        if ValidEnt(e) then
            local i = 0
            if const == 0 then
                i = 1
                e.Owner = ply
            else
                Consts = constraint.GetAllConstrainedEntities(e)
                for _,const in pairs (Consts) do
                    i = i+1
                    const.Owner = ply
                end
            end
            return { COLOR.NAME,owner,COLOR.NORM, " gave ",COLOR.NAME,ply,COLOR.NORM," possession of ",COLOR.NAME,tostring(i),COLOR.NORM," object"..(i>1 and "s" or "").."." }
        else
            return { owner,COLOR.NORM,"Invalid object." }
        end
    else
        return { owner,COLOR.NORM,"Sorry, this command only works for Falco's Prop Protection atm." }
    end
end		
PLUGIN:AddCommand( "own", {
    Call = PLUGIN.Own,
    Desc = "Sets the owner of a prop.",
    FlagDesc = "Allows users to change prop owners.",
    Console = { "own" },
    Chat = { "!own" },
    ReturnOrder = "Player-InclConst",
    Args = { Player = "PLAYER", InclConst = "NUMBER" },
    Optional = { InclConst = 1 }
})

PLUGIN:Register()