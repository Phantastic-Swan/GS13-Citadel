//THIS FILE CONTAINS CONSTANTS, PROCS, AND OTHER THINGS//
/////////////////////////////////////////////////////////

/proc/get_matrix_largest()
	var/matrix/mtrx=new()
	return mtrx.Scale(2)
/proc/get_matrix_large()
	var/matrix/mtrx=new()
	return mtrx.Scale(1.5)
/proc/get_matrix_norm()
	var/matrix/mtrx=new()
	return mtrx
/proc/get_matrix_small()
	var/matrix/mtrx=new()
	return mtrx.Scale(0.8)
/proc/get_matrix_smallest()
	var/matrix/mtrx=new()
	return mtrx.Scale(0.65)

/proc/get_racelist(mob/user)//This proc returns a list of species that 'user' has available to them. It searches the list of ckeys attached to the 'whitelist' var for a species and also checks if they're an admin.
	for(var/spath in subtypesof(/datum/species))
		var/datum/species/S = new spath()
		var/list/wlist = S.whitelist
		if(S.whitelisted && (wlist.Find(user.ckey) || wlist.Find(user.key) || user.client.holder))  //If your ckey is on the species whitelist or you're an admin:
			GLOB.whitelisted_species_list[S.id] = S.type 											//Add the species to their available species list.
		else if(!S.whitelisted)														//Normal roundstart species will be handled here.
			GLOB.whitelisted_species_list[S.id] = S.type

	return GLOB.whitelisted_species_list

	//Mammal Species
GLOBAL_LIST_EMPTY(mam_body_markings_list)
GLOBAL_LIST_EMPTY(mam_ears_list)
GLOBAL_LIST_EMPTY(mam_tails_list)
GLOBAL_LIST_EMPTY(mam_tails_animated_list)
GLOBAL_LIST_EMPTY(taur_list)
GLOBAL_LIST_EMPTY(mam_snouts_list)

	//Exotic Species
GLOBAL_LIST_EMPTY(exotic_tails_list)
GLOBAL_LIST_EMPTY(exotic_tails_animated_list)
GLOBAL_LIST_EMPTY(exotic_ears_list)
GLOBAL_LIST_EMPTY(exotic_head_list)
GLOBAL_LIST_EMPTY(exotic_back_list)

	//Xenomorph Species
GLOBAL_LIST_EMPTY(xeno_head_list)
GLOBAL_LIST_EMPTY(xeno_tail_list)
GLOBAL_LIST_EMPTY(xeno_dorsal_list)

	//IPC species
GLOBAL_LIST_EMPTY(ipc_screens_list)
GLOBAL_LIST_EMPTY(ipc_antennas_list)

	//Genitals and Arousal Lists
GLOBAL_LIST_EMPTY(genitals_list)
GLOBAL_LIST_EMPTY(cock_shapes_list)
GLOBAL_LIST_EMPTY(balls_shapes_list)
GLOBAL_LIST_EMPTY(butt_shapes_list)
GLOBAL_LIST_EMPTY(belly_shapes_list)
GLOBAL_LIST_EMPTY(taur_belly_shapes_list) // GS13 TAUR BELLY EDIT
GLOBAL_LIST_EMPTY(breasts_shapes_list)
GLOBAL_LIST_EMPTY(vagina_shapes_list)
//longcat memes.
GLOBAL_LIST_INIT(dick_nouns, list("phallus", "willy", "dick", "prick", "member", "tool", "gentleman's organ", "cock", "wang", "knob", "dong", "joystick", "pecker", "johnson", "weenie", "tadger", "schlong", "thirsty ferret", "One eyed trouser trout", "Ding dong", "ankle spanker", "Pork sword", "engine cranker", "Harry hot dog", "Davy Crockett", "Kidney cracker", "Heat seeking moisture missile", "Giggle stick", "love whistle", "Tube steak", "Uncle Dick", "Purple helmet warrior"))

GLOBAL_LIST_INIT(genitals_visibility_toggles, list(GEN_VISIBLE_ALWAYS, GEN_VISIBLE_NO_CLOTHES, GEN_VISIBLE_NO_UNDIES, GEN_VISIBLE_NEVER))

GLOBAL_LIST_INIT(dildo_shapes, list(
		"Human"		= "human",
		"Knotted"	= "knotted",
		"Plain"		= "plain",
		"Flared"	= "flared"
		))
GLOBAL_LIST_INIT(dildo_sizes, list(
		"Small"		= 1,
		"Medium"	= 2,
		"Big"		= 3
		))
GLOBAL_LIST_INIT(dildo_colors, list(//mostly neon colors
		"Cyan"		= "#00f9ff",//cyan
		"Green"		= "#49ff00",//green
		"Pink"		= "#ff4adc",//pink
		"Yellow"	= "#fdff00",//yellow
		"Blue"		= "#00d2ff",//blue
		"Lime"		= "#89ff00",//lime
		"Black"		= "#101010",//black
		"Red"		= "#ff0000",//red
		"Orange"	= "#ff9a00",//orange
		"Purple"	= "#e300ff"//purple
		))

GLOBAL_LIST_INIT(meat_types, list(
	"Mammalian" = /obj/item/reagent_containers/food/snacks/meat/slab/human/mutant/mammal,
	"Aquatic" = /obj/item/reagent_containers/food/snacks/carpmeat/aquatic,
	"Avian" = /obj/item/reagent_containers/food/snacks/meat/slab/human/mutant/avian,
	"Insect" = /obj/item/reagent_containers/food/snacks/meat/slab/human/mutant/insect))

//Crew objective and miscreants stuff
GLOBAL_VAR_INIT(miscreants_allowed, FALSE)

/client/proc/reload_mentors()
		set name = "Reload Mentors"
		set category = "Admin"
		if(!src.holder)	return
		message_admins("[key_name_admin(usr)] manually reloaded mentors")

/mob/living/carbon/proc/has_penis()
	var/obj/item/organ/genital/G = getorganslot(ORGAN_SLOT_PENIS)
	if(G && istype(G, /obj/item/organ/genital/penis))
		return TRUE
	return FALSE

/mob/living/carbon/proc/has_balls()
	var/obj/item/organ/genital/G = getorganslot(ORGAN_SLOT_TESTICLES)
	if(G && istype(G, /obj/item/organ/genital/testicles))
		return TRUE
	return FALSE

/mob/living/carbon/proc/has_vagina()
	if(getorganslot(ORGAN_SLOT_VAGINA))
		return TRUE
	return FALSE

/mob/living/carbon/proc/has_breasts()
	if(getorganslot(ORGAN_SLOT_BREASTS))
		return TRUE
	return FALSE

/mob/living/carbon/proc/has_butt()
	if(getorganslot(ORGAN_SLOT_BUTT))
		return TRUE
	return FALSE

/mob/living/carbon/proc/has_belly()
	if(getorganslot(ORGAN_SLOT_BELLY))
		return TRUE
	return FALSE

/mob/living/carbon/proc/has_taur_belly() //GS13 EDIT TAUR BELLY
	if(getorganslot(ORGAN_SLOT_TAUR_BELLY))
		return TRUE
	return FALSE

/mob/living/carbon/proc/is_groin_exposed(list/L)
	if(!L)
		L = get_equipped_items()
	for(var/A in L)
		var/obj/item/I = A
		if(I.body_parts_covered & GROIN)
			return FALSE
	return TRUE
//GS13 Port - Arousal
/mob/living/carbon/proc/is_butt_exposed(var/list/L)
	if(!L)
		L = get_equipped_items()
	for(var/obj/item/I in L)
		if(I.body_parts_covered & GROIN)
			if(!I.do_not_cover_butt)
				return FALSE
			else
				return TRUE
	return TRUE

/mob/living/carbon/proc/is_chest_exposed(list/L)
	if(!L)
		L = get_equipped_items()
	for(var/A in L)
		var/obj/item/I = A
		if(I.body_parts_covered & CHEST)
			return FALSE
	return TRUE

////////////////////////
//DANGER | DEBUG PROCS//
////////////////////////

/client/proc/give_humans_genitals()
	set name = "Mass Give Genitals"
	set category = "Dangerous"
	set desc = "Gives every human mob genitals for testing purposes. WARNING: NOT FOR LIVE SERVER USAGE!!"

	log_admin("[src] gave everyone genitals.")
	message_admins("[src] gave everyone genitals.")
	for(var/mob/living/carbon/human/H in GLOB.mob_list)
		if(H.gender == MALE)
			H.give_genital(/obj/item/organ/genital/penis)
			H.give_genital(/obj/item/organ/genital/testicles)
			H.give_genital(/obj/item/organ/genital/butt)
		else
			H.give_genital(/obj/item/organ/genital/vagina)
			H.give_genital(/obj/item/organ/genital/womb)
			H.give_genital(/obj/item/organ/genital/breasts)
			H.give_genital(/obj/item/organ/genital/butt)
