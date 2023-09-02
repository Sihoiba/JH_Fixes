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
					parent.clip.ammo = ""
					self.text.desc = "this weapon doesn't need ammo when reloading"
				elseif parent.weapon and parent.weapon.type == world:hash("melee") then					
					self.text.desc = "this weapon is sharper"
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
					if parent.data and parent.data.perk and parent.data.perk.exotic == "perk_we_rocket_rack" then
						self.attributes.clip_size = 5
					end
					if parent.data and parent.data.perk and parent.data.perk.exotic == "perk_we_grenade_drum" then
						self.attributes.clip_size = 6
					end
					parent.clip.count = parent.clip.count + self.attributes.clip_size
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