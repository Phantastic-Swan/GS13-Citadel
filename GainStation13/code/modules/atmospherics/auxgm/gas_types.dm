/datum/gas/lipoifium
	id = GAS_FAT
	specific_heat = 10
	name = "Lipoifium"
	color = "#e2e1b1"
	odor = "that this is a function that wasn't working, but it now, for some reason, is. You should speak to the gods about this and the conditions under which it happened"
	odor_strength = 1 // TODO: doesn't work for now
	price = 3
	powermix = 1
	heat_penalty = 10
	fire_burn_rate = 10
	fire_temperature = 15000
	fire_products = list(GAS_GALB = 1)
	enthalpy = -5000

/datum/gas/galbanium
	id = GAS_GALB
	specific_heat = 50
	name = "Galbanium"
	moles_visible = 20 * MOLES_GAS_VISIBLE
	color = "#E70C0C"
	price = 6
	powermix = 1
	heat_penalty = 4
	powerloss_inhibition = 0.4
	fire_burn_rate = 1
	fire_temperature = 22500
	fire_products = list(GAS_SLIM = 0.1, GAS_PLASMA = 5)
	enthalpy = 250000

/datum/gas/lipocidium
	id = GAS_SLIM
	specific_heat = 15
	name = "Lipocidium"
	color = "#F0FFF0"
	price = 3
	powermix = -1
	heat_penalty = 1.5
	heat_resistance = 1

/datum/gas/macerinium
	id = GAS_MACER
	specific_heat = 25
	name = "Macerinium"
	moles_visible = 40 * MOLES_GAS_VISIBLE
	color = "#3b0ce7"
	price = 6
	powermix = -1
	heat_penalty = -1
