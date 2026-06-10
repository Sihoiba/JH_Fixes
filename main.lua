register_blueprint "perk_wa_calibration"
{
    flags      = { EF_NOPICKUP },
    text = {
        name  = "Auto-calibrating",
        name2 = "Auto-calibrated",
        desc  = "this weapon is currently auto-calibrating",
        desc2 = "this weapon is auto-calibrated (+1 optimal range, +10% damage)",
        desc3 = "this weapon is auto-calibrated (+10% damage, +10% crit)",
    },
    attributes = {
        level = 1,
        value = 0,
        value_style = 1,
        kills = 0,
        kills_target = 50,
        damage       = 0,
        opt_distance = 0,
        crit_chance  = 0,
    },
    callbacks = {
        on_kill = [=[
            function ( self, entity, target, weapon, gibbed, coord )
                local sattr = self.attributes
                if sattr.level == 1 then
                    if target and target.data and target.data.ai
                        and target.flags and target.flags.data[ EF_TARGETABLE ] then
                        if weapon == self:parent() then
                            sattr.kills = sattr.kills + 1
                            sattr.value = math.floor( 100 * ( sattr.kills / sattr.kills_target ) )
                            if sattr.kills >= sattr.kills_target then
                                sattr.value_style  = 0
                                sattr.value        = 0
                                sattr.level        = 2
                                world:set_text( self, "name", "name2" )
                                if ( weapon.attributes.opt_distance or 0 ) > 0 then
                                    sattr.opt_distance = 1
                                    world:set_text( self, "desc", "desc2" )
                                else
                                    sattr.crit_chance = 10
                                    world:set_text( self, "desc", "desc3" )
                                end
                                sattr.damage    = math.ceil(weapon.attributes.damage * 0.1)
                                return
                            end
                        end
                    end
                end
            end
        ]=],
    },
}

register_blueprint "perk_we_nano"
{
    blueprint = "perk",
    data = {},
    text = {
        name  = "NanoTech",
        desc  = "this weapon doesn't need ammo when reloading",
    },
    attributes = {
        level = 3,
    },
    callbacks = {
        on_attach = [[
            function( self, parent )
                if not parent.data then
                    parent.data = {}
                end
                if parent.weapon and parent.clip then
                    parent.data.before_nano = {}
                    parent.data.before_nano.ammo = parent.clip.ammo
                    parent.clip.ammo = ""
                    self.text.desc = "this weapon doesn't need ammo when reloading"
                    if parent.clip.reload_count == -1 then
                        self.text.desc = "this weapon doesn't need ammo when reloading and can be reloaded manually"
                        parent.data.before_nano.reload_count = -1
                        parent.clip.reload_count = 1
                    end
                elseif parent.weapon and parent.weapon.type == world:hash("melee") then
                    parent.data.before_nano = {}
                    self.text.desc = "this weapon is sharper"

                    parent.data.before_nano.damage_type = parent.weapon.damage_type
                    parent.data.before_nano.large = parent.attributes.large
                    parent.data.before_nano.blade = parent.attributes.blade

                    if parent.weapon.damage_type ~= world:hash("pierce") then
                        nova.log("Nano make pierce")
                        parent.weapon.damage_type = "pierce"
                    else
                        nova.log("Nano add crit")
                        self.attributes.crit_damage = 50
                    end
                    if parent.attributes.large == 1 then
                        nova.log("Nano make not large")
                        self.text.desc = "this weapon is lighter and sharper"
                        parent.attributes.large = 0
                    end
                    if not parent.attributes.blade then
                        nova.log("Nano make blade")
                        self.text.desc = "this weapon is lighter, sharper and can now be wielded like a blade"
                        parent.attributes.blade = 1
                    end
                end
            end
        ]],
        on_detach  = [[
            function ( self, parent )
                if parent and parent.data and parent.data.before_nano and parent.data.before_nano.ammo then
                    parent.clip.ammo = parent.data.before_nano.ammo
                end
                if parent and parent.data and parent.data.before_nano and parent.data.before_nano.reload_count then
                    parent.clip.reload_count = parent.data.before_nano.reload_count
                end
                if parent and parent.data and parent.data.before_nano and parent.data.before_nano.damage_type then
                    parent.weapon.damage_type = parent.data.before_nano.damage_type
                end
                if parent and parent.data and parent.data.before_nano and parent.data.before_nano.large then
                    parent.attributes.large = parent.data.before_nano.large
                end
                if parent and parent.data and parent.data.before_nano and parent.data.before_nano.blade then
                    parent.attributes.blade = parent.data.before_nano.blade
                end
            end
        ]],
    },
}

register_blueprint "exo_pack_nano"
{
    flags = { EF_ITEM, EF_CONSUMABLE },
    lists = {
        group    = "item",
        keywords = { "exotic", "special", "rare_mod", },
        weight   = 1,
        dmin     = 14,
        dmed     = 21,
    },
    data = {
        exotic = true,
    },
    text = {
        name = "nanotech mod pack",
        desc = "Prototype device for modifying weapon magazines. Applies the {!NanoTech} perk.",

        select = "Select weapon to NanoTech mod",
    },
    ascii     = {
        glyph     = "\"",
        color     = LIGHTMAGENTA,
    },
    callbacks = {
        on_use = [=[
            function(self,entity)
                if entity == world:get_player() then
                    mod.run_ui( self, entity, {
                         mod_id    = "exo_mod_nano",
                         desc      = self.text.select,
                         slots     = { "1", "2", "3", "4" },
                         no_child  = "perk_we_nano",
                     } )
                    return -1
                else
                    return -1
                end
            end
        ]=],
        on_activate = [=[
            function( self, who, level, param )
                if self:parent() then return 0 end -- hack for activation prevention when in lootbox!
                if param then
                    local me    = mod.apply_mod( param, "exo_mod_nano" )
                    if param.weapon then
                        generator.add_perk( param, "perk_we_nano", nil, true )
                    else
                        return 0
                    end
                    world:remove_item( who, self )
                    world:get_player().statistics.data.mod:inc()
                    return 100
                else
                    return 0
                end
            end
        ]=]
    },
}

register_blueprint "perk_te_medifiber"
{
    blueprint = "perk",
    text = {
        name = "Medi-fiber",
        desc = "regenerates up to 50% of health at the cost of durability",
    },
    attributes = {
        level = 3,
    },
    callbacks = {
        on_post_command = [[
            function ( self, actor, cmt, weapon, time )
                if time <= 1 then return end
                local attr  = actor.attributes
                local max   = attr.health
                local cur   = actor.health.current
                if cur < 1 or actor:child("bleed") then return end
                local limit = math.floor( max * 0.5 )
                if cur < limit then
                    local need  = limit - cur
                    local armor = self:parent()
                    local attr  = armor.attributes
                    if attr and armor.health then
                        local acur = armor.health.current
                        if acur > 0 then
                            local regen = math.min( acur, math.min( 50, need * 50 ) )
                            armor.health.current = acur - regen
                            local amount         = math.ceil( regen * ( time / 500 ) )
                            actor.health.current = math.min( limit, cur + amount )
                        end
                    elseif attr and armor then
                        local regen = math.min( 50, math.min( 50, need * 50 ) )
                        local amount         = math.ceil( regen * ( time / 500 ) )
                        actor.health.current = math.min( limit, cur + amount )
                    end
                end
            end
        ]],
    },
}

register_blueprint "perk_wb_second_chamber"
{
    blueprint = "perk",
    lists = {
        group    = "perk_wb",
        keywords = { "reload", "mag", "shotguns", "explosives", },
    },
    data = {
        perk_group = "reload",
    },
    text = {
        name = "Second chamber",
        desc = "doubles magazine size",
    },
    attributes = {
        clip_size = 1,
    },
    callbacks = {
        on_attach = [[
            function( self, parent )
                if parent.attributes and parent.clip then
                    self.attributes.clip_size = parent.attributes.clip_size or 1
                    for c in ecs:children( parent ) do
                        if c ~= self and c.attributes and c.attributes.clip_size then
                            self.attributes.clip_size = self.attributes.clip_size + c.attributes.clip_size
                        end
                    end
                    parent.clip.count = parent.clip.count + self.attributes.clip_size
                end
            end
        ]],
        on_detach  = [[
            function ( self, parent )
                if parent.attributes and parent.clip then
                    if parent.clip.count >= self.attributes.clip_size then
                        parent.clip.count = parent.clip.count - self.attributes.clip_size
                    else
                        parent.clip.count = 0
                    end
                end
            end
        ]],
    },
}

register_blueprint "perk_wb_extended_mag"
{
    blueprint = "perk",
    lists = {
        group    = "perk_wb",
        keywords = { "reload", "mag", "pistols", "smgs", "auto", "rotary", "semi", },
    },
    data = {
        perk_value = "mag",
        perk_group = "reload",
    },
    text = {
        name = "Extended Mag",
        desc = "increases magazine size",
    },
    attributes = {
        clip_size = 1,
        value = 1,
    },
    callbacks = {
        on_create = [=[
            function(self,_,tier)
                if tier > 0 then
                    self.attributes.value     = tier
                    self.attributes.clip_size = tier
                end
            end
        ]=],
        on_attach = [[
            function( self, parent )
                if parent.attributes and parent.clip then
                    parent.clip.count = parent.clip.count + self.attributes.clip_size
                end
            end
        ]],
        on_detach  = [[
            function ( self, parent )
                if parent.attributes and parent.clip then
                    if parent.clip.count >= self.attributes.clip_size then
                        parent.clip.count = parent.clip.count - self.attributes.clip_size
                    else
                        parent.clip.count = 0
                    end
                end
            end
        ]],
    },
}

register_blueprint "perk_wb_efficient"
{
    blueprint = "perk",
    lists = {
        group    = "perk_wb",
        keywords = { "reload", "pistols", "smgs", "auto", "rotary", "semi", },
    },
    data = {
        perk_group = "reload",
    },
    text = {
        name = "Efficient",
        desc = "reload ammo efficiency doubled",
    },
    attributes = {
        reload_mod = 1.0,
        shot_cost_mod = 1,
    },
    callbacks = {
        on_attach = [[
            function( self, parent )
                if parent.weapon and parent.clip then
                    local ammo = parent.clip.ammo
                    if ammo == world:hash("kit_multitool") or parent.clip.reload_count == -1 then
                        self.attributes.shot_cost_mod = 0.75
                        self.text.desc = "75% ammo consumption"
                    elseif ammo ~= world:hash("kit_multitool") then
                        self.attributes.reload_mod = 0.5
                        self.text.desc = "reload ammo efficiency doubled"
                    end
                end
            end
        ]],
    },
}

register_blueprint "kit_nova"
{
    flags = { EF_ITEM, EF_CONSUMABLE },
    lists = {
        group    = "item",
        keywords ={ "special", },
        weight   = 50,
        dmin     = 3,
        dmed     = 7,
        dmax     = 10,
    },
    text = {
        name = "novabomb",
        desc = "A marvel of engineering, the nova flux catalyst can replicate the raw, unbridled energy of a supernova in a destructive display of light and force, while keeping the user in the center intact. Usually. Deals 120 slash damage.",
    },
    ascii     = {
        glyph     = "+",
        color     = LIGHTCYAN,
    },
    callbacks = {
        on_use = [=[
        function( self, entity )
            world:play_sound( "medkit_small", entity )
            local p   = entity:get_position()

            local w   = world:create_entity( "explosion_kit_nova" )
            entity:attach( w )
            world:get_level():fire( entity, p, w )
            world:destroy( w )

            return 100
        end
        ]=],
    },
}

register_blueprint "ancient_pack_hallowed"
{
    flags = { EF_ITEM, EF_CONSUMABLE },
    text = {
        name = "ancient mod pack",
        desc = "Ancient set of tools for weapon consecration. Cannot be reclaimed when dismantling the weapon.",

        select = "Select weapon to hallow",
    },
    ascii     = {
        glyph     = "\"",
        color     = LIGHTCYAN,
    },
    data = {},
    callbacks = {
        on_use = [=[
            function(self,entity)
                if entity == world:get_player() then
                    mod.run_ui( self, entity, {
                         mod_id    = "ancient_mod_hallow",
                         desc      = self.text.select,
                         slots     = { "1", "2", "3", "4" },
                         no_child  = "perk_wa_hallowed",
                     } )
                    return -1
                else
                    return -1
                end
            end
        ]=],
        on_activate = [=[
            function( self, who, level, param )
                if self:parent() then return 0 end -- hack for activation prevention when in lootbox!
                if param then
                    local me = mod.apply_mod( param, "ancient_mod_hallow" )
                    if param.weapon then
                        generator.add_perk( param, "perk_wa_hallowed", nil, true )
                    else
                        return 0
                    end
                    world:remove_item( who, self )
                    return 100
                else
                    return 0
                end
            end
        ]=]
    },
}

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

register_blueprint "terminal_ammo_manufacture"
{
    text = {
        entry = "Manufacture",
        desc  = "Manufacture a stack of the requested ammo type."
    },
    data = {
        terminal = {
            priority = 0,
        },
    },
    attributes = {
        charge_cost = 1,
    },
    callbacks = {
        on_activate = [=[
            function( self, who, level )
                local parent = self:parent()
                uitk.station_use_charges( self )
                world:play_sound( "ui_terminal_accept", parent )

                local data = self.data.terminal
                local id   = data.id
                local e = world:create_entity( id )
                e.stack.amount = data.amount
                if not e.data then
                    e.data = {}
                end
                e.data.from_terminal = true
                level:pickup( who, e, true )
                uitk.station_activate( who, parent, true )
                return 100
            end
        ]=]
    },
}

register_blueprint "perk_te_necrotic"
{
    blueprint = "perk",
    text = {
        name = "Necrotic",
        desc = "auto-repairs by draining the users life force",
    },
    attributes = {
        level = 3,
    },
    callbacks = {
        on_post_command = [[
            function ( self, actor, cmt, weapon, time )
                if time <= 1 then return end
                local attr  = actor.attributes
                local max   = attr.health
                local cur   = actor.health.current
                if cur <= math.ceil( max * 0.1 ) then return end
                local avail = cur - math.ceil( max * 0.1 )
                local armor = self:parent()
                local aattr  = armor.attributes
                if aattr and armor.health then
                    local amax   = armor:attribute( "health" )
                    local acur   = armor.health.current
                    local need   = amax - acur
                    if acur < amax then
                        local regen          = math.min( 10, need )
                        local amount         = math.ceil( regen * ( time / 100 ) )
                        armor.health.current = math.min( amax, acur + amount )
                        actor.health.current = cur - math.min( math.floor( amount / 10 ), avail )
                    end
                end
            end
        ]],
    },
}

register_blueprint "buff_quick_shot"
{
    flags = { EF_NOPICKUP },
    text = {
        name    = "Quickshot",
        desc    = "Your next shot with current weapon is 10% faster",
    },
    callbacks = {
        on_die = [[
            function (self)
                world:mark_destroy(self)
            end
        ]],
        on_rearm = [=[
            function(self, entity, wpn, wpn_next)
                world:mark_destroy(self)
            end
        ]=],
        on_post_command = [[
            function (self, actor, cmt, tgt, time)
                if self.data.applied_this_turn then
                    self.data.applied_this_turn = false
                    world:mark_destroy(self)
                else
                    self.data.applied_this_turn = true
                end
            end
        ]],
    },
    attributes = {
        fire_time = 0.9,
    },
    data = {
        applied_this_turn = false,
    },
    ui_buff = {
        color = GREEN,
    },
}

register_blueprint "perk_wb_loading_holster"
{
    blueprint = "perk",
    lists = {
        group    = "perk_wb",
        keywords = { "reload", "rotary", "shotguns", "explosives", },
    },
    data = {
        perk_group = "reload",
    },
    text = {
        name = "Loading holster",
        desc = "auto-reload the weapon when swapping to it",
    },
    attributes = {},
    callbacks = {
        on_attach = [=[
            function( self, parent )
                if parent and parent.weapon and parent.clip and parent.clip.reload_count and parent.clip.reload_count == -1 then
                     self.text.desc = "your first shot after swapping to it is faster"
                end
            end
        ]=],
        on_rearm = [=[
            function( self, entity, weapon )
                if weapon == self:parent() and weapon.weapon then
                    if weapon.clip and weapon.clip.reload_count and weapon.clip.reload_count == -1 then
                        entity:attach( "buff_quick_shot" )
                    elseif not (weapon.data and weapon.data.no_autoreload) then
                        world:get_level():reload( entity, weapon, true )
                    end
                end
            end
        ]=],
    },
}

register_blueprint "perk_wb_autoloader"
{
    blueprint = "perk",
    lists = {
        group    = "perk_wb",
        keywords = { "reload", "pistols", "smgs", "auto", "rotary", "semi", "shotguns", "explosives", },
    },
    data = {
        perk_group = "reload",
    },
    text = {
        name = "Autoloader",
        desc = "reloads weapon on move",
    },
    callbacks = {
        on_attach = [=[
            function( self, parent )
                if parent and parent.weapon and parent.clip and parent.clip.reload_count and parent.clip.reload_count == -1 then
                     self.text.desc = "Shots fired after moving are faster"
                end
            end
        ]=],
        on_move = [=[
            function ( self, entity )
                local weapon = self:parent()
                if weapon then
                    if weapon.clip and weapon.clip.reload_count and weapon.clip.reload_count == -1 then
                        entity:attach( "buff_quick_shot" )
                    elseif not (weapon.data and weapon.data.no_autoreload) then
                        world:get_level():reload( entity, weapon, true )
                    end
                end
            end
        ]=],
    },
}

register_blueprint "perk_hb_botscanner"
{
    blueprint = "perk",
    lists = {
        group    = "perk_cb",
        keywords = { "visor", "cvisor", "headset" },
    },
    text = {
        name = "Bot scanner",
        desc = "reveals turrets and bots on the minimap",
    },
    callbacks = {
        on_action = [[
            function ( self, entity, time_passed, last )
                if entity then
                    local l   = world:get_level()
                    for e in l:beings() do
                        if e.data and e.data.is_mechanical and not e:child( "disabled" ) and not e:child( "friendly" ) then
                            local btracker = e:equip("bot_tracker")
                            e.minimap.color = btracker.minimap.color
                            e.minimap.always = true
                        end
                    end
                end
                return 0
            end
        ]],
    },
}

register_blueprint "bot_tracker"
{
    flags = { EF_NOPICKUP, },
    minimap = {
        color    = tcolor( LIGHTGRAY, ivec3( 150, 150, 150 ) ),
        priority = 110,
    },
}

register_blueprint "terminal_unlock"
{
    flags = { EF_NOPICKUP },
    text = {
        entry = "Unlock Vault",
        desc  = "Unlock securely locked vault on the current level."
    },
    data = {
        terminal = {
            priority = 10,
        },
    },
    callbacks = {
        on_activate = [=[
            function( self, who, level )
                local parent = self:parent()
                local ar = level:get_area()
                if self.data and self.data.area then
                    ar = self.data.area
                end
                for c in level:coords( {"door_frame","pdoor_frame","door_frame_l","door_frame_r" }, ar ) do
                    local d = level:get_entity(c,"door") or level:get_entity(c,"door2_l") or level:get_entity(c,"door2_r")
                    if d then
                        level:change_state( d, {
                            door_locked    = "door_unlocked",
                            door2_locked_l = "door2_unlocked_l",
                            door2_locked_r = "door2_unlocked_r",
                        })
                        if d.attributes and d.attributes.health == 0 then
                            d.attributes.health = 50
                            d.health.current = 50
                        end
                        level:set_cell_flag( c, EF_NOPATH, false )
                    end
                end
                local parent = self:parent()
                world:destroy( self )
                ui:activate_terminal( who, parent )
            return 100
            end
        ]=]
    },
}

register_blueprint "door_locked"
{
    callbacks = {
        on_activate = [=[
        function( self, who, level )
            if who == world:get_player() then
                world:play_voice( "vo_locked" )
            end
            return 0
        end
        ]=],
        on_die = [[
            function ( self )
                local level = world:get_level()
                level:set_cell_flag( self:parent():get_position() , EF_NOPATH, false )
            end
        ]],
    },
}