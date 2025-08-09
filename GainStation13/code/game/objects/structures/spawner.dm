/obj/structure/spawner/candy
	name = "candyland tendril"
	desc = "A sweet tendril spewing out all sorts of teeth-rotting creatures."

	icon = 'GainStation13/icons/obj/gslight.dmi'
	icon_state = "candylight"

	faction = list("mining")
	max_mobs = 6
	max_integrity = 250
	mob_types = list(/mob/living/simple_animal/hostile/asteroid/basilisk/watcher/tendril)
	var/loot_type = /obj/structure/closet/crate/necropolis/tendril/all

	move_resist=INFINITY // just killing it tears a massive hole in the ground, let's not move it
	anchored = TRUE

	var/gps = null
	var/obj/effect/light_emitter/tendril/emitted_light

/obj/structure/spawner/candy/creamdemon
	mob_types = list(/mob/living/simple_animal/hostile/feed/chocolate_slime/creambeast/cream_demon)
	max_mobs = 2

/obj/structure/spawner/candy/chocoslime
	mob_types = list(/mob/living/simple_animal/hostile/feed/chocolate_slime)

/obj/structure/spawner/candy/magehand
	mob_types = list(/mob/living/simple_animal/hostile/fatten/magehand)
	max_mobs = 10

/obj/structure/spawner/candy/creambeast
	mob_types = list(/mob/living/simple_animal/hostile/feed/chocolate_slime/creambeast)


/obj/structure/spawner/candy/Initialize(mapload)
	. = ..()
	emitted_light = new(loc)
	for(var/F in RANGE_TURFS(1, src))
		if(ismineralturf(F))
			var/turf/closed/mineral/M = F
			M.ScrapeAway(null, CHANGETURF_IGNORE_AIR)
	gps = new /obj/item/gps/internal(src)
	GLOB.tendrils += src

/obj/structure/spawner/candy/deconstruct(disassembled)
	new /obj/effect/collapse(loc)
	new loot_type(loc)
	return ..()


/obj/structure/spawner/candy/Destroy()
	var/last_tendril = TRUE
	if(GLOB.tendrils.len>1)
		last_tendril = FALSE

	if(last_tendril && !(flags_1 & ADMIN_SPAWNED_1))
		if(SSachievements.achievements_enabled)
			for(var/mob/living/L in view(7,src))
				if(L.stat || !L.client)
					continue
				L.client.give_award(/datum/award/achievement/boss/tendril_exterminator, L)
				L.client.give_award(/datum/award/score/tendril_score, L) //Progresses score by one
	GLOB.tendrils -= src
	QDEL_NULL(emitted_light)
	QDEL_NULL(gps)
	return ..()
