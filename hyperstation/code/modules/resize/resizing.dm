//I am not a coder. Please fucking tear apart my code, and insult me for how awful I am at coding. Please and thank you. -Dahlular
//alright bet -BoxBoy
//Moving these here - Jay
/mob/living
	var/size_multiplier = 1 //multiplier for the mob's icon size atm
	var/previous_size = 1
	var/custom_body_size = 1

//Cyanosis - Action that resizes the sprite for the client but nobody else. Say goodbye to attacking yourself when someone's above you lmao
	var/datum/action/sizecode_resize/small_sprite

//Scale up a mob's icon by the size_multiplier
/mob/living/update_transform()
	ASSERT(!iscarbon(src)) //the source isnt carbon should always be true
	var/matrix/M = matrix() //matrix (M) variable
	M.Scale(size_multiplier)
	M.Translate(0, 16*(size_multiplier-1)) //translate by 16 * size_multiplier - 1 on Y axis
	src.transform = M //the source of transform is M

//IMPORTANT: Multiple animate() calls do not stack well, so try to do them all at once if you can.
/mob/living/carbon/update_transform()
	var/matrix/ntransform = matrix(transform) //aka transform.Copy()
	var/final_pixel_y = pixel_y
	var/final_dir = dir
	var/changed = 0

	if(lying != lying_prev && rotate_on_lying)
		changed++
		ntransform.TurnTo(lying_prev,lying)
		if(lying == 0) //Lying to standing
			final_pixel_y = get_standard_pixel_y_offset()
			if(size_multiplier >= 1) //if its bigger than normal
				ntransform.Translate(0,16 * (size_multiplier-1))
			else
				if(lying_prev == 90)
					ntransform.Translate(16 * (size_multiplier-1),16 * (size_multiplier-1))

				if(lying_prev == 270)
					ntransform.Translate(-16 * (size_multiplier-1),16 * (size_multiplier-1))

		else //if(lying != 0)
			if(lying_prev == 0) //Standing to lying
				pixel_y = get_standard_pixel_y_offset()
				final_pixel_y = get_standard_pixel_y_offset(lying)
				if(lying == 90)    //Check the angle of the sprite to offset it accordingly.
					ntransform.Translate(-16 * (size_multiplier-1),0)
					if(size_multiplier < 1) //if its smaller than normal
						ntransform.Translate(0,16 * (size_multiplier-1)) //we additionally offset the sprite downwards

				if(lying == 270) //check the angle of the sprite to offset it accordingly
					ntransform.Translate(16 * (size_multiplier-1),0)
					if(size_multiplier < 1) //if its smaller than normal
						ntransform.Translate(0,16 * (size_multiplier-1)) //we additionally offset the sprite downwards

				if(dir & (EAST|WEST)) //Facing east or west
					final_dir = pick(NORTH, SOUTH) //So you fall on your side rather than your face or ass

	if(resize != RESIZE_DEFAULT_SIZE)
		changed++
		ntransform.Scale(resize)
		resize = RESIZE_DEFAULT_SIZE

	//Apply size multiplier, thank NeverExisted for this
	if(size_multiplier != previous_size)
		changed++
		//now we offset the sprite
		//Scaling affects offset. There's probably a smarter and easier way to do this, but this way it works for sure (?)
		//Just to be clear. All this bullshit is needed because someone wanted to store the old transform matrix instead of using a new one each iteration
		//Winfre is currently doing a great job at coating my nuts in slobber while i code this
		if(!lying) //when standing. People of all sizes are affected equally
			ntransform.Translate(0,-16 * (previous_size-1))			//reset the sprite
			ntransform.Scale(size_multiplier/previous_size)			//scale the sprite accordingly.
			ntransform.Translate(0,16 * (size_multiplier-1))		//apply the new offset
		else //when lying. Macros dont get an offset, Micros do. We must also check the cases when a micro becomes a macro and viceversa
			if(previous_size <= 1 && size_multiplier <= 1) //micro stays a micro. We modify the side-offset
				ntransform.Translate(0,-16 * (previous_size-1))		//reset the sprite
				ntransform.Scale(size_multiplier/previous_size)		//scale the sprite accordingly
				ntransform.Translate(0,16 * (size_multiplier-1))	//apply the new offset

			if(previous_size <= 1 && size_multiplier > 1) //micro becomes a macro. We remove the side-offset
				ntransform.Translate(0,-16 * (previous_size-1))		//reset the sprite
				ntransform.Scale(size_multiplier/previous_size)		//scale the sprite accordingly

			if(previous_size > 1 && size_multiplier <= 1) //macro becomes a micro. We add an offset
				ntransform.Scale(size_multiplier/previous_size)		//scale the sprite accordingly.
				ntransform.Translate(0,16 * (size_multiplier-1))	//apply the new offset

			if(previous_size > 1 && size_multiplier > 1) //macro stays a macro. We just scale the sprite with no offset changes
				ntransform.Scale(size_multiplier/previous_size)		//scale the sprite accordingly


	if(changed)
		animate(src, transform = ntransform, time = 2, pixel_y = final_pixel_y, dir = final_dir, easing = EASE_IN|EASE_OUT)
		setMovetype(movement_type & ~FLOATING)  // If we were without gravity, the bouncing animation got stopped, so we make sure we restart it in next life().


/mob/proc/get_effective_size()
	return 100000

/mob/living/get_effective_size()
	return src.size_multiplier

/datum/movespeed_modifier/size
	id = MOVESPEED_ID_SIZE
	variable = TRUE

/mob/living/proc/resize(var/new_size, var/animate = TRUE)
	size_multiplier = new_size //This will be passed into update_transform() and used to change health and speed.
	if(size_multiplier == previous_size)
		return TRUE
	src.update_transform() //WORK DAMN YOU
	src.update_mobsize()
	//Going to change the health and speed values too
	src.remove_movespeed_modifier(/datum/movespeed_modifier/size)
	src.add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/size, multiplicative_slowdown = (abs(size_multiplier - 1) * 0.3 )) //GS Change, reduces speed penalties for size from *.4 to *.3
	var/healthmod_old = ((previous_size * 35) - 75) //Get the old value to see what we must change.
	var/healthmod_new = ((size_multiplier * 35) - 75) //A size of one would be zero. Big boys get health, small ones lose health. //GS Change, reduces health penalties/buffs for size from *75 to *35
	var/healthchange = healthmod_new - healthmod_old //Get ready to apply the new value, and subtract the old one. (Negative values become positive)
	src.maxHealth += healthchange
	src.health += healthchange
	if(iscarbon(src))
		var/mob/living/carbon/C = src
		for(var/obj/item/organ/genital/G in C.internal_organs)
			G.update_appearance()
	//if(src.size_multiplier >= RESIZE_A_HUGEBIG || src.size_multiplier <= RESIZE_A_TINYMICRO) Will remove clothing when too big or small. Will do later.
	previous_size = size_multiplier //And, change this now that we are finally done.

	SEND_SIGNAL(src, COMSIG_MOBSIZE_CHANGED, src) //This SHOULD allow other shit to check when a mob changes size -Capn

	//Now check if the mob can get the size action
	if(!small_sprite)
		small_sprite = new(src)
	small_sprite.Remove(src)
	if(size_multiplier >= 1.25)	//Anything bigger will start to block things
		small_sprite.Grant(src)

//handle the big steppy, except nice
/mob/living/proc/handle_micro_bump_helping(var/mob/living/tmob)
	if(ishuman(src))
		var/mob/living/carbon/human/H = src

		if(tmob.pulledby == H)
			return FALSE

		//Micro is on a table.
		var/turf/steppyspot = tmob.loc
		for(var/thing in steppyspot.contents)
			if(istype(thing, /obj/structure/table))
				return TRUE

		//Both small.
		if(H.get_effective_size() <= RESIZE_A_TINYMICRO && tmob.get_effective_size() <= RESIZE_A_TINYMICRO)
			now_pushing = 0
			H.forceMove(tmob.loc)
			return TRUE

		//Doing messages
		if(abs(get_effective_size()/tmob.get_effective_size()) >= 2) //if the initiator is twice the size of the micro
			now_pushing = 0
			H.forceMove(tmob.loc)

			//Smaller person being stepped on
			if(get_effective_size() > tmob.get_effective_size() && iscarbon(src))
				// GS13: Import Fat Naga & Alt Naga from VoreStation
				if(istype(H) && H.dna.features["taur"] == "Naga" || H.dna.features["taur"] == "Tentacle" || H.dna.features["taur"] == "Fat Naga" || H.dna.features["taur"] == "Alt Naga")
					tmob.visible_message("<span class='notice'>[src] carefully slithers around [tmob].</span>", "<span class='notice'>[src]'s huge tail slithers besides you.</span>")
				else
					tmob.visible_message("<span class='notice'>[src] carefully steps over [tmob].</span>", "<span class='notice'>[src] steps over you carefully.</span>")

				return TRUE

		//Smaller person stepping under a larger person
		if(abs(tmob.get_effective_size()/get_effective_size()) >= 2)
			H.forceMove(tmob.loc)
			now_pushing = 0
			micro_step_under(tmob)
			return TRUE

//Stepping on disarm intent -- TO DO, OPTIMIZE ALL OF THIS SHIT
/mob/living/proc/handle_micro_bump_other(var/mob/living/tmob)
	ASSERT(isliving(tmob))
	if(ishuman(src))
		var/mob/living/carbon/human/H = src

		if(tmob.pulledby == H)
			return FALSE

	//If on a table, don't
		var/turf/steppyspot = tmob.loc
		for(var/thing in steppyspot.contents)
			if(istype(thing, /obj/structure/table))
				return TRUE

	//Both small
		if(H.get_effective_size() <= RESIZE_A_TINYMICRO && tmob.get_effective_size() <= RESIZE_A_TINYMICRO)
			now_pushing = 0
			H.forceMove(tmob.loc)
			return TRUE

		if(abs(get_effective_size()/tmob.get_effective_size()) >= 2)
			if(H.a_intent == "disarm" && CHECK_MOBILITY(H, MOBILITY_MOVE) && !H.buckled)
				now_pushing = 0
				H.forceMove(tmob.loc)
				sizediffStamLoss(tmob)
				H.add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/size, multiplicative_slowdown = 10) //Full stop
				addtimer(CALLBACK(H, TYPE_PROC_REF(/mob/, remove_movespeed_modifier), MOVESPEED_ID_STOMP), 3) //0.3 seconds
				if(get_effective_size() > tmob.get_effective_size() && iscarbon(H))
					if(istype(H) && H.dna.features["taur"] == "Naga" || H.dna.features["taur"] == "Tentacle" || H.dna.features["taur"] == "Fat Naga" || H.dna.features["taur"] == "Alt Naga")
						tmob.visible_message("<span class='danger'>[src] carefully rolls their tail over [tmob]!</span>", "<span class='danger'>[src]'s huge tail rolls over you!</span>")
					else
						tmob.visible_message("<span class='danger'>[src] carefully steps on [tmob]!</span>", "<span class='danger'>[src] steps onto you with force!</span>")

					//horny traits
					/*
					if(HAS_TRAIT(src, TRAIT_MICROPHILE))
						src.adjust_arousal(8)
						if (src.getArousal() >= 100 && ishuman(tmob) && tmob.has_dna())
							src.mob_climax(forced_climax=TRUE)

					if(HAS_TRAIT(tmob, TRAIT_MACROPHILE))
						tmob.adjust_arousal(10)
						if (tmob.getArousal() >= 100 && ishuman(tmob) && tmob.has_dna())
							tmob.mob_climax(forced_climax=TRUE)

						return TRUE
					* commenting out for now.*/

			if(H.a_intent == "harm" && CHECK_MOBILITY(H, MOBILITY_MOVE) && !H.buckled)
				now_pushing = 0
				H.forceMove(tmob.loc)
				sizediffStamLoss(tmob)
				sizediffBruteloss(tmob)
				playsound(loc, 'sound/misc/splort.ogg', 50, 1)
				H.add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/size, multiplicative_slowdown = 10)
				addtimer(CALLBACK(H, TYPE_PROC_REF(/mob/, remove_movespeed_modifier), MOVESPEED_ID_STOMP), 10) //1 second
				//H.Stun(20)
				if(get_effective_size() > tmob.get_effective_size() && iscarbon(H))
					if(istype(H) && H.dna.features["taur"] == "Naga" || H.dna.features["taur"] == "Tentacle" || H.dna.features["taur"] == "Fat Naga" || H.dna.features["taur"] == "Alt Naga")
						tmob.visible_message("<span class='danger'>[src] mows down [tmob] under their tail!</span>", "<span class='userdanger'>[src] plows their tail over you mercilessly!</span>")
					else
						tmob.visible_message("<span class='danger'>[src] slams their foot down on [tmob], crushing them!</span>", "<span class='userdanger'>[src] crushes you under their foot!</span>")

					//horny traits
					/*
					if(HAS_TRAIT(src, TRAIT_MICROPHILE))
						src.adjust_arousal((get_effective_size()/tmob.get_effective_size()*3))
						if (src.getArousal() >= 100 && ishuman(tmob) && tmob.has_dna())
							src.mob_climax(forced_climax=TRUE)

					if(HAS_TRAIT(tmob, TRAIT_MACROPHILE))
						tmob.adjust_arousal((get_effective_size()/tmob.get_effective_size()*3))
						if (tmob.getArousal() >= 100 && ishuman(tmob) && tmob.has_dna())
							tmob.mob_climax(forced_climax=TRUE)

					commenting out for now */
					return TRUE

			// if(H.a_intent == "grab" && CHECK_MOBILITY(H, MOBILITY_MOVE) && !H.buckled)
			// 	now_pushing = 0
			// 	H.forceMove(tmob.loc)
			// 	sizediffStamLoss(tmob)
			// 	sizediffStun(tmob)
			// 	H.add_movespeed_modifier(MOVESPEED_ID_STOMP, multiplicative_slowdown = 10)
			// 	addtimer(CALLBACK(H, TYPE_PROC_REF(/mob/, remove_movespeed_modifier), MOVESPEED_ID_STOMP), 7)//About 3/4th a second
			// 	if(get_effective_size() > tmob.get_effective_size() && iscarbon(H))
			// 		var/feetCover = (H.wear_suit && (H.wear_suit.body_parts_covered & FEET)) || (H.w_uniform && (H.w_uniform.body_parts_covered & FEET) || (H.shoes && (H.shoes.body_parts_covered & FEET)))
			// 		if(feetCover)
			// 			if(istype(H) && H.dna.features["taur"] == "Naga" || H.dna.features["taur"] == "Tentacle" || H.dna.features["taur"] == "Fat Naga" || H.dna.features["taur"] == "Alt Naga")
			// 				tmob.visible_message("<span class='danger'>[src] pins [tmob] under their tail!</span>", "<span class='danger'>[src] pins you beneath their tail!</span>")
			// 			else
			// 				tmob.visible_message("<span class='danger'>[src] pins [tmob] helplessly underfoot!</span>", "<span class='danger'>[src] pins you underfoot!</span>")
			// 			return TRUE
			// 		else
			// 			if(istype(H) && H.dna.features["taur"] == "Naga" || H.dna.features["taur"] == "Tentacle" || H.dna.features["taur"] == "Fat Naga" || H.dna.features["taur"] == "Alt Naga")
			// 				tmob.visible_message("<span class='danger'>[src] snatches up [tmob] underneath their tail!</span>", "<span class='userdanger'>[src]'s tail winds around you and snatches you in its coils!</span>")
			// 				//tmob.mob_pickup_micro_feet(H)
			// 				SEND_SIGNAL(tmob, COMSIG_MICRO_PICKUP_FEET, H)
			// 			else
			// 				tmob.visible_message("<span class='danger'>[src] stomps down on [tmob], curling their toes and picking them up!</span>", "<span class='userdanger'>[src]'s toes pin you down and curl around you, picking you up!</span>")
			// 				//tmob.mob_pickup_micro_feet(H)
			// 				SEND_SIGNAL(tmob, COMSIG_MICRO_PICKUP_FEET, H)
			// 			return TRUE

		if(abs(tmob.get_effective_size()/get_effective_size()) >= 2)
			H.forceMove(tmob.loc)
			now_pushing = 0
			micro_step_under(tmob)
			return TRUE

//smaller person stepping under another person... TO DO, fix and allow special interactions with naga legs to be seen
/mob/living/proc/micro_step_under(var/mob/living/tmob)
	if(istype(tmob) && istype(tmob, /datum/sprite_accessory/taur/naga))
		src.visible_message("<span class='notice'>[src] bounds over [tmob]'s tail.</span>", "<span class='notice'>You jump over [tmob]'s thick tail.</span>")
	else
		src.visible_message("<span class='notice'>[src] runs between [tmob]'s legs.</span>", "<span class='notice'>You run between [tmob]'s legs.</span>")

//Proc for scaling stamina damage on size difference
/mob/living/proc/sizediffStamLoss(var/mob/living/tmob)
	var/S = (get_effective_size()/tmob.get_effective_size()*25) //macro divided by micro, times 25
	tmob.Knockdown(S) //final result in stamina knockdown

//Proc for scaling stuns on size difference (for grab intent)
/mob/living/proc/sizediffStun(var/mob/living/tmob)
	var/T = (get_effective_size()/tmob.get_effective_size()*2) //Macro divided by micro, times 2
	tmob.Stun(T)

//Proc for scaling brute damage on size difference
/mob/living/proc/sizediffBruteloss(var/mob/living/tmob)
	var/B = (get_effective_size()/tmob.get_effective_size()*2) //macro divided by micro, times 3 //GS change, *2
	tmob.adjustBruteLoss(B) //final result in brute loss

//Proc for changing mob_size to be grabbed for item weight classes
/mob/living/proc/update_mobsize(var/mob/living/tmob)
	if(size_multiplier <= 0.50)
		mob_size = 0
	else if(size_multiplier < 1)
		mob_size = 1
	else if(size_multiplier <= 2)
		mob_size = 2 //the default human size
	else if(size_multiplier > 2)
		mob_size = 3

//Proc for instantly grabbing valid size difference. Code optimizations soon(TM)
/*
/mob/living/proc/sizeinteractioncheck(var/mob/living/tmob)
	if(abs(get_effective_size()/tmob.get_effective_size())>=2.0 && get_effective_size()>tmob.get_effective_size())
		return FALSE
	else
		return TRUE
*/
//Clothes coming off at different sizes, and health/speed/stam changes as well
