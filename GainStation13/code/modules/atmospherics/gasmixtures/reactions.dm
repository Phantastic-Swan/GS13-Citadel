/datum/gas_reaction/lipoifium_formation
	priority = 7
	name = "Lipoifium Formation"
	id = "lipoifium_formation"

/datum/gas_reaction/lipoifium_formation/init_reqs()
	min_requirements = list(
		"MAX_TEMP" = 100,
		GAS_PLASMA = MINIMUM_MOLE_COUNT,
		GAS_TRITIUM = MINIMUM_MOLE_COUNT
	)

/datum/gas_reaction/lipoifium_formation/react(datum/gas_mixture/air)
	var/plasma_moles = air.get_moles(GAS_PLASMA)
	var/tritium_moles = air.get_moles(GAS_TRITIUM)
	if (plasma_moles < MINIMUM_MOLE_COUNT || tritium_moles < MINIMUM_MOLE_COUNT)
		return NO_REACTION

	var/temperature = air.return_temperature()
	var/reaction_efficiency = 0
	if (temperature <= 5)
		reaction_efficiency = 1
	else if (temperature >= 100)
		return NO_REACTION
	else
		reaction_efficiency = -((temperature - 5) / 95) + 1		// will equal 1 at 5 kelvin, and will linearly fall until 0 at 100k

	
	var/old_heat_capacity = air.heat_capacity()

	var/used_moles = min((reaction_efficiency * min(plasma_moles, tritium_moles) * 0.5), 10)
	var/energy_released = used_moles * FIRE_CARBON_ENERGY_RELEASED
	
	air.adjust_moles(GAS_FAT, used_moles)
	air.adjust_moles(GAS_TRITIUM, -used_moles)
	air.adjust_moles(GAS_PLASMA, -used_moles)
	var/new_heat_capacity = air.heat_capacity()
	air.set_temperature(max((temperature * old_heat_capacity + energy_released) / new_heat_capacity, TCMB))

	return REACTING
