/datum/round_event_control/disease_outbreak/light
	name = "Light Disease Outbreak"
	typepath = /datum/round_event/disease_outbreak/light
	max_occurrences = 5
	min_players = 5
	weight = 10
	description = "A simple disease will infect some crewmembers."

/datum/round_event/disease_outbreak/light
	max_severity = 0

/datum/round_event/disease_outbreak/light/start()
	if(!virus_type)
		virus_type = pick(/datum/disease/cold9, /datum/disease/cold, /datum/disease/flu, /datum/disease/magnitis, /datum/disease/fluspanish, /datum/disease/anxiety, /datum/disease/brainrot)

	for(var/mob/living/carbon/human/H in shuffle(GLOB.alive_mob_list))
		var/turf/T = get_turf(H)
		if(!T)
			continue
		if(!is_station_level(T.z))
			continue
		if(!H.client)
			continue
		if(HAS_TRAIT(H,TRAIT_EXEMPT_HEALTH_EVENTS))
			continue
		if(H.stat == DEAD)
			continue
		if(HAS_TRAIT(H, TRAIT_VIRUSIMMUNE)) //Don't pick someone who's virus immune, only for it to not do anything.
			continue
		var/foundAlready = FALSE	// don't infect someone that already has a disease
		for(var/thing in H.diseases)
			foundAlready = TRUE
			break
		if(foundAlready)
			continue

		var/datum/disease/D
		D = new virus_type()
		if (prob(25))
			D.carrier = TRUE
		H.ForceContractDisease(D, FALSE, TRUE)
		break