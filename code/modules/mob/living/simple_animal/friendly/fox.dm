//Foxxy
/mob/living/simple_animal/pet/fox
	name = "fox"
	desc = "It's a fox."
	icon = 'icons/mob/pets.dmi'
	icon_state = "fox"
	icon_living = "fox"
	icon_dead = "fox_dead"
	speak = list("Ack-Ack","Ack-Ack-Ack-Ackawoooo","Geckers","Awoo","Tchoff")
	speak_emote = list("geckers", "barks")
	emote_hear = list("howls.","barks.")
	emote_see = list("shakes its head.", "shivers.")
	speak_chance = 1
	turns_per_move = 5
	see_in_dark = 6
	butcher_results = list(/obj/item/reagent_containers/food/snacks/meat/slab = 3)
	response_help_continuous = "pets"
	response_help_simple = "pet"
	response_disarm_continuous = "gently pushes aside"
	response_disarm_simple = "gently push aside"
	response_harm_continuous = "kicks"
	response_harm_simple = "kick"
	gold_core_spawnable = FRIENDLY_SPAWN
	footstep_type = FOOTSTEP_MOB_CLAW

	vocal_bark_id = "bullet"
	vocal_speed = 2
	vocal_pitch = 1.6
	vocal_pitch_range = 0.4

/mob/living/simple_animal/pet/fox/ComponentInitialize()
	. = ..()
	AddElement(/datum/element/mob_holder, "fox")

//Captain fox
/mob/living/simple_animal/pet/fox/Renault
	name = "Renault"
	desc = "Renault, the Captain's trustworthy fox."
	gender = FEMALE
	gold_core_spawnable = NO_SPAWN
	unique_pet = TRUE

/mob/living/simple_animal/pet/fox/fennec //ported from CHOMPstation2
	name = "fennec"
	desc = "It's an earsy fennec fox."
	icon = 'v_CHOMPstation2/icons/mob/fennec.dmi'
	icon_state = "fennec"
	icon_living = "fennec"
	icon_dead = "fennec_dead"
