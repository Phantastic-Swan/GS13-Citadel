/datum/round_event_control/space_dust
	name = "Minor Space Dust"
	typepath = /datum/round_event/space_dust
	// GS13 EDIT
	weight = 100 			// lowered from 200 to 100, to give it a chance to appear later in the round, rather than have all 50 shots fizzle out at the start
	max_occurrences = 50 	//GS13 - it was originaly 1000 occurences, which won't work out well in our super long rounds
	// GS13 END EDIT
	earliest_start = 0 MINUTES
	alert_observers = FALSE
	category = EVENT_CATEGORY_SPACE
	description = "A single space dust is hurled at the station."

/datum/round_event/space_dust
	start_when		= 1
	end_when			= 2
	fakeable = FALSE

/datum/round_event/space_dust/start()
	spawn_meteors(1, GLOB.meteorsC)

/datum/round_event_control/sandstorm
	name = "Sandstorm"
	typepath = /datum/round_event/sandstorm
	// GS13 EDIT
	weight = 3				// lowered weight from 5 to 3, cuz we're gonna make it appear more often in other ways
	max_occurrences = 3		// increased max occurences from 1 to 3, hopefully with lower weight this will result in more sandstorms over longer shifts vs 3 SANDSTORMS IN A ROW
	min_players = 10		// lowered min players to 10, since when was the last time we had 20 pop?
	// GS13 END EDIT
	earliest_start = 20 MINUTES
	category = EVENT_CATEGORY_SPACE
	description = "The station is pelted by an extreme amount of sand for several minutes."

/datum/round_event/sandstorm
	start_when = 1
	end_when = 150 // ~5 min
	announce_when = 0
	fakeable = FALSE

/datum/round_event/sandstorm/announce(fake)
	priority_announce("The station is passing through a heavy debris cloud. Watch out for breaches.", "Collision Alert", has_important_message = TRUE)

/datum/round_event/sandstorm/tick()
	spawn_meteors(rand(6,10), GLOB.meteorsC)
