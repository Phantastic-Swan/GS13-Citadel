/obj/item/organ/genital
	color = "#fcccb3"
	w_class = WEIGHT_CLASS_SMALL
	organ_flags = ORGAN_NO_DISMEMBERMENT|ORGAN_EDIBLE
	var/shape
	var/sensitivity = 1 // wow if this were ever used that'd be cool but it's not but i'm keeping it for my unshit code
	var/genital_flags //see citadel_defines.dm
	var/masturbation_verb = "masturbate"
	var/orgasm_verb = "cumming" //present continous
	var/arousal_verb = "You feel aroused"
	var/unarousal_verb = "You no longer feel aroused"
	var/can_climax				= FALSE
	var/fluid_transfer_factor = 0 //How much would a partner get in them if they climax using this?
	var/size = 2 //can vary between num or text, just used in icon_state strings
	var/datum/reagent/fluid_id = null
	var/fluid_max_volume = 50
	var/fluid_efficiency = 1
	var/fluid_rate = CUM_RATE
	var/fluid_mult = 1
	var/producing = FALSE
	var/last_orgasmed = 0
	var/aroused_state			= FALSE //Boolean used in icon_state strings
	var/aroused_amount			= 50 //This is a num from 0 to 100 for arousal percentage for when to use arousal state icons.
	var/obj/item/organ/genital/linked_organ
	var/linked_organ_slot //used for linking an apparatus' organ to its other half on update_link().
	var/layer_index = GENITAL_LAYER_INDEX //Order should be very important. FIRST vagina, THEN testicles, THEN penis, as this affects the order they are rendered in.
	var/through_clothes			= FALSE
	var/internal				= FALSE
	var/hidden					= FALSE
	var/colourtint				= ""
	var/mode					= ""
	var/obj/item/equipment 		//for fun stuff that goes on the gentials/maybe rings down the line
	var/dontlist				= FALSE
	var/nochange				= FALSE //stops people changing visablity.
	var/starting_size //GS13 EDIT


/obj/item/organ/genital/Initialize(mapload, do_update = TRUE)
	. = ..()
	if(do_update)
		update()

/obj/item/organ/genital/Destroy()
	if(linked_organ?.linked_organ == src)
		linked_organ.linked_organ = null
	linked_organ = null
	. = ..()

//GS13 Port - Make gentials actually produce "reagents"
/obj/item/organ/genital/on_life()
	if(QDELETED(src))
		return
	if(!reagents || !owner)
		return

	generate_fluid(reagents)

/obj/item/organ/genital/proc/set_aroused_state(new_state,cause = "manual toggle")
	if(!(genital_flags & GENITAL_CAN_AROUSE))
		return FALSE
	if(!((HAS_TRAIT(owner,TRAIT_PERMABONER) && !new_state) || HAS_TRAIT(owner,TRAIT_NEVERBONER) && new_state))
		aroused_state = new_state
	if(cause)
		owner.log_message("[src]'s arousal was [new_state ? "enabled" : "disabled"] due to [cause]", LOG_EMOTE)
	return aroused_state

/obj/item/organ/genital/proc/update()
	if(QDELETED(src))
		return
	update_size()
	update_appearance()
	if(genital_flags & UPDATE_OWNER_APPEARANCE && owner && ishuman(owner))
		var/mob/living/carbon/human/H = owner
		H.update_genitals()
		if(owner)//GS13: rebuild overlays on genitals appearance update, for modular clothes
			owner.update_inv_w_uniform()
	if(linked_organ_slot || (linked_organ && !owner))
		update_link()

//exposure and through-clothing code
/mob/living/carbon
	var/list/exposed_genitals = list() //Keeping track of them so we don't have to iterate through every genitalia and see if exposed

/obj/item/organ/genital/proc/is_exposed()
	if(!owner || genital_flags & (GENITAL_INTERNAL|GENITAL_HIDDEN))
		return FALSE
	if(genital_flags & GENITAL_UNDIES_HIDDEN && ishuman(owner))
		var/mob/living/carbon/human/H = owner
		if(!(NO_UNDERWEAR in H.dna.species.species_traits))
			var/datum/sprite_accessory/underwear/top/T = H.hidden_undershirt ? null : GLOB.undershirt_list[H.undershirt]
			var/datum/sprite_accessory/underwear/bottom/B = H.hidden_underwear ? null : GLOB.underwear_list[H.underwear]
			if(zone == BODY_ZONE_CHEST ? (T?.covers_chest || B?.covers_chest) : (T?.covers_groin || B?.covers_groin))
				return FALSE
	if(genital_flags & GENITAL_THROUGH_CLOTHES)
		return TRUE

	switch(zone) //update as more genitals are added
		if(BODY_ZONE_CHEST)
			return owner.is_chest_exposed()
		if(BODY_ZONE_PRECISE_GROIN)
			return owner.is_groin_exposed()

/obj/item/organ/genital/proc/toggle_visibility(visibility, update = TRUE)
	genital_flags &= ~(GENITAL_THROUGH_CLOTHES|GENITAL_HIDDEN|GENITAL_UNDIES_HIDDEN)
	if(owner)
		owner.exposed_genitals -= src
	switch(visibility)
		if(GEN_VISIBLE_ALWAYS)
			genital_flags |= GENITAL_THROUGH_CLOTHES
			if(owner)
				owner.log_message("Exposed their [src]",LOG_EMOTE)
				owner.exposed_genitals += src
			mode = GEN_VISIBLE_ALWAYS
		if(GEN_VISIBLE_NO_CLOTHES)
			if(owner)
				owner.log_message("Hid their [src] under clothes only",LOG_EMOTE)
			mode = GEN_VISIBLE_NO_CLOTHES
		if(GEN_VISIBLE_NO_UNDIES)
			genital_flags |= GENITAL_UNDIES_HIDDEN
			if(owner)
				owner.log_message("Hid their [src] under underwear",LOG_EMOTE)
			mode = GEN_VISIBLE_NO_UNDIES
		if(GEN_VISIBLE_NEVER)
			genital_flags |= GENITAL_HIDDEN
			if(owner)
				owner.log_message("Hid their [src] completely",LOG_EMOTE)
			mode = GEN_VISIBLE_NEVER

	if(update && owner && ishuman(owner)) //recast to use update genitals proc
		var/mob/living/carbon/human/H = owner
		H.update_genitals()

/mob/living/carbon/verb/toggle_genitals()
	set category = "IC"
	set name = "Expose/Hide genitals"
	set desc = "Allows you to toggle which genitals should show through clothes or not."

	if(stat != CONSCIOUS)
		to_chat(usr, "<span class='warning'>You can toggle genitals visibility right now...</span>")
		return

	var/list/genital_list = list()
	for(var/obj/item/organ/genital/G in internal_organs)
		if(!(G.genital_flags & GENITAL_INTERNAL))
			genital_list += G
	if(!genital_list.len) //There is nothing to expose
		return
	//Full list of exposable genitals created
	var/obj/item/organ/genital/picked_organ
	picked_organ = input(src, "Choose which genitalia to expose/hide", "Expose/Hide genitals") as null|anything in genital_list
	if(picked_organ && (picked_organ in internal_organs))
		var/picked_visibility = input(src, "Choose visibility setting", "Expose/Hide genitals") as null|anything in GLOB.genitals_visibility_toggles
		if(picked_visibility && picked_organ && (picked_organ in internal_organs))
			picked_organ.toggle_visibility(picked_visibility)
	return

/mob/living/carbon/verb/toggle_arousal_state()
	set category = "IC"
	set name = "Toggle genital arousal"
	set desc = "Allows you to toggle which genitals are showing signs of arousal."
	var/list/genital_list = list()
	for(var/obj/item/organ/genital/G in internal_organs)
		if(G.genital_flags & GENITAL_CAN_AROUSE)
			genital_list += G
	if(!genital_list.len) //There's nothing that can show arousal
		return
	var/obj/item/organ/genital/picked_organ
	picked_organ = input(src, "Choose which genitalia to toggle arousal on", "Set genital arousal", null) in genital_list
	if(picked_organ)
		var/original_state = picked_organ.aroused_state
		picked_organ.set_aroused_state(!picked_organ.aroused_state)
		if(original_state != picked_organ.aroused_state)
			to_chat(src,"<span class='userlove'>[picked_organ.aroused_state ? picked_organ.arousal_verb : picked_organ.unarousal_verb].</span>")
		else
			to_chat(src,"<span class='userlove'>You can't make that genital [picked_organ.aroused_state ? "unaroused" : "aroused"]!</span>")
		picked_organ.update_appearance()
		if(ishuman(src))
			var/mob/living/carbon/human/human = src
			human.update_genitals()
	return


/obj/item/organ/genital/proc/modify_size(modifier, min = -INFINITY, max = INFINITY)
	fluid_max_volume += modifier*2.5
	fluid_rate += modifier/10
	return

/obj/item/organ/genital/proc/update_size()
	return

/obj/item/organ/genital/proc/update_appearance_genitals()
	if(!owner || owner.stat == DEAD)
		aroused_state = FALSE

/obj/item/organ/genital/proc/generate_fluid(datum/reagents/R)
	//GS13 milky trait - this code currently doesn't do anything
	var/milky_mult = 2
	if(owner != null && HAS_TRAIT(owner, TRAIT_MILKY))
		milky_mult += 2
	var/amount = clamp((fluid_rate * ((world.time - last_orgasmed) / (10 SECONDS)) * fluid_mult),0,fluid_max_volume)
	R.clear_reagents()
	R.maximum_volume = fluid_max_volume
	if(fluid_id)
		R.add_reagent(fluid_id,amount)
	else if(linked_organ?.fluid_id)
		R.add_reagent(linked_organ.fluid_id,amount)
	return TRUE


/obj/item/organ/genital/proc/update_link()
	if(owner)
		if(linked_organ)
			return FALSE
		linked_organ = owner.getorganslot(linked_organ_slot)
		if(linked_organ)
			linked_organ.linked_organ = src
			linked_organ.upon_link()
			upon_link()
			return TRUE
	if(linked_organ)
		linked_organ.linked_organ = null
		linked_organ = null
	return FALSE

//post organ duo making arrangements.
/obj/item/organ/genital/proc/upon_link()
	return

/obj/item/organ/genital/Insert(mob/living/carbon/M, special = FALSE, drop_if_replaced = TRUE)
	. = ..()
	if(.)
		update()
		RegisterSignal(owner, COMSIG_MOB_DEATH, PROC_REF(update_appearance_genitals))
		if(genital_flags & GENITAL_THROUGH_CLOTHES)
			owner.exposed_genitals += src

/obj/item/organ/genital/Remove(special = FALSE)
	. = ..()
	var/mob/living/carbon/C = .
	update()
	if(!QDELETED(C))
		if(genital_flags & UPDATE_OWNER_APPEARANCE && ishuman(C))
			var/mob/living/carbon/human/H = .
			H.update_genitals()
		C.exposed_genitals -= src
		UnregisterSignal(C, COMSIG_MOB_DEATH)

//proc to give a player their genitals and stuff when they log in
/mob/living/carbon/human/proc/give_genitals(clean = FALSE)//clean will remove all pre-existing genitals. proc will then give them any genitals that are enabled in their DNA
	if(clean)
		for(var/obj/item/organ/genital/G in internal_organs)
			qdel(G)
	if (NOGENITALS in dna.species.species_traits)
		return
	if(dna.features["has_vag"])
		give_genital(/obj/item/organ/genital/vagina)
	if(dna.features["has_womb"])
		give_genital(/obj/item/organ/genital/womb)
	if(dna.features["has_balls"])
		give_genital(/obj/item/organ/genital/testicles)
	if(dna.features["has_breasts"])
		give_genital(/obj/item/organ/genital/breasts)
	if(dna.features["has_cock"])
		give_genital(/obj/item/organ/genital/penis)
	if(dna.features["has_butt"])
		give_genital(/obj/item/organ/genital/butt)
	if(dna.features["has_belly"])
		give_genital(/obj/item/organ/genital/belly)
	if(dna.features["has_taur_belly"]) //GS13 EDIT TAUR BELLY
		give_genital(/obj/item/organ/genital/taur_belly)

/mob/living/carbon/human/proc/give_genital(obj/item/organ/genital/G)
	if(!dna || (NOGENITALS in dna.species.species_traits) || getorganslot(initial(G.slot)))
		return FALSE
	G = new G(null, FALSE)
	G.get_features(src)
	G.Insert(src)
	return G

/obj/item/organ/genital/proc/get_features(mob/living/carbon/human/H)
	return

/mob/living/carbon/human/proc/update_genitals()
	if(QDELETED(src))
		return
	var/static/list/relevant_layers = list("[GENITALS_BEHIND_LAYER]" = "BEHIND", "[GENITALS_FRONT_LAYER]" = "FRONT")
	var/static/list/layers_num
	if(!layers_num)
		for(var/L in relevant_layers)
			LAZYSET(layers_num, L, text2num(L))
	for(var/L in relevant_layers) //Less hardcode
		remove_overlay(layers_num[L])
	remove_overlay(GENITALS_EXPOSED_LAYER)
	if(!LAZYLEN(internal_organs) || ((NOGENITALS in dna.species.species_traits) && !genital_override) || HAS_TRAIT(src, TRAIT_HUSK))
		return

	//start scanning for genitals

	var/list/gen_index[GENITAL_LAYER_INDEX_LENGTH]
	var/list/genitals_to_add
	var/list/fully_exposed
	for(var/obj/item/organ/genital/G in internal_organs)
		if(G.is_exposed()) //Checks appropriate clothing slot and if it's through_clothes
			LAZYADD(gen_index[G.layer_index], G)
	for(var/L in gen_index)
		if(L) //skip nulls
			LAZYADD(genitals_to_add, L)
	if(!genitals_to_add)
		return
	//Now we added all genitals that aren't internal and should be rendered
	//start applying overlays
	for(var/layer in relevant_layers)
		var/list/standing = list()
		var/layertext = relevant_layers[layer]
		for(var/A in genitals_to_add)
			var/obj/item/organ/genital/G = A
			var/datum/sprite_accessory/S
			var/size = G.size
			switch(G.type)
				if(/obj/item/organ/genital/penis)
					S = GLOB.cock_shapes_list[G.shape]
				if(/obj/item/organ/genital/testicles)
					S = GLOB.balls_shapes_list[G.shape]
				if(/obj/item/organ/genital/vagina)
					S = GLOB.vagina_shapes_list[G.shape]
				if(/obj/item/organ/genital/breasts)
					S = GLOB.breasts_shapes_list[G.shape]
				if(/obj/item/organ/genital/butt)
					S = GLOB.butt_shapes_list[G.shape]
				if(/obj/item/organ/genital/belly)
					S = GLOB.belly_shapes_list[G.shape]
				if(/obj/item/organ/genital/taur_belly) //GS13 EDIT TAUR BELLY
					S = GLOB.taur_belly_shapes_list[G.shape]

			if(!S || S.icon_state == "none")
				continue
			var/aroused_state = G.aroused_state && S.alt_aroused
			var/accessory_icon = S.icon
			var/do_center = S.center
			var/dim_x = S.dimension_x
			var/dim_y = S.dimension_y
			if(G.genital_flags & GENITAL_CAN_TAUR && S.taur_icon && (!S.feat_taur || dna.features[S.feat_taur]) && dna.species.mutant_bodyparts["taur"])
				var/datum/sprite_accessory/taur/T = GLOB.taur_list[dna.features["taur"]]
				if(T?.taur_mode & S.accepted_taurs)
					accessory_icon = S.taur_icon
					do_center = TRUE
					dim_x = S.taur_dimension_x
					dim_y = S.taur_dimension_y

			var/mutable_appearance/genital_overlay = mutable_appearance(accessory_icon, layer = -layer)
			if(do_center)
				genital_overlay = center_image(genital_overlay, dim_x, dim_y)

			if(dna.species.use_skintones && dna.features["genitals_use_skintone"])
				genital_overlay.color = SKINTONE2HEX(skin_tone)
			else
				switch(S.color_src)
					if("cock_color")
						genital_overlay.color = "#[dna.features["cock_color"]]"
					if("balls_color")
						genital_overlay.color = "#[dna.features["balls_color"]]"
					if("breasts_color")
						genital_overlay.color = "#[dna.features["breasts_color"]]"
					if("vag_color")
						genital_overlay.color = "#[dna.features["vag_color"]]"
					if("butt_color")
						genital_overlay.color = "#[dna.features["butt_color"]]"
					if("belly_color")
						genital_overlay.color = "#[dna.features["belly_color"]]"
					if("taur_belly_color")	//GS13 EDIT TAUR BELLY
						genital_overlay.color = "#[dna.features["taur_belly_color"]]"

			//GS13 -	Because each genital's file has different naming schemes for their icon_states,
			//			I've made it so each type is checked and the icon_state built based on which genital it is
			switch(G.slot)
				if("belly")
					genital_overlay.icon = G.icon
					genital_overlay.icon_state = "[G.icon_state]_[aroused_state]_[layertext]"
				if("taur_belly") //GS13 EDIT TAUR BELLY
					//genital_overlay.icon = G.icon
					genital_overlay.icon_state = "[G.icon_state]_[aroused_state]_[layertext]"
				if("breasts")
					genital_overlay.icon_state = "[G.slot]_[S.icon_state]_[size][(dna.species.use_skintones && !dna.skin_tone_override) ? "-s" : ""]_[aroused_state]_[layertext]"
				if("penis")
					genital_overlay.icon_state = "[G.slot]_[S.icon_state]_[size]_[aroused_state]_[layertext]"
				if("testicles")
					genital_overlay.icon_state = "[G.slot]_[S.icon_state]_[size]_[aroused_state]_[layertext]"
				if("vagina")
					genital_overlay.icon_state = "[G.slot][(dna.species.use_skintones && !dna.skin_tone_override) ? "-s" : ""]_[S.icon_state]_[size]_[aroused_state]_[layertext]"
				if("butt")
					genital_overlay.icon_state = "[G.slot]_[S.icon_state]_[size][(dna.species.use_skintones && !dna.skin_tone_override) ? "_s" : ""]_[aroused_state]_[layertext]"
			//GS13 END
			if(layers_num[layer] == GENITALS_FRONT_LAYER && G.genital_flags & GENITAL_THROUGH_CLOTHES)
				genital_overlay.layer = -GENITALS_EXPOSED_LAYER
				LAZYADD(fully_exposed, genital_overlay)
			else
				genital_overlay.layer = -layers_num[layer]
				standing += genital_overlay

		if(LAZYLEN(standing))
			overlays_standing[layers_num[layer]] = standing

	if(LAZYLEN(fully_exposed))
		overlays_standing[GENITALS_EXPOSED_LAYER] = fully_exposed
		apply_overlay(GENITALS_EXPOSED_LAYER)

	for(var/L in relevant_layers)
		apply_overlay(layers_num[L])


//Checks to see if organs are new on the mob, and changes their colours so that they don't get crazy colours.
/mob/living/carbon/human/proc/emergent_genital_call()
	if(!client.prefs.arousable)
		return FALSE

	var/organCheck = locate(/obj/item/organ/genital) in internal_organs
	var/breastCheck = getorganslot(ORGAN_SLOT_BREASTS)
	var/willyCheck = getorganslot(ORGAN_SLOT_PENIS)
	var/buttCheck = getorganslot(ORGAN_SLOT_BUTT)
	var/ballCheck = getorganslot(ORGAN_SLOT_TESTICLES)
	var/bellyCheck = getorganslot(ORGAN_SLOT_BELLY)
	var/taurbellyCheck = getorganslot(ORGAN_SLOT_TAUR_BELLY)	//GS13 EDIT TAUR BELLY

	if(organCheck == FALSE)
		if(ishuman(src) && dna.species.use_skintones)
			dna.features["genitals_use_skintone"] = TRUE
		if(dna.species.fixed_mut_color)
			dna.features["cock_color"] = "[dna.species.fixed_mut_color]"
			dna.features["breasts_color"] = "[dna.species.fixed_mut_color]"
			dna.features["butt_color"] = "[dna.species.fixed_mut_color]"
			dna.features["belly_color"] = "[dna.species.fixed_mut_color]"
			dna.features["testicles_color"] = "[dna.species.fixed_mut_color]"
			dna.features["taur_belly_color"] = "[dna.species.fixed_mut_color]"	//GS13 EDIT TAUR BELLY
			return
		//So people who haven't set stuff up don't get rainbow surprises.
		dna.features["cock_color"] = "[dna.features["mcolor"]]"
		dna.features["breasts_color"] = "[dna.features["mcolor"]]"
		dna.features["butt_color"] = "[dna.features["mcolor"]]"
		dna.features["belly_color"] = "[dna.features["mcolor"]]"
		dna.features["testicles_color"] = "[dna.features["mcolor"]]"
		dna.features["taur_belly_color"] = "[dna.features["mcolor"]]"	//GS13 EDIT TAUR BELLY
	else //If there's a new organ, make it the same colour.
		if(breastCheck == FALSE)
			dna.features["breasts_color"] = dna.features["cock_color"]
		else if (willyCheck == FALSE)
			dna.features["cock_color"] = dna.features["breasts_color"]
		else if (buttCheck == FALSE)
			dna.features["butt_color"] = dna.features["butt_color"]
		else if (bellyCheck == FALSE)
			dna.features["belly_color"] = dna.features["belly_color"]
		else if (ballCheck == FALSE)
			dna.features["testicles_color"] = dna.features["testicles_color"]
		else if (taurbellyCheck == FALSE)
			dna.features["taur_belly_color"] = dna.features["taur_belly_color"]	//GS13 EDIT TAUR BELLY
	return TRUE
