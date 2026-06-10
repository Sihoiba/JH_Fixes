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