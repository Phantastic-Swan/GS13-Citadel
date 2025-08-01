/datum/round_event_control/processor_overload/light
	name = "Light Processor Overload"
	typepath = /datum/round_event/processor_overload/light
	weight = 20					// more likely than the base one
	min_players = 0				// doesn't break shit so we don't care if there is nobody around to fix it
	max_occurrences = 15		// 15, since comms going down goes BRRRRRRRT
	description = "Emps the telecomm processors, scrambling radio speech. Doesn't blow them up."

/datum/round_event/processor_overload/announce(fake)
	var/alert = pick(	"Exospheric bubble inbound. Processor overload is likely. Please contact you*%xp25)`6cq-BZZT", \
						"Exospheric bubble inbound. Processor overload is likel*1eta;c5;'1v¬-BZZZT", \
						"Exospheric bubble inbound. Processor ov#MCi46:5.;@63-BZZZZT", \
						"Exospheric bubble inbo'Fz\\k55_@-BZZZZZT", \
						"Exospheri:%£ QCbyj^j</.3-BZZZZZZT", \
						"!!hy%;f3l7e,<$^-BZZZZZZZT")

	for(var/mob/living/silicon/ai/A in GLOB.ai_list)
	//AIs are always aware of processor overload
		to_chat(A, "<br><span class='warning'><b>[alert]</b></span><br>")

	// Announce most of the time, but leave a little gap so people don't know
	// whether it's, say, a tesla zapping tcomms, or some selective
	// modification of the tcomms bus
	if(prob(80) || fake)
		priority_announce(alert)


/datum/round_event/processor_overload/start()
	for(var/obj/machinery/telecomms/processor/P in GLOB.telecomms_list)
		if(prob(10))
			continue // 10% chance it spares a processor from getting scrambled like an egg
		else
			P.emp_act(80)
