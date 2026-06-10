nova.require "item_overrides"
nova.require "perk_overrides"
nova.require "trait_overrides"

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

register_blueprint "armor_alerter"
{
    flags = { EF_NOPICKUP },
    data = {
        alerted_armor = false,
        alerted_head = false,
    },
    callbacks = {
        on_action = [=[
            function ( self, entity )
                local alert_armor = false
                local alert_head = false
                local head = entity:get_slot("head")
                local armor = entity:get_slot("armor")

                if not self.data.alerted_armor and armor and not armor.armor.permanent and armor.health and armor.health.current < 100 and armor.health.current > 0 then
                    alert_armor = true
                    self.data.alerted_armor = true
                elseif self.data.alerted_armor and armor and not armor.armor.permanent and armor.health and armor.health.current > 99 then
                    self.data.alerted_armor = false
                end

                if not self.data.alerted_head and head and not head.armor.permanent and head.health and head.health.current < 100 and head.health.current > 0 then
                    alert_head = true
                    self.data.alerted_head = true
                elseif self.data.alerted_head and head and not head.armor.permanent and head.health and head.health.current > 99 then
                    self.data.alerted_head = false
                end

                if alert_armor or alert_head then
                    ui:set_hint( "{WYOUR ARMOR AND/OR HELMET ARE AT RISK}", 5001, -2 )
                end

            end
        ]=],
    },
}
world.register_on_entity(function(x) if x.data and x.data.ai and x.data.ai.group == "player" then x:attach("armor_alerter") end end)