/obj/item/organ/lungs/proc/lipoifium_breathing(datum/gas_mixture/breath, mob/living/carbon/human/H)
	if(breath)
		var/pressure = breath.return_pressure()
		var/total_moles = breath.total_moles()
		var/lipoifium_moles = breath.get_moles(GAS_FAT)
		#define PP_MOLES(X) ((X / total_moles) * pressure)
		var/gas_breathed = PP_MOLES(lipoifium_moles) // this does the same thing as the bit below but I think this is more readable
		#undef PP_MOLES
		// #define PP(air, gas) PP_MOLES(air.get_moles(gas))
		// var/gas_breathed = PP(breath, GAS_FAT)
		if(gas_breathed > 0)
			H.adjust_fatness(2 * gas_breathed, FATTENING_TYPE_ATMOS)
			breath.adjust_moles(GAS_FAT, -gas_breathed)
			// TODO: the entire code below is a workaround for default odor not working
			// The problem seems to be auxmos'es get_gasses function not acknowledging that lipoifium exists
			// which is strange, considering that everything else regarding this gas and auxmos works
			// I do not know what kind of spaghetti coding must be going on there, but I pray god has in his
			// care the poor sods who have to work on that
			var/smell_chance = min(lipoifium_moles * 100 / total_moles, 7.5)
			if(prob(smell_chance))
				to_chat(owner, "<span class='notice'>You can smell lard.</span>")

/obj/item/organ/lungs/proc/galbanium_breathing(datum/gas_mixture/breath, mob/living/carbon/human/H)
	if(breath)
		var/pressure = breath.return_pressure()
		var/total_moles = breath.total_moles()
		var/galbanium_moles = breath.get_moles(GAS_GALB)
		#define PP_MOLES(X) ((X / total_moles) * pressure)
		var/gas_breathed = PP_MOLES(galbanium_moles)
		#undef PP_MOLES
		if(gas_breathed > 0)
			H.adjust_fatness(4 * gas_breathed, FATTENING_TYPE_ATMOS)
			H.adjust_perma(gas_breathed / 10, FATTENING_TYPE_ATMOS)
			breath.adjust_moles(GAS_GALB, -gas_breathed)
			// TODO: the entire code below is a workaround for default odor not workin
			var/smell_chance = min(galbanium_moles * 100 / total_moles, 7.5)
			if(prob(smell_chance))
				to_chat(owner, "<span class='notice'>You can smell rampant obesity.</span>")

/obj/item/organ/lungs/proc/fattening_gasses(datum/gas_mixture/breath, mob/living/carbon/human/H)
	var/pressure = breath.return_pressure()
	var/total_moles = breath.total_moles()
	#define PP_MOLES(X) ((X / total_moles) * pressure)
	var/lipoifium_PP = PP_MOLES(breath.get_moles(GAS_FAT))
	H.adjust_fatness(2 * lipoifium_PP, FATTENING_TYPE_ATMOS)
	// breath.adjust_moles(GAS_FAT, -breath.get_moles(GAS_FAT))
	breath.set_moles(GAS_FAT, 0)

	var/galbanium_PP = PP_MOLES(breath.get_moles(GAS_GALB))
	H.adjust_fatness(4 * galbanium_PP, FATTENING_TYPE_ATMOS)
	H.adjust_perma(galbanium_PP / 10, FATTENING_TYPE_ATMOS)
	breath.set_moles(GAS_GALB, 0)

	var/lipocidium_PP = PP_MOLES(breath.get_moles(GAS_SLIM))
	if(HAS_TRAIT(H, TRAIT_LIPOLICIDE_TOLERANCE))
		H.adjust_fatness(-0.5 * lipocidium_PP, FATTENING_TYPE_WEIGHT_LOSS)
	else
		H.adjust_fatness(-lipocidium_PP, FATTENING_TYPE_WEIGHT_LOSS)
	breath.set_moles(GAS_SLIM, 0)

	var/macerinium_PP = PP_MOLES(breath.get_moles(GAS_MACER))
	H.adjust_fatness(-5 * macerinium_PP,FATTENING_TYPE_WEIGHT_LOSS)
	H.adjust_perma(-macerinium_PP, FATTENING_TYPE_WEIGHT_LOSS)
	breath.set_moles(GAS_MACER, 0)

	#undef PP_MOLES

/obj/item/organ/lungs/check_breath(datum/gas_mixture/breath, mob/living/carbon/human/H)
	// lipoifium_breathing(breath, H)
	// galbanium_breathing(breath, H)
	fattening_gasses(breath, H)
	. = ..()
