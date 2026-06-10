register_blueprint "trait_scavenger"
{
    blueprint = "trait",
    text = {
        name   = "Scavenger",
        desc   = "Convert regular ammo at a loss to the current weapon",
        full   = "There's a use for all that junk, and you can find it! No matter what weapon you're using, you can convert the ammo you find to make use of it. Ammo is converted on pickup to the ammo type of the current weapon. Higher levels allow more ammo types to be converted, and multiply the conversion factor.\n\n{!LEVEL 1} - convert to 9mm, .44 and shells at a {!20%}/lvl ratio, 40mm grenades at {!10%}/lvl\n{!LEVEL 2} - also convert to 7.62 at a {!20%}/lvl ratio\n{!LEVEL 3} - also convert to rockets ({!5%}/lvl) and cells ({!10%}/lvl)",
        abbr   = "Scv",
    },
    attributes = {
        level = 1,
    },
    callbacks = {
        on_activate = [=[
            function(self,entity)
                gtk.upgrade_trait( entity, "trait_scavenger" )
            end
        ]=],
        on_pickup = [=[
            function ( self, user, item )
                if item and item.data and item.data.from_terminal then
                    item.data.from_terminal = false
                    return 0
                end
                local iid    = world:get_hid( item )
                local slevel = self.attributes.level
                local ammos  =
                {
                    [world:hash("ammo_9mm")]     = { id = "ammo_9mm",     factor = 0.2,  level = 1, },
                    [world:hash("ammo_shells")]  = { id = "ammo_shells",  factor = 0.2,  level = 1, },
                    [world:hash("ammo_44")]      = { id = "ammo_44",      factor = 0.2,  level = 1, },
                    [world:hash("ammo_40")]      = { id = "ammo_40",      factor = 0.1,  level = 1, },
                    [world:hash("ammo_762")]     = { id = "ammo_762",     factor = 0.2,  level = 2, },
                    [world:hash("ammo_rockets")] = { id = "ammo_rockets", factor = 0.05, level = 3, },
                    [world:hash("ammo_cells")]   = { id = "ammo_cells",   factor = 0.1,  level = 3, },
                }
                if ammos[ iid ] then
                    local weapon = user:get_weapon()
                    if weapon then
                        if weapon.clip then
                            local wid    = weapon.clip.ammo
                            if wid ~= iid and ammos[wid] and ammos[wid].level <= slevel and item.stack.amount > 0 then
                                local amount = item.stack.amount
                                item.stack.amount = 0
                                world:destroy( item )
                                local factor = ammos[wid].factor * slevel
                                amount = math.max( math.floor( amount * factor ), 1 )
                                user:equip( ammos[wid].id, { stack = { amount = amount } } )
                            end
                        end
                    end
                end
                return 0
            end
        ]=],
    },
}

register_blueprint "ktrait_master_nuclearcoil"
{
    blueprint = "trait",
    text = {
        name   = "NUCLEAR COIL",
        desc   = "MASTER TRAIT - cell-weapons - regenerate if empty and increase critical chance",
        full   = "Anything powered by cells is your jam. Not only do you increase your critical chance when using them, but held cell-based weapons regenerate a bit of power if empty! Not to mention you know how to use them to keep you warm - you're immune to {!Cold} statuses.\n\n{!LEVEL 1} - regenerate up to {!8} cells, {!+25%} critical chance\n{!LEVEL 2} - regenerate up to {!12} cells, {!+50%} critical chance\n{!LEVEL 3} - regenerate up to {!20} cells, regenerate {!2x} as fast, {!+100%} critical chance\n\nYou can pick only one MASTER trait per character.",
        abbr   = "MAA",
    },
    attributes = {
        level                 = 1,
        nuclearcoil_crit_chance = 25,
        nuclearcoil_regen_max   = 8,
        nuclearcoil_regen       = 1,
        resist = {
            cold = 100,
        },
    },
    callbacks = {
        on_activate = [=[
            function(self,entity)
                local tlevel, t = gtk.upgrade_master( entity, "ktrait_master_nuclearcoil" )
                local tattr     = t.attributes
                if tlevel == 2 then
                    tattr.nuclearcoil_crit_chance = 50
                    tattr.nuclearcoil_regen_max   = 12
                    --tattr.nuclearcoil_regen       = 2
                elseif tlevel == 3 then
                    tattr.nuclearcoil_crit_chance = 100
                    tattr.nuclearcoil_regen_max   = 20
                    tattr.nuclearcoil_regen       = 2
                end
            end
        ]=],
        on_aim = [=[
            function ( self, entity, target, weapon )
                local crit_chance = 0
                if target and weapon and weapon.clip and ( weapon.clip.ammo == world:hash("ammo_cells") or ( weapon.data and weapon.data.used_cells ) ) then
                    crit_chance = self.attributes.nuclearcoil_crit_chance
                end
                self.attributes.crit_chance = crit_chance
            end
        ]=],
        on_post_command = [[
            function ( self, actor, cmt, weapon, time )
                if time <= 1 then return end
                local attr       = self.attributes
                local regen_max  = attr.nuclearcoil_regen_max
                local regen      = attr.nuclearcoil_regen
                local run_weapon = function( w )
                    if w and w.clip and ( w.clip.ammo == world:hash("ammo_cells") or ( w.data and w.data.used_cells ) ) then
                        local max = math.min( w:attribute( "clip_size" ), regen_max )
                        local cur = w.clip.count
                        if cur < max then
                            local amount = math.ceil( regen * ( time / 100 ) )
                            w.clip.count = math.min( max, cur + amount )
                        end
                    end
                end
                run_weapon( actor:get_weapon(0) )
                run_weapon( actor:get_weapon(1) )
            end
        ]],
    }
}