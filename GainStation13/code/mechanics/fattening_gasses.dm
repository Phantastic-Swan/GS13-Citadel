/obj/item/organ/lungs/proc/lipoifium_breathing(datum/gas_mixture/breath, mob/living/carbon/human/H)
	if(!breath)
		return
	
	if(breath.total_moles() == 0)
		return

	var/total_moles = breath.total_moles()
	var/lipoifium_moles = breath.get_moles(GAS_FAT)
	var/pressure = breath.return_pressure()
	var/lipoifium_partial_pressure = pressure * lipoifium_moles / total_moles
	// #define PP_MOLES(X) ((X / total_moles) * pressure) // this needs to be here because spaghetti, I'm sorry
	if(lipoifium_moles <= 0)
		return

	var/fatness_to_add = lipoifium_moles * 150	// each mole gives 150 BFI. Now, you may think that that's A METRIC FUCKTON, but in reality, because lungs by default are 0.5 liters, at 20C 101.325 kPa that's just 0.02 moles
	fatness_to_add *= 10 * lipoifium_moles / total_moles
	H.adjust_fatness(fatness_to_add + 5, FATTENING_TYPE_ATMOS)
	breath.set_moles(GAS_FAT, 0)
	// TODO: the 3 lines below are a workaround for default odor not working
	// The problem seems to be auxmos'es get_gasses function not acknowledging that lipoifium exists
	// which is strange, considering that everything else regarding this gas and auxmos works
	var/smell_chance = clamp((lipoifium_partial_pressure - 100) / 2.5, 0, 20)
	// var/smell_chance = min(lipoifium_moles * 100 / total_moles, 5)
	if(prob(smell_chance))
		to_chat(owner, "<span class='notice'>" + pick("You can smell lard.", "Your clothes feel tight.", "You can feel yourself expand.") + "</span>")


/obj/item/organ/lungs/check_breath(datum/gas_mixture/breath, mob/living/carbon/human/H)
	lipoifium_breathing(breath, H)
	. = ..()
