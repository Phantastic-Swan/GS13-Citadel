/obj/structure/chair/foldingchair
	name = "folding chair"
	desc = "A collapsible folding chair."
	icon = 'GainStation13/icons/obj/chairs.dmi'
	icon_state = "chair_fold"
	color = "#ffffff"
	item_chair = ""

/obj/structure/chair/mountchair
	name = "mounted chair"
	desc = "A chair mounted to the floor, this aint going anywhere!"
	icon = 'GainStation13/icons/obj/chairs.dmi'
	icon_state = "mounted_chair"
	color = "#ffffff"
	item_chair = ""

/obj/structure/chair/sofachair
	name = "sofa chair"
	desc = "A leather sofa chair."
	icon = 'GainStation13/icons/obj/chairs.dmi'
	icon_state = "sofachair"
	color = "#ffffff"
	item_chair = ""
	var/mutable_appearance/armrest

/obj/structure/chair/sofachair/proc/GetArmrest()
	return mutable_appearance('GainStation13/icons/obj/chairs.dmi', "sofachair_armrest")

/obj/structure/chair/sofachair/Destroy()
	QDEL_NULL(armrest)
	return ..()

/obj/structure/chair/sofachair/post_buckle_mob(mob/living/M)
	. = ..()
	update_armrest()

/obj/structure/chair/sofachair/proc/update_armrest()
	if(has_buckled_mobs())
		add_overlay(armrest)
	else
		cut_overlay(armrest)

/obj/structure/chair/sofachair/post_unbuckle_mob()
	. = ..()
	update_armrest()

/obj/structure/chair/sofachair/Initialize()

	armrest = GetArmrest()
	armrest.layer = ABOVE_MOB_LAYER
	return ..()

/obj/structure/rack/shelf
	name = "shelving"
	desc = "Some nice metal shelves."
	icon = 'hyperstation/icons/obj/objects.dmi'
	icon_state = "shelf"

/obj/structure/chair/beanbag
	name = "beanbag chair"
	desc = "A comfy beanbag chair. Almost as soft as your fat ass."
	icon = 'GainStation13/icons/obj/chairs.dmi'
	icon_state = "beanbag"
	color = "#ffffff"
	anchored = FALSE
	buildstacktype = /obj/item/stack/sheet/cloth
	buildstackamount = 5
	item_chair = null

/obj/structure/chair/beanbag/gato
	name = "GATO beanbag chair"
	desc = "A comfy beanbag chair. This one seems to a super duper cutesy GATO mascot."
	icon_state = "beanbag_gato"

/obj/structure/chair/beanbag/attackby(obj/item/W, mob/user, params)
	if(W.tool_behaviour == TOOL_WIRECUTTER && !(flags_1 & NODECONSTRUCT_1))
		W.play_tool_sound(src)
		deconstruct()
	else if(istype(W, /obj/item/assembly/shock_kit))
		if(!user.temporarilyRemoveItemFromInventory(W))
			return
		var/obj/item/assembly/shock_kit/SK = W
		var/obj/structure/chair/e_chair/E = new /obj/structure/chair/e_chair(src.loc)
		playsound(src.loc, 'sound/items/deconstruct.ogg', 50, 1)
		E.setDir(dir)
		E.part = SK
		SK.forceMove(E)
		SK.master = E
		qdel(src)
	else
		// this is fucking horrible but BYOND forces my hand
		// because BYOND seems to have NO CONCEPT of skipping the parent object and calling the parent of a parent
		// and it seems we have no other way to just call the attackby function of /obj
		// we have to copy and paste it 1:1
		if(. & STOP_ATTACK_PROC_CHAIN)
			return
		if(obj_flags & CAN_BE_HIT)
			. |= W.attack_obj(src, user)

//beanbag chair colors
/obj/structure/chair/beanbag/red
	color = "#8b2e2e"

/obj/structure/chair/beanbag/blue
	color = "#345bbc"

/obj/structure/chair/beanbag/green
	color = "#76da4b"

/obj/structure/chair/beanbag/purple
	color = "#a83acf"

/obj/structure/chair/beanbag/black
	color = "#404040"
