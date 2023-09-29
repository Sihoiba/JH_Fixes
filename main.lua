nova.require "libraries/bresenham"

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

register_blueprint "man_mdf"
{
    blueprint = "manufacturer",
    text = {
		name     = "Mimir Defence Force",
        prefixed = "MDF",
		desc     = "{!+1} optimal weapon range",
    },
    attributes = {
		opt_distance = 0,
		melee_guard = 0,
    },
	callbacks = {
		on_attach = [=[
			function( self, parent )
				if parent and parent.weapon then
					if ( parent.weapon.type ~= world:hash("melee") ) then
						self.attributes.opt_distance = 1
						parent.text.prefix = self.text.prefixed
						self.text.desc = "{!+1} optimal weapon range"
					else
						self.attributes.melee_guard = 10
						parent.text.prefix = self.text.prefixed
						self.text.desc = "{!+10%} melee guard"
					end		
				end
			end
		]=],
	},
}

register_blueprint "man_idr"
{
	blueprint = "manufacturer",
	text = {
		name     = "Io Defence Reserve",
		prefixed = "IDR",
		desc     = "{!-50%} reload time",
	},
	attributes = {
		reload_time = 1.0,
		melee_guard_dist = 0,
	},
	callbacks = {
		on_attach = [=[
			function( self, parent )
				if parent and parent.weapon then
					if ( parent.weapon.type ~= world:hash("melee") ) then
						self.attributes.reload_time = 0.5
						parent.text.prefix = self.text.prefixed
						self.text.desc = "{!-50%} reload time"
					else
						self.attributes.melee_guard_dist = 1
						parent.text.prefix = self.text.prefixed
						self.text.desc = "increases melee guard range by 1"
					end		
				end
			end
		]=],
	},
}

register_blueprint "perk_wa_sustain"
{
	blueprint = "perk", 
	lists = {
		group    = "perk_wa",
		keywords = { "reload", "pistols", "smgs", "auto", "rotary", "semi", "shotguns", "explosives", },
	},
	data = {
		perk_group = "reload",
	},
	text = {
		name = "Sustain",
		desc = "return bullets to the magazine on kill",
	},
	attributes = {
		level = 2,
	},
	callbacks = {
		on_attach = [=[
			function( self, parent )
				if parent and parent.weapon then
					if ( parent.weapon.type ~= world:hash("melee") ) then						
						self.text.desc = "return bullets to the magazine on kill"
					else
						self.text.desc = "repairs armor on a melee kill"
					end		
				end
			end
		]=],
		on_kill = [=[
			function ( self, entity, target, weapon )
				if target then
					if target.data and target.data.ai then
						if weapon == self:parent() and weapon.weapon and weapon.weapon.type ~= world:hash("melee") then
							local shots     = weapon.attributes.shots or 1
							local clip_size = weapon:attribute("clip_size") or 1
							local shot_cost = weapon.weapon.shot_cost
							local refund    = shots * shot_cost

							if weapon.clip then
								weapon.clip.count = math.min( weapon.clip.count + refund, math.max( clip_size, weapon.clip.count ) )
							end
						elseif weapon == self:parent() and weapon.weapon and weapon.weapon.type == world:hash("melee") then										
							local fixa   = core.repair_item( entity, "armor", 0.05 )
							local fixh   = core.repair_item( entity, "head", 0.05 )
							if fixa or fixh then
								ui:spawn_fx( entity, "fx_armor", entity )
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
				if parent.weapon and parent.clip then
					parent.data.before_nano = {}
					parent.data.before_nano.ammo = parent.clip.ammo
					parent.clip.ammo = ""
					self.text.desc = "this weapon doesn't need ammo when reloading"
				elseif parent.weapon and parent.weapon.type == world:hash("melee") then
					parent.data.before_nano = {}				
					self.text.desc = "this weapon is sharper"
					
					parent.data.before_nano.damage_type	= parent.weapon.damage_type
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

register_blueprint "perk_tb_loadingfeed"
{
	blueprint = "perk",
	lists = {
		group    = "perk_cb",
		keywords = { "reload", "armor", },
	},
	data = {
		perk_group = "reload",
	},
	text = {
		name = "Loading feed",
		desc = "partially reloads SMGs, autos, semis and rotaries on the move",
	},
	callbacks = {
		on_move = [=[
			function ( self, entity )
				local weapon = gtk.get_weapon_group( entity, { "smgs", "auto", "semi", "rotary" } )
				if weapon and weapon.weapon then
					local shots = weapon.attributes.shots or 1
					local cost  = weapon.weapon.shot_cost
					local clip = weapon.attributes.clip_size
					if cost > 0 and clip ~= 99 then
						world:get_level():reload( entity, weapon, true, shots * cost )
					elseif cost > 0 and clip == 99 and weapon.clip.count == 0 then
						world:get_level():reload( entity, weapon, true, clip )
					end
				end
			end
		]=],
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
				if parent.weapon then					
					local clip = parent.attributes.clip_size
					if clip ~= 99 then
						self.attributes.reload_mod = 0.5
						self.text.desc = "reload ammo efficiency doubled"
					elseif clip == 99 then
						self.attributes.shot_cost_mod = 0.75
						self.text.desc = "75% ammo consumption"
					end
				end
			end
		]],		
	},
}

register_blueprint "ktrait_master_gunrunner"
{
	blueprint = "trait",
	text = {
		name   = "GUNRUNNER",
		desc   = "MASTER TRAIT - reduce attack time after move and reload weapons",
		full   = "Run and gun is your motto! No wasting time reloading {?curse|shit|guns}, so you do it while you move. Also, while you move you prep for attack, so you attack faster, and with {!+1} optimal distance!\n\n{!LEVEL 1} - {!50%} attack time after move\n{!LEVEL 2} - {!25%} attack time and {!+25%} flat damage after move\n{!LEVEL 3} - {!+50%} flat damage after move\n\nYou can pick only one MASTER trait per character.",
		abbr   = "MGU",
		bdesc  = "{!GUNRUNNER} bonuses are active",
		bdesc1 = "firing takes {!50%} regular attack time, {!+1} optimal distance",
		bdesc2 = "firing takes {!25%} regular attack time, {!+1} optimal distance, {!+25%} damage",
		bdesc3 = "firing takes {!25%} regular attack time, {!+1} optimal distance, {!+50%} damage",
	},
	ui_buff = {
		color     = GREEN,
		priority  = -1,
		style     = 2,
		attribute = "moved",
	},
	attributes = {
		level          = 1,
		moved          = 0,
		apply          = 0,
		fire_time      = 1.0,
		opt_distance   = 0,
		damage_mult    = 1.0,
		gr_fire_time   = 1.0,
		gr_damage_mult = 1.0,
		gr_opt_distance= 0,
	},
	callbacks = {
		on_activate = [=[
			function(self,entity)
				local tlevel, t = gtk.upgrade_master( entity, "ktrait_master_gunrunner" )
				local attr      = t.attributes
				if tlevel == 1 then
					world:set_text( t, "bdesc", "bdesc1" )
					attr.gr_fire_time    = 0.5
					attr.gr_damage_mult  = 1.0
					attr.gr_opt_distance = 1
				elseif tlevel == 2 then
					world:set_text( t, "bdesc", "bdesc2" )
					attr.gr_fire_time    = 0.25
					attr.gr_damage_mult  = 1.25
					attr.gr_opt_distance = 1
				elseif tlevel == 3 then
					world:set_text( t, "bdesc", "bdesc3" )
					attr.gr_fire_time    = 0.25
					attr.gr_damage_mult  = 1.5
					attr.gr_opt_distance = 1
				end
			end
		]=],
		on_pre_command = [[
			function ( self, actor, cmt, tgt )
				local attr   = self.attributes
				if attr.moved == 1 then
					attr.moved = 0
					attr.apply = 1
				end
				return 0
			end
		]],
		on_post_command = [[
			function ( self, actor, cmt, weapon, time )
				if time <= 1 then
					local attr   = self.attributes
					if attr.apply == 1 then
						attr.moved = 1
						attr.apply = 0
					end
					return
				end
				self.attributes.apply = 0
			end
		]],
		on_move = [=[
			function ( self, user )
				local sattr  = self.attributes
				sattr.moved  = 1
				local weapon = user:get_weapon()
				local function do_reload( weapon )
					if weapon then
						local wd     = weapon.weapon
						if not wd then return 0 end
						local cd     = weapon.clip
						if cd then
							local clip_size = weapon:attribute( "clip_size", wd.group )
							if cd.count < clip_size and clip_size < 99 then
								nova.log("Reload non nail "..tostring(cd.count).." of "..tostring(clip_size))
								world:get_level():reload( user, weapon, true )
							elseif cd.count < clip_size and cd.count == 0 and clip_size >= 99 then	
								nova.log("Reload nail "..tostring(cd.count).." of "..tostring(clip_size))
								world:get_level():reload( user, weapon, true )
							end
						end
					end
				end
				do_reload( user:get_weapon(0) )
				do_reload( user:get_weapon(1) )
			end
		]=],
		on_aim = [=[
			function ( self, entity, target, weapon )
				local attr = self.attributes
				if target and (( attr.moved == 1 ) or ( attr.apply == 1 )) then
					attr.fire_time    = attr.gr_fire_time
					attr.opt_distance = attr.gr_opt_distance
					attr.damage_mult  = attr.gr_damage_mult
				else
					attr.fire_time    = 1.0
					attr.opt_distance = 0
					attr.damage_mult  = 1.0
				end
			end
		]=],
	},
}

function ignite_along_line(self, level, source, end_point) 
	local start_point = source:get_position()
	local points, _ = line(start_point.x, start_point.y, end_point.x, end_point.y, function (x,y)
		return true
	end)
	local burn_amount = world:get_player().attributes.fireangel_burn
	local burn_slevel = core.get_status_value( burn_amount, "ignite", world:get_player() )
	local flame_amount = world:get_player().attributes.fireangel_flame
	local flame_slevel = core.get_status_value( flame_amount, "ignite", world:get_player() )
	nova.log("Fireangel beam mod checking for targets")	
	local burn_point = source:get_position()
	for _, v in ipairs(points) do
		if v.x == start_point.x and v.y == start_point.y then
			nova.log("Fireangel beam mod not igniting player")
		else  	
			burn_point.x = v.x
			burn_point.y = v.y
			for e in world:get_level():entities( burn_point ) do
				nova.log("Fireangel beam mod entity found on line")				
				if e.data and e.data.can_burn then
					nova.log("Fireangel beam mod trying to burn "..e.text.name)
					core.apply_damage_status( e, "burning", "ignite", burn_slevel, world:get_player())								
				end					
			end
			nova.log("Fireangel beam mod placing flames x"..burn_point.x..", y"..burn_point.y)
			gtk.place_flames( burn_point, math.max( flame_slevel + math.random(3), 2 ), 300 + math.random(400) + 50 )
		end
		
	end
end

register_blueprint "kperk_fireangel"
{
	flags = { EF_NOPICKUP }, 
	callbacks = {
		on_area_damage = [[
			function ( self, weapon, level, c, damage, distance, center, source, is_repeat )				
				nova.log("Using modded fireangel perk")
				if not is_repeat then					
					if weapon and weapon.ui_target and weapon.ui_target.type == world:hash("beam") then																		
						ignite_along_line(self, level, source, c)						
					else
						for e in level:entities( c ) do
							if e.data and e.data.can_burn then			
								local amount = world:get_player().attributes.fireangel_burn
								local slevel = core.get_status_value( amount, "ignite", world:get_player() )
								core.apply_damage_status( e, "burning", "ignite", slevel, world:get_player() )
							end
						end
					end	
				end
				if distance < 6 then
					if distance < 1 then distance = 1 end
					local amount = world:get_player().attributes.fireangel_flame
					local slevel = core.get_status_value( math.max( amount + 1 - distance, 1 ), "ignite", world:get_player() )
					gtk.place_flames( c, math.max( slevel + math.random(3), 2 ), 300 + math.random(400) + distance * 50 )
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