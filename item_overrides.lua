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
                    parent.data.used_cells = (parent.clip.ammo == world:hash("ammo_cells"))
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