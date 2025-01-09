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
			// listen I know I can debug this but sometimes having this show up in chat without a pause is more convenient
			// message_admins("Lipoifium pp is [gas_breathed]")
			// message_admins("Lipoifium moles are [lipoifium_moles]")
			H.adjust_fatness(2 * gas_breathed, FATTENING_TYPE_ATMOS)
			// var/BFI_gained =
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
		var/gas_breathed = PP_MOLES(galbanium_moles) // this does the same thing as the bit below but I think this is more readable
		#undef PP_MOLES
		if(gas_breathed > 0)
			H.adjust_fatness(4 * gas_breathed, FATTENING_TYPE_ATMOS)
			H.adjust_perma(gas_breathed / 10, FATTENING_TYPE_ATMOS)
			breath.adjust_moles(GAS_GALB, -gas_breathed)
			// TODO: the entire code below is a workaround for default odor not workin
			var/smell_chance = min(galbanium_moles * 100 / total_moles, 7.5)
			if(prob(smell_chance))
				to_chat(owner, "<span class='notice'>You can smell rampant obesity.</span>")

/obj/item/organ/lungs/check_breath(datum/gas_mixture/breath, mob/living/carbon/human/H)
	lipoifium_breathing(breath, H)
	galbanium_breathing(breath, H)
	. = ..()
