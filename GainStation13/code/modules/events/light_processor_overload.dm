/datum/round_event_control/processor_overload/light
	name = "Light Processor Overload"
	typepath = /datum/round_event/processor_overload/light
	weight = 20					// more likely than the base one
	min_players = 0				// doesn't break shit so we don't care if there is nobody around to fix it
	max_occurrences = 15		// 15, since comms going down goes BRRRRRRRT
	description = "Emps the telecomm processors, scrambling radio speech. Doesn't blow them up."

/datum/round_event/processor_overload/light
	announce_when	= 1

/datum/round_event/processor_overload/light/start()
	for(var/obj/machinery/telecomms/processor/P in GLOB.telecomms_list)
		if(prob(10))
			continue // 10% chance it spares a processor from getting scrambled like an egg
		else
			P.emp_act(80)
