nova.require "data/lua/gfx/common"

register_gfx_blueprint "axe_large"
{
	uisprite = {
		icon = "data/texture/ui/icons/ui_weapon_axe_large",
	},
	weapon_fx = {
		advance   = 0.5,
	},
	equip = {
		animation = "to_sword",
		target    = "RigRHandWeaponMount",
		alt_target = "RigLHandWeaponMount",
	},
	vision = {
		pure_floor = true,
	},
	scene = {},
	{
        render = {
			mesh     = "data/model/axe_large.nmd:axe_large_01",
			material = "data/texture/weapons/melee/axe_large_01/A/axe_large_01",
		},
	},
}

register_gfx_blueprint "exo_ancient_sword"
{
	uisprite = {
		icon = "data/texture/ui/icons/ui_weapon_ancient_alien_sword",
		color = vec4( 0.6, 0.0, 0.6, 1.0 ),
	},
	weapon_fx = {
		advance   = 0.5,
	},
	equip = {
		animation = "to_sword",
		target    = "RigRHandWeaponMount",
		alt_target = "RigLHandWeaponMount",
	},
	vision = {
		pure_floor = true,
	},
	scene = {},
	{
        render = {
			mesh     = "data/model/ancient_alien_sword.nmd:ancient_alien_sword_01",
			material = "data/texture/boss_io_01/A/ancient_alien_sword_01",
		},
	},
}