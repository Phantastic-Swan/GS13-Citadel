//Ported from /vg/station13, which was in turn forked from baystation12;
//Please do not bother them with bugs from this port, however, as it has been modified quite a bit.
//Modifications include removing the world-ending full supermatter variation, and leaving only the shard.

//Zap constants, speeds up targeting

#define BIKE (COIL + 1)
#define COIL (ROD + 1)
#define ROD (LIVING + 1)
#define LIVING (MACHINERY + 1)
#define MACHINERY (OBJECT + 1)
#define OBJECT (LOWEST + 1)
#define LOWEST (1)

/datum/auxgm/proc/add_supermatter_properties(datum/gas/gas)
	var/g = gas.id
	var/list/props = src.supermatter
	if(gas.powermix || gas.heat_penalty || gas.transmit_modifier || gas.radioactivity_modifier || gas.heat_resistance || gas.powerloss_inhibition)
		props[HEAT_PENALTY][g] = gas.heat_penalty
		props[TRANSMIT_MODIFIER][g] = gas.transmit_modifier
		props[RADIOACTIVITY_MODIFIER][g] = gas.radioactivity_modifier
		props[HEAT_RESISTANCE][g] = gas.heat_resistance
		props[POWERLOSS_INHIBITION][g] = gas.powerloss_inhibition
		props[POWER_MIX][g] = gas.powermix
		props[ALL_SUPERMATTER_GASES] += g

#define POWERLOSS_INHIBITION_GAS_THRESHOLD 0.20         //Higher == Higher percentage of inhibitor gas needed before the charge inertia chain reaction effect starts.
#define POWERLOSS_INHIBITION_MOLE_THRESHOLD 20        //Higher == More moles of the gas are needed before the charge inertia chain reaction effect starts.        //Scales powerloss inhibition down until this amount of moles is reached
#define POWERLOSS_INHIBITION_MOLE_BOOST_THRESHOLD 500  //bonus powerloss inhibition boost if this amount of moles is reached

#define MOLE_PENALTY_THRESHOLD 1800           //Above this value we can get lord singulo and independent mol damage, below it we can heal damage
#define MOLE_HEAT_PENALTY 350                 //Heat damage scales around this. Too hot setups with this amount of moles do regular damage, anything above and below is scaled
//Along with damage_penalty_point, makes flux anomalies.
#define POWER_PENALTY_THRESHOLD 5000          //The cutoff on power properly doing damage, pulling shit around, and delamming into a tesla. Low chance of pyro anomalies, +2 bolts of electricity
#define SEVERE_POWER_PENALTY_THRESHOLD 7000   //+1 bolt of electricity, allows for gravitational anomalies, and higher chances of pyro anomalies
#define CRITICAL_POWER_PENALTY_THRESHOLD 9000 //+1 bolt of electricity.
#define HEAT_PENALTY_THRESHOLD 40             //Higher == Crystal safe operational temperature is higher.
#define DAMAGE_HARDCAP 0.002
#define DAMAGE_INCREASE_MULTIPLIER 0.25


#define THERMAL_RELEASE_MODIFIER 350         //Higher == more heat released during reaction, not to be confused with the above values
#define THERMAL_RELEASE_CAP_MODIFIER 250     //Higher == lower cap on how much heat can be released per tick--currently 1.3x old value
#define PLASMA_RELEASE_MODIFIER 750        //Higher == less plasma released by reaction
#define OXYGEN_RELEASE_MODIFIER 550        //Higher == less oxygen released at high temperature/power

#define REACTION_POWER_MODIFIER 0.55       //Higher == more overall power

#define MATTER_POWER_CONVERSION 10         //Crystal converts 1/this value of stored matter into energy.

//These would be what you would get at point blank, decreases with distance
#define DETONATION_RADS 200
#define DETONATION_HALLUCINATION 600


#define WARNING_DELAY 60

#define HALLUCINATION_RANGE(P) (min(7, round(P ** 0.25)))


#define GRAVITATIONAL_ANOMALY "gravitational_anomaly"
#define FLUX_ANOMALY "flux_anomaly"
#define PYRO_ANOMALY "pyro_anomaly"

//If integrity percent remaining is less than these values, the monitor sets off the relevant alarm.
#define SUPERMATTER_DELAM_PERCENT 5
#define SUPERMATTER_EMERGENCY_PERCENT 25
#define SUPERMATTER_DANGER_PERCENT 50
#define SUPERMATTER_WARNING_PERCENT 100
#define CRITICAL_TEMPERATURE 10000

#define SUPERMATTER_COUNTDOWN_TIME 30 SECONDS

///to prevent accent sounds from layering
#define SUPERMATTER_ACCENT_SOUND_MIN_COOLDOWN 2 SECONDS

#define DEFAULT_ZAP_ICON_STATE "sm_arc"
#define SLIGHTLY_CHARGED_ZAP_ICON_STATE "sm_arc_supercharged"
#define OVER_9000_ZAP_ICON_STATE "sm_arc_dbz_referance" //Witty I know

GLOBAL_DATUM(main_supermatter_engine, /obj/machinery/power/supermatter_crystal)

/obj/machinery/power/supermatter_crystal
	name = "supermatter crystal"
	desc = "A strangely translucent and iridescent crystal."
	icon = 'GainStation13/icons/turf/supermatter.dmi' // GS13 EDIT 'icons/obj/supermatter.dmi'
	icon_state = "darkmatter"
	density = TRUE
	anchored = TRUE
	flags_1 = PREVENT_CONTENTS_EXPLOSION_1
	light_range = 4
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF | FREEZE_PROOF
	critical_machine = TRUE

	///The id of our supermatter
	var/uid = 1
	///The amount of supermatters that have been created this round
	var/static/gl_uid = 1
	///Tracks the bolt color we are using
	var/zap_icon = DEFAULT_ZAP_ICON_STATE
	///The portion of the gasmix we're on that we should remove
	var/gasefficency = 0.15
	///Used for changing icon states for diff base sprites
	base_icon_state = "darkmatter"

	///Are we exploding?
	var/final_countdown = FALSE

	///The amount of damage we have currently
	var/damage = 0
	///The damage we had before this cycle. Used to limit the damage we can take each cycle, and for safe_alert
	var/damage_archived = 0
	///Our "Shit is no longer fucked" message. We send it when damage is less then damage_archived
	var/safe_alert = "Crystalline hyperstructure returning to safe operating parameters."
	///The point at which we should start sending messeges about the damage to the engi channels.
	var/warning_point = 50
	///The alert we send when we've reached warning_point
	var/warning_alert = "Danger! Crystal hyperstructure integrity faltering!"
	///The point at which we start sending messages to the common channel
	var/emergency_point = 700
	///The alert we send when we've reached emergency_point
	var/emergency_alert = "CRYSTAL DELAMINATION IMMINENT."
	///The point at which we delam
	var/explosion_point = 900
	///When we pass this amount of damage we start shooting bolts
	var/damage_penalty_point = 550

	///A scaling value that affects the severity of explosions.
	var/explosion_power = 35
	///Time in 1/10th of seconds since the last sent warning
	var/lastwarning = 0
	///Refered to as eer on the moniter. This value effects gas output, heat, damage, and radiation.
	var/power = 0
	///Determines the rate of positve change in gas comp values
	var/gas_change_rate = 0.05
	var/list/gas_comp = list()
	///The last air sample's total molar count, will always be above or equal to 0
	var/combined_gas = 0
	///Affects the power gain the sm experiances from heat
	var/gasmix_power_ratio = 0
	///Affects the amount of damage and minimum point at which the sm takes heat damage
	var/dynamic_heat_resistance = 1
	///Uses powerloss_dynamic_scaling and combined_gas to lessen the effects of our powerloss functions
	var/powerloss_inhibitor = 1
	///Based on co2 percentage, slowly moves between 0 and 1. We use it to calc the powerloss_inhibitor
	var/powerloss_dynamic_scaling= 0
	///Used to increase or lessen the amount of damage the sm takes from heat based on molar counts.
	var/mole_heat_penalty = 0
	///Takes the energy throwing things into the sm generates and slowly turns it into actual power
	var/matter_power = 0
	///The cutoff for a bolt jumping, grows with heat, lowers with higher mol count,
	var/zap_cutoff = 1500
	///How much the bullets damage should be multiplied by when it is added to the internal variables
	var/bullet_energy = 2
	///How much hallucination should we produce per unit of power?
	var/hallucination_power = 0.05 // 2 seconds per second at a distance of 7 with a typical nitrogen setup

	///Our internal radio
	var/obj/item/radio/radio
	///The key our internal radio uses
	var/radio_key = /obj/item/encryptionkey/headset_eng
	///The engineering channel
	var/engineering_channel = "Engineering"
	///The common channel
	var/common_channel = null

	///Boolean used for logging if we've been powered
	var/has_been_powered = FALSE
	///Boolean used for logging if we've passed the emergency point
	var/has_reached_emergency = FALSE

	///An effect we show to admins and ghosts the percentage of delam we're at
	var/obj/effect/countdown/supermatter/countdown

	///Used along with a global var to track if we can give out the sm sliver stealing objective
	var/is_main_engine = FALSE
	///Our soundloop
	var/datum/looping_sound/supermatter/soundloop
	///Can it be moved?
	var/moveable = FALSE

	///cooldown tracker for accent sounds
	var/last_accent_sound = 0

	//For making hugbox supermatters
	///Disables all methods of taking damage
	var/takes_damage = TRUE
	///Disables the production of gas, and pretty much any handling of it we do.
	var/produces_gas = TRUE
	///Disables power changes
	var/power_changes = TRUE
	///Disables the sm's proccessing totally.
	var/processes = TRUE

/obj/machinery/power/supermatter_crystal/Initialize(mapload)
	. = ..()
	uid = gl_uid++
	SSair.start_processing_machine(src)
	countdown = new(src)
	countdown.start()
	GLOB.poi_list |= src
	radio = new(src)
	radio.keyslot = new radio_key
	radio.listening = 0
	radio.recalculateChannels()
	investigate_log("has been created.", INVESTIGATE_SUPERMATTER)
	if(is_main_engine)
		GLOB.main_supermatter_engine = src

	AddElement(/datum/element/bsa_blocker)
	RegisterSignal(src, COMSIG_ATOM_BSA_BEAM, PROC_REF(call_explode))

	soundloop = new(src, TRUE)

/obj/machinery/power/supermatter_crystal/Destroy()
	investigate_log("has been destroyed.", INVESTIGATE_SUPERMATTER)
	SSair.stop_processing_machine(src)
	QDEL_NULL(radio)
	GLOB.poi_list -= src
	QDEL_NULL(countdown)
	if(is_main_engine && GLOB.main_supermatter_engine == src)
		GLOB.main_supermatter_engine = null
	QDEL_NULL(soundloop)
	return ..()

/obj/machinery/power/supermatter_crystal/examine(mob/user)
	. = ..()
	if (istype(user, /mob/living/carbon))
		var/mob/living/carbon/C = user
		if (!istype(C.glasses, /obj/item/clothing/glasses/meson) && (get_dist(user, src) < HALLUCINATION_RANGE(power)))
			. += "<span class='danger'>You get headaches just from looking at it.</span>"

// SupermatterMonitor UI for ghosts only. Inherited attack_ghost will call this.
/obj/machinery/power/supermatter_crystal/ui_interact(mob/user, datum/tgui/ui)
	if(!isobserver(user))
		return FALSE
	. = ..()
	ui = SStgui.try_update_ui(user, src, ui)
	if (!ui)
		ui = new(user, src, "SupermatterMonitor")
		ui.open()

/obj/machinery/power/supermatter_crystal/ui_data(mob/user)
	var/list/data = list()

	var/turf/local_turf = get_turf(src)

	var/datum/gas_mixture/air = local_turf.return_air()

	// singlecrystal set to true eliminates the back sign on the gases breakdown.
	data["singlecrystal"] = TRUE
	data["active"] = TRUE
	data["SM_integrity"] = get_integrity()
	data["SM_power"] = power
	data["SM_ambienttemp"] = air.return_temperature()
	data["SM_ambientpressure"] = air.return_pressure()
	data["SM_bad_moles_amount"] = MOLE_PENALTY_THRESHOLD / gasefficency
	data["SM_moles"] = 0
	data["SM_uid"] = uid
	var/area/active_supermatter_area = get_area(src)
	data["SM_area_name"] = active_supermatter_area.name

	var/list/gasdata = list()

	if(air.total_moles())
		data["SM_moles"] = air.total_moles()
		for(var/id in air.get_gases())
			var/gas_level = air.get_moles(id)/air.total_moles()
			if(gas_level > 0)
				gasdata.Add(list(list(
				"name"= "[GLOB.gas_data.names[id]]",
				"amount" = round(gas_level*100, 0.01))))

	else
		for(var/id in air.get_gases())
			gasdata.Add(list(list(
			"name"= "[GLOB.gas_data.names[id]]",
			"amount" = 0)))

	data["gases"] = gasdata

	return data

/obj/machinery/power/supermatter_crystal/proc/get_status()
	var/turf/T = get_turf(src)
	if(!T)
		return SUPERMATTER_ERROR
	var/datum/gas_mixture/air = T.return_air()
	if(!air)
		return SUPERMATTER_ERROR

	var/integrity = get_integrity()
	if(integrity < SUPERMATTER_DELAM_PERCENT)
		return SUPERMATTER_DELAMINATING

	if(integrity < SUPERMATTER_EMERGENCY_PERCENT)
		return SUPERMATTER_EMERGENCY

	if(integrity < SUPERMATTER_DANGER_PERCENT)
		return SUPERMATTER_DANGER

	if((integrity < SUPERMATTER_WARNING_PERCENT) || (air.return_temperature() > CRITICAL_TEMPERATURE))
		return SUPERMATTER_WARNING

	if(air.return_temperature() > (CRITICAL_TEMPERATURE * 0.8))
		return SUPERMATTER_NOTIFY

	if(power > 5)
		return SUPERMATTER_NORMAL
	return SUPERMATTER_INACTIVE

/obj/machinery/power/supermatter_crystal/proc/alarm()
	switch(get_status())
		if(SUPERMATTER_DELAMINATING)
			playsound(src, 'sound/misc/bloblarm.ogg', 100, FALSE, 40, 30, falloff_distance = 10)
		if(SUPERMATTER_EMERGENCY)
			playsound(src, 'sound/machines/engine_alert1.ogg', 100, FALSE, 30, 30, falloff_distance = 10)
		if(SUPERMATTER_DANGER)
			playsound(src, 'sound/machines/engine_alert2.ogg', 100, FALSE, 30, 30, falloff_distance = 10)
		if(SUPERMATTER_WARNING)
			playsound(src, 'sound/machines/terminal_alert.ogg', 75)

/obj/machinery/power/supermatter_crystal/proc/get_integrity()
	var/integrity = damage / explosion_point
	integrity = round(100 - integrity * 100, 0.01)
	integrity = integrity < 0 ? 0 : integrity
	return integrity

/obj/machinery/power/supermatter_crystal/update_overlays()
	. = ..()
	if(final_countdown)
		. += "casuality_field"

/obj/machinery/power/supermatter_crystal/proc/countdown()
	set waitfor = FALSE

	if(final_countdown) // We're already doing it go away
		return
	final_countdown = TRUE
	update_icon()

	var/speaking = "[emergency_alert] The supermatter has reached critical integrity failure. Emergency causality destabilization field has been activated."
	radio.talk_into(src, speaking, common_channel, language = get_selected_language())
	for(var/i in SUPERMATTER_COUNTDOWN_TIME to 0 step -10)
		if(damage < explosion_point) // Cutting it a bit close there engineers
			radio.talk_into(src, "[safe_alert] Failsafe has been disengaged.", common_channel)
			final_countdown = FALSE
			update_icon()
			return
		else if((i % 50) != 0 && i > 50) // A message once every 5 seconds until the final 5 seconds which count down individualy
			sleep(10)
			continue
		else if(i > 50)
			speaking = "[DisplayTimeText(i, TRUE)] remain before causality stabilization."
		else
			speaking = "[i*0.1]..."
		radio.talk_into(src, speaking, common_channel, list(SPAN_COMMAND))	// IT GOT WORSE, LOUD TIME
		sleep(10)

	explode()

/obj/machinery/power/supermatter_crystal/proc/explode()
	for(var/mob in GLOB.alive_mob_list)
		var/mob/living/L = mob
		if(istype(L) && L.z == z)
			if(ishuman(mob))
				//Hilariously enough, running into a closet should make you get hit the hardest.
				var/mob/living/carbon/human/H = mob
				H.hallucination += max(50, min(300, DETONATION_HALLUCINATION * sqrt(1 / (get_dist(mob, src) + 1)) ) )
			var/rads = DETONATION_RADS * sqrt( 1 / (get_dist(L, src) + 1) )
			L.rad_act(rads)

	var/turf/T = get_turf(src)
	for(var/mob/M in GLOB.player_list)
		if(M.z == z)
			SEND_SOUND(M, 'sound/magic/charge.ogg')
			to_chat(M, "<span class='boldannounce'>You feel reality distort for a moment...</span>")
			SEND_SIGNAL(M, COMSIG_ADD_MOOD_EVENT, "delam", /datum/mood_event/delam)
	if(combined_gas > MOLE_PENALTY_THRESHOLD)
		investigate_log("has collapsed into a singularity.", INVESTIGATE_SUPERMATTER)
		if(T) //If something fucks up we blow anyhow. This fix is 4 years old and none ever said why it's here. help.
			var/obj/singularity/S = new(T)
			S.energy = 800
			S.consume(src)
			return //No boom for me sir
	else if(power > POWER_PENALTY_THRESHOLD)
		investigate_log("has spawned additional energy balls.", INVESTIGATE_SUPERMATTER)
		if(T)
			var/obj/singularity/energy_ball/E = new(T)
			E.energy = power
	investigate_log("has exploded.", INVESTIGATE_SUPERMATTER)
	//Dear mappers, balance the sm max explosion radius to 17.5, 37, 39, 41
	explosion(get_turf(T), explosion_power * max(gasmix_power_ratio, 0.205) * 0.5 , explosion_power * max(gasmix_power_ratio, 0.205) + 2, explosion_power * max(gasmix_power_ratio, 0.205) + 4 , explosion_power * max(gasmix_power_ratio, 0.205) + 6, 1, 1)
	qdel(src)


//this is here to eat arguments
/obj/machinery/power/supermatter_crystal/proc/call_explode()
	explode()

/obj/machinery/power/supermatter_crystal/process_atmos()
	if(!processes) //Just fuck me up bro
		return
	var/turf/T = loc

	if(isnull(T))// We have a null turf...something is wrong, stop processing this entity.
		return PROCESS_KILL

	if(!istype(T))//We are in a crate or somewhere that isn't turf, if we return to turf resume processing but for now.
		return  //Yeah just stop.

	if(isclosedturf(T))
		var/turf/did_it_melt = T.Melt()
		if(!isclosedturf(did_it_melt)) //In case some joker finds way to place these on indestructible walls
			visible_message("<span class='warning'>[src] melts through [T]!</span>")
		return

	//We vary volume by power, and handle OH FUCK FUSION IN COOLING LOOP noises.
	if(power)
		soundloop.volume = clamp((50 + (power / 50)), 50, 100)
	if(damage >= 300)
		soundloop.mid_sounds = list('sound/machines/sm/loops/delamming.ogg' = 1)
	else
		soundloop.mid_sounds = list('sound/machines/sm/loops/calm.ogg' = 1)

	//We play delam/neutral sounds at a rate determined by power and damage
	if(last_accent_sound < world.time && prob(20))
		var/aggression = min(((damage / 800) * (power / 2500)), 1.0) * 100
		if(damage >= 300)
			playsound(src, "smdelam", max(50, aggression), FALSE, 10)
		else
			playsound(src, "smcalm", max(50, aggression), FALSE, 10)
		var/next_sound = round((100 - aggression) * 5)
		last_accent_sound = world.time + max(SUPERMATTER_ACCENT_SOUND_MIN_COOLDOWN, next_sound)

	//Ok, get the air from the turf
	var/datum/gas_mixture/env = T.return_air()

	var/datum/gas_mixture/removed
	if(produces_gas)
		//Remove gas from surrounding area
		removed = env.remove_ratio(gasefficency)
	else
		// Pass all the gas related code an empty gas container
		removed = new()
	damage_archived = damage

	var/list/gas_info = GLOB.gas_data.supermatter

	var/list/gases_we_care_about = gas_info[ALL_SUPERMATTER_GASES]

	/********
	EXPERIMENTAL, HUGBOXY AS HELL CITADEL CHANGES: Even in a vaccum, update gas composition and modifiers.
	This means that the SM will usually have a very small explosion if it ends up being breached to space,
	and CO2 tesla delaminations basically require multiple grounding rods to stabilize it long enough to not have it vent.
	*********/

	if(!removed || !removed.total_moles() || isspaceturf(T)) //we're in space or there is no gas to process
		if(takes_damage)
			damage += max((power / 1000) * DAMAGE_INCREASE_MULTIPLIER, 0.1) // always does at least some damage
		combined_gas = max(0, combined_gas - 0.5)		// Slowly wear off.
		for(var/gasID in gas_comp)
			gas_comp[gasID] = max(0, gas_comp[gasID] - 0.05)		//slowly ramp down
	else
		if(takes_damage)
			//causing damage
			//Due to DAMAGE_INCREASE_MULTIPLIER, we only deal one 4th of the damage the statements otherwise would cause

			//((((some value between 0.5 and 1 * temp - ((273.15 + 40) * some values between 1 and 10)) * some number between 0.25 and knock your socks off / 150) * 0.25
			//Heat and mols account for each other, a lot of hot mols are more damaging then a few
			//Mols start to have a positive effect on damage after 350
			var/spaced = 0
			for(var/turf/open/space/_space_turf in range(2,src))
				spaced++
			damage = max(damage + (max(clamp(removed.total_moles() / 200, 0.5, 1) * removed.return_temperature() - ((T0C + HEAT_PENALTY_THRESHOLD)*dynamic_heat_resistance), 0) * mole_heat_penalty / 150 ) * DAMAGE_INCREASE_MULTIPLIER, 0)
			//Power only starts affecting damage when it is above 5000
			damage = max(damage + (max(power - POWER_PENALTY_THRESHOLD, 0)/500) * DAMAGE_INCREASE_MULTIPLIER, 0)
			//Molar count only starts affecting damage when it is above 1800
			damage = max(damage + (max(combined_gas - MOLE_PENALTY_THRESHOLD, 0)/80) * DAMAGE_INCREASE_MULTIPLIER, 0)

			damage = max(damage + spaced * 0.1 * DAMAGE_INCREASE_MULTIPLIER, 0)

			//There might be a way to integrate healing and hurting via heat
			//healing damage
			if(combined_gas < MOLE_PENALTY_THRESHOLD && !spaced)
				//Only has a net positive effect when the temp is below 313.15, heals up to 2 damage. Psycologists increase this temp min by up to 45
				damage = max(damage + (min(removed.return_temperature() - (T0C + HEAT_PENALTY_THRESHOLD), 0) / 150), 0)

			//caps damage rate

			//Takes the lower number between archived damage + (1.8) and damage
			//This means we can only deal 1.8 damage per function call
			damage = min(damage_archived + (DAMAGE_HARDCAP * explosion_point), damage)

			//calculating gas related values
			//Wanna know a secret? See that max() to zero? it's used for error checking. If we get a mol count in the negative, we'll get a divide by zero error
			combined_gas = max(removed.total_moles(), 0)

			//This is more error prevention, according to all known laws of atmos, gas_mix.remove() should never make negative mol values.
			//But this is tg

			//Lets get the proportions of the gasses in the mix and then slowly move our comp to that value
			//Can cause an overestimation of mol count, should stabalize things though.
			//Prevents huge bursts of gas/heat when a large amount of something is introduced
			//They range between 0 and 1
			for(var/gasID in gases_we_care_about)
				if(!(gasID in gas_comp))
					gas_comp[gasID] = 0
				gas_comp[gasID] += clamp(max(removed.get_moles(gasID)/combined_gas, 0) - gas_comp[gasID], -1, gas_change_rate)

	var/list/threshold_mod = gases_we_care_about.Copy()

	var/list/powermix = gas_info[POWER_MIX]
	var/list/heat = gas_info[HEAT_PENALTY]
	var/list/transmit = gas_info[TRANSMIT_MODIFIER]
	var/list/resist = gas_info[HEAT_RESISTANCE]
	var/list/radioactivity = gas_info[RADIOACTIVITY_MODIFIER]
	var/list/inhibition = gas_info[POWERLOSS_INHIBITION]

	//We're concerned about pluoxium being too easy to abuse at low percents, so we make sure there's a substantial amount.
	var/pluoxiumbonus = (gas_comp[GAS_PLUOXIUM] >= 0.15) //makes pluoxium only work at 15%+
	var/h2obonus = 1 - (gas_comp[GAS_H2O] * 0.25)//At min this value should be 0.75
//		var/freonbonus = (gas_comp[/datum/gas/freon] <= 0.03) //Let's just yeet power output if this shit is high

	threshold_mod[GAS_PLUOXIUM] = pluoxiumbonus

	//No less then zero, and no greater then one, we use this to do explosions and heat to power transfer
	//Be very careful with modifing this var by large amounts, and for the love of god do not push it past 1
	gasmix_power_ratio = 0
	//Affects the amount of o2 and plasma the sm outputs, along with the heat it makes.
	var/dynamic_heat_modifier = 0
	//Effects the damage heat does to the crystal.
	dynamic_heat_resistance = 0
	//We multiply this with power to find the rads.
	var/power_transmission_bonus = 0
	var/powerloss_inhibition_gas = 0
	var/radioactivity_modifier = 0
	for(var/gasID in gas_comp)
		var/this_comp = gas_comp[gasID] * (isnull(threshold_mod[gasID] ? 1 : threshold_mod[gasID]))
		gasmix_power_ratio += this_comp * powermix[gasID]
		dynamic_heat_modifier += this_comp * heat[gasID]
		dynamic_heat_resistance += this_comp * resist[gasID]
		power_transmission_bonus += this_comp * transmit[gasID]
		powerloss_inhibition_gas += this_comp * inhibition[gasID]
		radioactivity_modifier += this_comp * radioactivity[gasID]
	dynamic_heat_modifier *= h2obonus
	power_transmission_bonus *= h2obonus
	gasmix_power_ratio = clamp(gasmix_power_ratio, 0, 1)
	dynamic_heat_modifier = max(dynamic_heat_modifier, 0.5)

	//more moles of gases are harder to heat than fewer, so let's scale heat damage around them
	mole_heat_penalty = max(combined_gas / MOLE_HEAT_PENALTY, 0.25)

	//Ramps up or down in increments of 0.02 up to the proportion of co2
	//Given infinite time, powerloss_dynamic_scaling = co2comp
	//Some value between 0 and 1
	if (combined_gas > POWERLOSS_INHIBITION_MOLE_THRESHOLD && powerloss_inhibition_gas > POWERLOSS_INHIBITION_GAS_THRESHOLD) //If there are more then 20 mols, and more then 20% co2
		powerloss_dynamic_scaling = clamp(powerloss_dynamic_scaling + clamp(powerloss_inhibition_gas - powerloss_dynamic_scaling, -0.02, 0.02), 0, 1)
	else
		powerloss_dynamic_scaling = clamp(powerloss_dynamic_scaling - 0.05, 0, 1)
	//Ranges from 0 to 1 (1-(value between 0 and 1 * ranges from 1 to 1.5(mol / 500)))
	//0 means full inhibition, 1 means no inhibition
	//We take the mol count, and scale it to be our inhibitor
	powerloss_inhibitor = clamp(1-(powerloss_dynamic_scaling * clamp(combined_gas/POWERLOSS_INHIBITION_MOLE_BOOST_THRESHOLD, 1, 1.5)), 0, 1)

	//Releases stored power into the general pool
	//We get this by consuming shit or being scalpeled
	if(matter_power && power_changes)
		//We base our removed power off one 10th of the matter_power.
		var/removed_matter = max(matter_power/MATTER_POWER_CONVERSION, 40)
		//Adds at least 40 power
		power = max(power + removed_matter, 0)
		//Removes at least 40 matter power
		matter_power = max(matter_power - removed_matter, 0)

	var/temp_factor = 50
	if(gasmix_power_ratio > 0.8)
		//with a perfect gas mix, make the power more based on heat
		icon_state = "[base_icon_state]_glow"
	else
		//in normal mode, power is less effected by heat
		temp_factor = 30
		icon_state = base_icon_state

	var/effective_temperature = min(removed.return_temperature(), 2500 * dynamic_heat_modifier)

	//if there is more pluox and n2 then anything else, we receive no power increase from heat
	if(power_changes)
		power = max((effective_temperature * temp_factor / T0C) * gasmix_power_ratio + power, 0)

	if(prob(50))
		//(1 + (tritRad + pluoxDampen * bzDampen * o2Rad * plasmaRad / (10 - bzrads))) * freonbonus
		radiation_pulse(src, power * max(0, (1 + (power_transmission_bonus/(10-radioactivity_modifier)))))//freonbonus))// RadModBZ(500%)
	if(radioactivity_modifier >= 2 && prob(6 * radioactivity_modifier))
		src.fire_nuclear_particle()

	//Power * 0.55 * a value between 1 and 0.8
	var/device_energy = power * REACTION_POWER_MODIFIER

	var/max_temp_increase = effective_temperature + ((device_energy * dynamic_heat_modifier) / THERMAL_RELEASE_CAP_MODIFIER)
	//Calculate how much gas to release
	//Varies based on power and gas content
	removed.adjust_moles(GAS_PLASMA, clamp((device_energy * dynamic_heat_modifier) / PLASMA_RELEASE_MODIFIER, 0, 50))
	//Varies based on power, gas content, and heat
	removed.adjust_moles(GAS_O2, clamp((device_energy * dynamic_heat_modifier + effective_temperature - T20C) / OXYGEN_RELEASE_MODIFIER, 0, 100))

	if(removed.return_temperature() < max_temp_increase)
		removed.adjust_heat(device_energy * dynamic_heat_modifier * THERMAL_RELEASE_MODIFIER)
	removed.set_temperature(min(removed.return_temperature(), max_temp_increase))


	if(produces_gas)
		env.merge(removed)
		air_update_turf()

	/*********
	END CITADEL CHANGES
	*********/

	//Makes em go mad and accumulate rads.
	for(var/mob/living/carbon/human/l in fov_viewers(src, HALLUCINATION_RANGE(power))) // If they can see it without mesons on.  Bad on them.
		if(!istype(l.glasses, /obj/item/clothing/glasses/meson))
			var/D = sqrt(1 / max(1, get_dist(l, src)))
			if(!l.hallucination)
				to_chat(l, "<span class='warning'>Looking at the supermatter unprotected gives you a headache...</span>")
			l.hallucination += power * hallucination_power * D
			l.hallucination = clamp(l.hallucination, 0, 200)
	for(var/mob/living/l in range(src, round((power / 100) ** 0.25)))
		var/rads = (power / 10) * sqrt( 1 / max(get_dist(l, src),1) )
		l.rad_act(rads)

	//Transitions between one function and another, one we use for the fast inital startup, the other is used to prevent errors with fusion temperatures.
	//Use of the second function improves the power gain imparted by using co2
	if(power_changes)
		power = max(power - min(((power/500)**3) * powerloss_inhibitor, power * 0.83 * powerloss_inhibitor),0)
	//After this point power is lowered
	//This wraps around to the begining of the function
	//Handle high power zaps/anomaly generation
	if(power > POWER_PENALTY_THRESHOLD || damage > damage_penalty_point) //If the power is above 5000 or if the damage is above 550
		var/range = 4
		zap_cutoff = 1500
		if(removed && removed.return_pressure() > 0 && removed.return_temperature() > 0)
			//You may be able to freeze the zapstate of the engine with good planning, we'll see
			zap_cutoff = clamp(3000 - (power * (removed.total_moles()) / 10) / removed.return_temperature(), 350, 3000)//If the core is cold, it's easier to jump, ditto if there are a lot of mols
			//We should always be able to zap our way out of the default enclosure
			//See supermatter_zap() for more details
			range = clamp(power / removed.return_pressure() * 10, 2, 7)
		var/flags = ZAP_SUPERMATTER_FLAGS
		var/zap_count = 0
		//Deal with power zaps
		switch(power)
			if(POWER_PENALTY_THRESHOLD to SEVERE_POWER_PENALTY_THRESHOLD)
				zap_icon = DEFAULT_ZAP_ICON_STATE
				zap_count = 2
			if(SEVERE_POWER_PENALTY_THRESHOLD to CRITICAL_POWER_PENALTY_THRESHOLD)
				zap_icon = SLIGHTLY_CHARGED_ZAP_ICON_STATE
				//Uncaps the zap damage, it's maxed by the input power
				//Objects take damage now
				flags |= (ZAP_MOB_DAMAGE)
				zap_count = 3
			if(CRITICAL_POWER_PENALTY_THRESHOLD to INFINITY)
				zap_icon = OVER_9000_ZAP_ICON_STATE
				//It'll stun more now, and damage will hit harder, gloves are no garentee.
				//Machines go boom
				flags |= (ZAP_MOB_STUN | ZAP_MOB_DAMAGE)
				zap_count = 4
		//Now we deal with damage shit
		if (damage > damage_penalty_point && prob(20))
			zap_count += 1

		if(zap_count >= 1)
			playsound(src.loc, 'sound/weapons/emitter2.ogg', 100, TRUE, extrarange = 10)
			for(var/i in 1 to zap_count)
				supermatter_zap(src, range, clamp(power*2, 4000, 20000), flags)

		if(prob(5))
			supermatter_anomaly_gen(src, FLUX_ANOMALY, rand(5, 10))
		if(power > SEVERE_POWER_PENALTY_THRESHOLD && prob(5) || prob(1))
			supermatter_anomaly_gen(src, GRAVITATIONAL_ANOMALY, rand(5, 10))
		if((power > SEVERE_POWER_PENALTY_THRESHOLD && prob(2)) || (prob(0.3) && power > POWER_PENALTY_THRESHOLD))
			supermatter_anomaly_gen(src, PYRO_ANOMALY, rand(5, 10))

	if(prob(15))
		supermatter_pull(loc, min(power/850, 3))//850, 1700, 2550

	//Tells the engi team to get their butt in gear
	if(damage > warning_point) // while the core is still damaged and it's still worth noting its status
		if(damage_archived < warning_point) //If damage_archive is under the warning point, this is the very first cycle that we've reached said point.
			SEND_SIGNAL(src, COMSIG_SUPERMATTER_DELAM_START_ALARM)
		if((REALTIMEOFDAY - lastwarning) / 10 >= WARNING_DELAY)
			alarm()

			//Oh shit it's bad, time to freak out
			if(damage > emergency_point)
				// it's bad, LETS YELL
				radio.talk_into(src, "[emergency_alert] Integrity: [get_integrity()]%", common_channel, list(SPAN_YELL))
				SEND_SIGNAL(src, COMSIG_SUPERMATTER_DELAM_ALARM)
				lastwarning = REALTIMEOFDAY
				if(!has_reached_emergency)
					investigate_log("has reached the emergency point for the first time.", INVESTIGATE_SUPERMATTER)
					message_admins("[src] has reached the emergency point [ADMIN_JMP(src)].")
					has_reached_emergency = TRUE
			else if(damage >= damage_archived) // The damage is still going up
				radio.talk_into(src, "[warning_alert] Integrity: [get_integrity()]%", engineering_channel)
				SEND_SIGNAL(src, COMSIG_SUPERMATTER_DELAM_ALARM)
				lastwarning = REALTIMEOFDAY - (WARNING_DELAY * 5)

			else                                                 // Phew, we're safe
				radio.talk_into(src, "[safe_alert] Integrity: [get_integrity()]%", engineering_channel)
				lastwarning = REALTIMEOFDAY

			if(power > POWER_PENALTY_THRESHOLD)
				radio.talk_into(src, "Warning: Hyperstructure has reached dangerous power level.", engineering_channel)
				if(powerloss_inhibitor < 0.5)
					radio.talk_into(src, "DANGER: CHARGE INERTIA CHAIN REACTION IN PROGRESS.", engineering_channel)

			if(combined_gas > MOLE_PENALTY_THRESHOLD)
				radio.talk_into(src, "Warning: Critical coolant mass reached.", engineering_channel)
		//Boom (Mind blown)
		if(damage > explosion_point)
			countdown()

	return TRUE

/obj/machinery/power/supermatter_crystal/bullet_act(obj/item/projectile/Proj)
	var/turf/L = loc
	if(!istype(L))
		return FALSE
	if(!istype(Proj.firer, /obj/machinery/power/emitter) && power_changes)
		investigate_log("has been hit by [Proj] fired by [key_name(Proj.firer)]", INVESTIGATE_SUPERMATTER)
	if(Proj.flag != BULLET)
		if(power_changes) //This needs to be here I swear
			power += Proj.damage * bullet_energy
			if(!has_been_powered)
				investigate_log("has been powered for the first time.", INVESTIGATE_SUPERMATTER)
				message_admins("[src] has been powered for the first time [ADMIN_JMP(src)].")
				has_been_powered = TRUE
	else if(takes_damage)
		matter_power += Proj.damage * bullet_energy
	return BULLET_ACT_HIT

/obj/machinery/power/supermatter_crystal/singularity_act()
	var/gain = 100
	investigate_log("Supermatter shard consumed by singularity.", INVESTIGATE_SINGULO)
	message_admins("Singularity has consumed a supermatter shard and can now become stage six.")
	visible_message("<span class='userdanger'>[src] is consumed by the singularity!</span>")
	for(var/mob/M in GLOB.player_list)
		if(M.z == z)
			SEND_SOUND(M, 'sound/effects/supermatter.ogg') //everyone goan know bout this
			to_chat(M, "<span class='boldannounce'>A horrible screeching fills your ears, and a wave of dread washes over you...</span>")
	qdel(src)
	return gain

/obj/machinery/power/supermatter_crystal/blob_act(obj/structure/blob/B)
	if(B && !isspaceturf(loc)) //does nothing in space
		playsound(get_turf(src), 'sound/effects/supermatter.ogg', 50, TRUE)
		damage += B.obj_integrity * 0.5 //take damage equal to 50% of remaining blob health before it tried to eat us
		if(B.obj_integrity > 100)
			B.visible_message("<span class='danger'>\The [B] strikes at \the [src] and flinches away!</span>",\
			"<span class='hear'>You hear a loud crack as you are washed with a wave of heat.</span>")
			B.take_damage(100, BURN)
		else
			B.visible_message("<span class='danger'>\The [B] strikes at \the [src] and rapidly flashes to ash.</span>",\
			"<span class='hear'>You hear a loud crack as you are washed with a wave of heat.</span>")
			Consume(B)

/obj/machinery/power/supermatter_crystal/attack_tk(mob/user)
	if(iscarbon(user))
		var/mob/living/carbon/C = user
		log_game("[key_name(C)] has been disintegrated by a telekenetic grab on a supermatter crystal.</span>")
		to_chat(C, "<span class='userdanger'>That was a really dense idea.</span>")
		C.visible_message("<span class='userdanger'>A bright flare of radiation is seen from [C]'s head, shortly before you hear a sickening sizzling!</span>")
		C.ghostize()
		var/obj/item/organ/brain/rip_u = locate(/obj/item/organ/brain) in C.internal_organs
		rip_u.Remove(C)
		qdel(rip_u)

/obj/machinery/power/supermatter_crystal/attack_paw(mob/user)
	dust_mob(user, cause = "monkey attack")

/obj/machinery/power/supermatter_crystal/attack_alien(mob/user)
	dust_mob(user, cause = "alien attack")

/obj/machinery/power/supermatter_crystal/attack_animal(mob/living/simple_animal/S)
	var/murder
	if(!S.melee_damage_upper && !S.melee_damage_lower)
		murder = S.friendly_verb_continuous
	else
		murder = S.attack_verb_continuous
	dust_mob(S, \
	"<span class='danger'>[S] unwisely [murder] [src], and [S.p_their()] body burns brilliantly before flashing into ash!</span>", \
	"<span class='userdanger'>You unwisely touch [src], and your vision glows brightly as your body crumbles to dust. Oops.</span>", \
	"simple animal attack")

/obj/machinery/power/supermatter_crystal/attack_robot(mob/user)
	if(Adjacent(user))
		dust_mob(user, cause = "cyborg attack")

/obj/machinery/power/supermatter_crystal/attack_ai(mob/user)
	return

/obj/machinery/power/supermatter_crystal/on_attack_hand(mob/living/user)
	. = ..()
	dust_mob(user, cause = "hand")

/obj/machinery/power/supermatter_crystal/proc/dust_mob(mob/living/nom, vis_msg, mob_msg, cause)
	if(nom.incorporeal_move || nom.status_flags & GODMODE) //try to keep supermatter sliver's + hemostat's dust conditions in sync with this too
		return
	if(!vis_msg)
		vis_msg = "<span class='danger'>[nom] reaches out and touches [src], inducing a resonance... [nom.p_their()] body starts to glow and burst into flames before flashing into dust!</span>"
	if(!mob_msg)
		mob_msg = "<span class='userdanger'>You reach out and touch [src]. Everything starts burning and all you can hear is ringing. Your last thought is \"That was not a wise decision.\"</span>"
	if(!cause)
		cause = "contact"
	nom.visible_message(vis_msg, mob_msg, "<span class='hear'>You hear an unearthly noise as a wave of heat washes over you.</span>")
	investigate_log("has been attacked ([cause]) by [key_name(nom)]", INVESTIGATE_SUPERMATTER)
	playsound(get_turf(src), 'sound/effects/supermatter.ogg', 50, TRUE)
	Consume(nom)

/obj/machinery/power/supermatter_crystal/attackby(obj/item/W, mob/living/user, params)
	if(!istype(W) || (W.item_flags & ABSTRACT) || !istype(user))
		return
	if(istype(W, /obj/item/melee/roastingstick))
		return ..()
	if(istype(W, /obj/item/clothing/mask/cigarette))
		var/obj/item/clothing/mask/cigarette/cig = W
		var/clumsy = HAS_TRAIT(user, TRAIT_CLUMSY)
		if(clumsy)
			var/which_hand = BODY_ZONE_L_ARM
			if(!(user.active_hand_index % 2))
				which_hand = BODY_ZONE_R_ARM
			var/obj/item/bodypart/dust_arm = user.get_bodypart(which_hand)
			dust_arm.dismember()
			user.visible_message("<span class='danger'>The [W] flashes out of existence on contact with \the [src], resonating with a horrible sound...</span>",\
				"<span class='danger'>Oops! The [W] flashes out of existence on contact with \the [src], taking your arm with it! That was clumsy of you!</span>")
			playsound(src, 'sound/effects/supermatter.ogg', 150, TRUE)
			Consume(dust_arm)
			qdel(W)
			return
		if(cig.lit || user.a_intent != INTENT_HELP)
			user.visible_message("<span class='danger'>A hideous sound echoes as [W] is ashed out on contact with \the [src]. That didn't seem like a good idea...</span>")
			playsound(src, 'sound/effects/supermatter.ogg', 150, TRUE)
			Consume(W)
			radiation_pulse(src, 150, 4)
			return ..()
		else
			cig.light()
			user.visible_message("<span class='danger'>As [user] lights \their [W] on \the [src], silence fills the room...</span>",\
				"<span class='danger'>Time seems to slow to a crawl as you touch \the [src] with \the [W].</span>\n<span class='notice'>\The [W] flashes alight with an eerie energy as you nonchalantly lift your hand away from \the [src]. Damn.</span>")
			playsound(src, 'sound/effects/supermatter.ogg', 50, TRUE)
			radiation_pulse(src, 50, 3)
			return
	if(istype(W, /obj/item/scalpel/supermatter))
		var/obj/item/scalpel/supermatter/scalpel = W
		to_chat(user, "<span class='notice'>You carefully begin to scrape \the [src] with \the [W]...</span>")
		if(W.use_tool(src, user, 60, volume=100))
			if (scalpel.usesLeft)
				to_chat(user, "<span class='danger'>You extract a sliver from \the [src]. \The [src] begins to react violently!</span>")
				new /obj/item/nuke_core/supermatter_sliver(drop_location())
				matter_power += 800
				scalpel.usesLeft--
				if (!scalpel.usesLeft)
					to_chat(user, "<span class='notice'>A tiny piece of \the [W] falls off, rendering it useless!</span>")
			else
				to_chat(user, "<span class='warning'>You fail to extract a sliver from \The [src]! \the [W] isn't sharp enough anymore.</span>")
	else if(user.dropItemToGround(W))
		user.visible_message("<span class='danger'>As [user] touches \the [src] with \a [W], silence fills the room...</span>",\
			"<span class='userdanger'>You touch \the [src] with \the [W], and everything suddenly goes silent.</span>\n<span class='notice'>\The [W] flashes into dust as you flinch away from \the [src].</span>",\
			"<span class='hear'>Everything suddenly goes silent.</span>")
		investigate_log("has been attacked ([W]) by [key_name(user)]", INVESTIGATE_SUPERMATTER)
		Consume(W)
		playsound(get_turf(src), 'sound/effects/supermatter.ogg', 50, TRUE)

		radiation_pulse(src, 150, 4)

	else if(Adjacent(user)) //if the item is stuck to the person, kill the person too instead of eating just the item.
		var/vis_msg = "<span class='danger'>[user] reaches out and touches [src] with [W], inducing a resonance... [W] starts to glow briefly before the light continues up to [user]'s body. [user.p_they(TRUE)] bursts into flames before flashing into dust!</span>"
		var/mob_msg = "<span class='userdanger'>You reach out and touch [src] with [W]. Everything starts burning and all you can hear is ringing. Your last thought is \"That was not a wise decision.\"</span>"
		dust_mob(user, vis_msg, mob_msg)

/obj/machinery/power/supermatter_crystal/wrench_act(mob/user, obj/item/tool)
	..()
	if (moveable)
		default_unfasten_wrench(user, tool, time = 20)
	return TRUE

/obj/machinery/power/supermatter_crystal/Bumped(atom/movable/AM)
	if(isliving(AM))
		AM.visible_message("<span class='danger'>\The [AM] slams into \the [src] inducing a resonance... [AM.p_their()] body starts to glow and burst into flames before flashing into dust!</span>",\
		"<span class='userdanger'>You slam into \the [src] as your ears are filled with unearthly ringing. Your last thought is \"Oh, fuck.\"</span>",\
		"<span class='hear'>You hear an unearthly noise as a wave of heat washes over you.</span>")
	else if(isobj(AM) && !iseffect(AM))
		AM.visible_message("<span class='danger'>\The [AM] smacks into \the [src] and rapidly flashes to ash.</span>", null,\
		"<span class='hear'>You hear a loud crack as you are washed with a wave of heat.</span>")
	else
		return

	playsound(get_turf(src), 'sound/effects/supermatter.ogg', 50, TRUE)
	Consume(AM)

/obj/machinery/power/supermatter_crystal/intercept_zImpact(atom/movable/AM, levels)
	. = ..()
	Bumped(AM)
	. |= FALL_STOP_INTERCEPTING | FALL_INTERCEPTED

/obj/machinery/power/supermatter_crystal/proc/Consume(atom/movable/AM)
	if(isliving(AM))
		var/mob/living/user = AM
		if(user.status_flags & GODMODE)
			return
		var/add
		if(user.mind?.assigned_role == "Clown")
			var/denergy = rand(-1000, 1000)
			var/ddamage = rand(-150, clamp(150, 0, (explosion_point - damage) + 150))
			power += denergy
			damage += ddamage
			add = ", adding [denergy] energy and [ddamage] damage to the crystal"
		message_admins("[src] has consumed [key_name_admin(user)] [ADMIN_JMP(src)][add].")
		investigate_log("has consumed [key_name(user)][add].", INVESTIGATE_SUPERMATTER)
		user.dust(force = TRUE)
		if(power_changes)
			matter_power += 200
	else if(istype(AM, /obj/singularity))
		return
	else if(isobj(AM))
		if(!iseffect(AM))
			var/suspicion = ""
			if(AM.fingerprintslast)
				suspicion = "last touched by [AM.fingerprintslast]"
				message_admins("[src] has consumed [AM], [suspicion] [ADMIN_JMP(src)].")
			investigate_log("has consumed [AM] - [suspicion].", INVESTIGATE_SUPERMATTER)
		qdel(AM)
	if(!iseffect(AM) && power_changes)
		matter_power += 200

	//Some poor sod got eaten, go ahead and irradiate people nearby.
	radiation_pulse(src, 3000, 2, TRUE)
	for(var/mob/living/L in range(10))
		investigate_log("has irradiated [key_name(L)] after consuming [AM].", INVESTIGATE_SUPERMATTER)
		var/list/viewers = fov_viewers(world.view, src)
		if(L in viewers)
			L.show_message("<span class='danger'>As \the [src] slowly stops resonating, you find your skin covered in new radiation burns.</span>", MSG_VISUAL,\
				"<span class='danger'>The unearthly ringing subsides and you notice you have new radiation burns.</span>", MSG_AUDIBLE)
		else
			L.show_message("<span class='hear'>You hear an unearthly ringing and notice your skin is covered in fresh radiation burns.</span>", MSG_AUDIBLE)

/obj/machinery/power/supermatter_crystal/proc/consume_turf(turf/T)
	var/oldtype = T.type
	var/turf/newT = T.ScrapeAway()
	if(newT.type == oldtype)
		return
	playsound(T, 'sound/effects/supermatter.ogg', 50, 1)
	T.visible_message("<span class='danger'>[T] smacks into [src] and rapidly flashes to ash.</span>",\
	"<span class='italics'>You hear a loud crack as you are washed with a wave of heat.</span>")
	T.ImmediateCalculateAdjacentTurfs()

//Do not blow up our internal radio
/obj/machinery/power/supermatter_crystal/contents_explosion(severity, target, origin)
	return

/obj/machinery/power/supermatter_crystal/engine
	is_main_engine = TRUE

/obj/machinery/power/supermatter_crystal/shard
	name = "supermatter shard"
	desc = "A strangely translucent and iridescent crystal that looks like it used to be part of a larger structure."
	base_icon_state = "darkmatter_shard"
	icon = 'GainStation13/icons/turf/supermatter.dmi' // GS13 EDIT 'icons/obj/supermatter.dmi'
	icon_state = "darkmatter_shard"
	anchored = FALSE
	gasefficency = 0.125
	explosion_power = 12
	layer = ABOVE_MOB_LAYER
	moveable = TRUE

/obj/machinery/power/supermatter_crystal/shard/examine(mob/user)
	. = ..()
	if(anchored)
		. += "<span class='notice'>[src] is <b>anchored</b> to the floor.</span>"
	else
		. += "<span class='notice'>[src] is <i>unanchored</i>, but can be <b>bolted</b> down.</span>"

/obj/machinery/power/supermatter_crystal/shard/engine
	name = "anchored supermatter shard"
	is_main_engine = TRUE
	anchored = TRUE
	moveable = FALSE

// When you wanna make a supermatter shard for the dramatic effect, but
// don't want it exploding suddenly
/obj/machinery/power/supermatter_crystal/shard/hugbox
	name = "anchored supermatter shard"
	takes_damage = FALSE
	produces_gas = FALSE
	power_changes = FALSE
	processes = FALSE //SHUT IT DOWN
	moveable = FALSE
	anchored = TRUE

/obj/machinery/power/supermatter_crystal/shard/hugbox/fakecrystal //Hugbox shard with crystal visuals, used in the Supermatter/Hyperfractal shuttle
	name = "supermatter crystal"
	base_icon_state = "darkmatter"
	icon_state = "darkmatter"

/obj/machinery/power/supermatter_crystal/proc/supermatter_pull(turf/center, pull_range = 3)
	playsound(center, 'sound/weapons/marauder.ogg', 100, TRUE, extrarange = pull_range - world.view)
	for(var/atom/movable/P in orange(pull_range,center))
		if((P.anchored || P.move_resist >= MOVE_FORCE_EXTREMELY_STRONG)) //move resist memes.
			if(istype(P, /obj/structure/closet))
				var/obj/structure/closet/toggle = P
				toggle.open()
			continue
		if(ismob(P))
			var/mob/M = P
			if(M.mob_negates_gravity())
				continue //You can't pull someone nailed to the deck
		step_towards(P,center)

/obj/machinery/power/supermatter_crystal/proc/supermatter_anomaly_gen(turf/anomalycenter, type = FLUX_ANOMALY, anomalyrange = 5)
	var/turf/L = pick(orange(anomalyrange, anomalycenter))
	if(L)
		switch(type)
			if(FLUX_ANOMALY)
				var/obj/effect/anomaly/flux/A = new(L, 300, SUPERMATTER_ANOMALY_DROP_CHANCE)
				A.explosive = FALSE
			if(GRAVITATIONAL_ANOMALY)
				new /obj/effect/anomaly/grav(L, 250, SUPERMATTER_ANOMALY_DROP_CHANCE)
			if(PYRO_ANOMALY)
				new /obj/effect/anomaly/pyro(L, 200, SUPERMATTER_ANOMALY_DROP_CHANCE)

/obj/machinery/power/supermatter_crystal/proc/supermatter_zap(atom/zapstart = src, range = 5, zap_str = 4000, zap_flags = ZAP_SUPERMATTER_FLAGS, list/targets_hit = list())
	if(QDELETED(zapstart))
		return
	. = zapstart.dir
	//If the strength of the zap decays past the cutoff, we stop
	if(zap_str < zap_cutoff)
		return
	var/atom/target
	var/target_type = LOWEST
	var/list/arctargets = list()
	//Making a new copy so additons further down the recursion do not mess with other arcs
	//Lets put this ourself into the do not hit list, so we don't curve back to hit the same thing twice with one arc
	for(var/test in oview(zapstart, range))
		if(!(zap_flags & ZAP_ALLOW_DUPLICATES) && LAZYACCESS(targets_hit, test))
			continue

		if(istype(test, /obj/vehicle/ridden/bicycle/))
			var/obj/vehicle/ridden/bicycle/bike = test
			if(!(bike.obj_flags & BEING_SHOCKED) && bike.can_buckle)//God's not on our side cause he hates idiots.
				if(target_type != BIKE)
					arctargets = list()
				arctargets += test
				target_type = BIKE

		if(target_type > COIL)
			continue

		if(istype(test, /obj/machinery/power/tesla_coil/))
			var/obj/machinery/power/tesla_coil/coil = test
			if(coil.anchored && !(coil.obj_flags & BEING_SHOCKED) && !coil.panel_open && prob(70))//Diversity of death
				if(target_type != COIL)
					arctargets = list()
				arctargets += test
				target_type = COIL

		if(target_type > ROD)
			continue

		if(istype(test, /obj/machinery/power/grounding_rod/))
			var/obj/machinery/power/grounding_rod/rod = test
			//We're adding machine damaging effects, rods need to be surefire
			if(rod.anchored && !rod.panel_open)
				if(target_type != ROD)
					arctargets = list()
				arctargets += test
				target_type = ROD

		if(target_type > LIVING)
			continue

		if(istype(test, /mob/living/))
			var/mob/living/alive = test
			if(!(HAS_TRAIT(alive, TRAIT_TESLA_SHOCKIMMUNE)) && !(alive.flags_1 & SHOCKED_1) && alive.stat != DEAD && prob(20))//let's not hit all the engineers with every beam and/or segment of the arc
				if(target_type != LIVING)
					arctargets = list()
				arctargets += test
				target_type = LIVING

		if(target_type > MACHINERY)
			continue

		if(istype(test, /obj/machinery/))
			var/obj/machinery/machine = test
			if(!(machine.obj_flags & BEING_SHOCKED) && prob(40))
				if(target_type != MACHINERY)
					arctargets = list()
				arctargets += test
				target_type = MACHINERY

		if(target_type > OBJECT)
			continue

		if(istype(test, /obj/))
			var/obj/object = test
			if(!(object.obj_flags & BEING_SHOCKED))
				if(target_type != OBJECT)
					arctargets = list()
				arctargets += test
				target_type = OBJECT

	if(arctargets.len)//Pick from our pool
		target = pick(arctargets)

	if(!QDELETED(target))//If we found something
		//Do the animation to zap to it from here
		if(!(zap_flags & ZAP_ALLOW_DUPLICATES))
			LAZYSET(targets_hit, target, TRUE)
		zapstart.Beam(target, icon_state=zap_icon, time=5)
		var/zapdir = get_dir(zapstart, target)
		if(zapdir)
			. = zapdir

		if(target_type == COIL)
			//In the best situation we can expect this to grow up to 2120kw before a delam/IT'S GONE TOO FAR FRED SHUT IT DOWN
			//The formula for power gen is zap_str * zap_mod / 2 * capacitor rating, between 1 and 4
			var/multi = 10
			switch(power)//Between 7k and 9k it's 20, above that it's 40
				if(SEVERE_POWER_PENALTY_THRESHOLD to CRITICAL_POWER_PENALTY_THRESHOLD)
					multi = 20
				if(CRITICAL_POWER_PENALTY_THRESHOLD to INFINITY)
					multi = 40
			target.zap_act(zap_str * multi, zap_flags, list())
			zap_str /= 3 //Coils should take a lot out of the power of the zap

		else if(target_type == ROD)
			//We can expect this to do very little, maybe shock the poor soul buckled to it, but that's all.
			//This is one of our endpoints, if the bolt hits a grounding rod, it stops jumping
			target.zap_act(zap_str, zap_flags, list())
			return

		else if(isliving(target))//If we got a fleshbag on our hands
			var/mob/living/creature = target
			creature.set_shocked()
			addtimer(CALLBACK(creature, TYPE_PROC_REF(/mob/living, reset_shocked)), 10)
			//3 shots a human with no resistance. 2 to crit, one to death. This is at at least 10000 power.
			//There's no increase after that because the input power is effectivly capped at 10k
			//Does 1.5 damage at the least
			var/shock_damage = ((zap_flags & ZAP_MOB_DAMAGE) ? (power / 200) - 10 : rand(5,10))
			creature.electrocute_act(shock_damage, "Supermatter Discharge Bolt", 1,  ((zap_flags & ZAP_MOB_STUN) ? SHOCK_TESLA : SHOCK_NOSTUN))
			zap_str /= 1.5 //Meatsacks are conductive, makes working in pairs more destructive

		else
			target.zap_act(zap_str, zap_flags, list())
			zap_str /= 2 // worse then living things, better then coils
		//This gotdamn variable is a boomer and keeps giving me problems
		var/turf/T = get_turf(target)
		var/pressure = 1
		if(T && T.return_air())
			pressure = max(1,T.return_air().return_pressure())
		//We get our range with the strength of the zap and the pressure, the higher the former and the lower the latter the better
		var/new_range = clamp(zap_str / pressure * 10, 2, 7)
		var/zap_count = 1
		if(prob(5))
			zap_str -= (zap_str/10)
			zap_count += 1
		for(var/j in 1 to zap_count)
			if(zap_count > 1)
				targets_hit = targets_hit.Copy() //Pass by ref begone
			supermatter_zap(target, new_range, zap_str, zap_flags, targets_hit)

#undef HALLUCINATION_RANGE
#undef GRAVITATIONAL_ANOMALY
#undef FLUX_ANOMALY
#undef PYRO_ANOMALY
#undef BIKE
#undef COIL
#undef ROD
#undef LIVING
#undef MACHINERY
#undef OBJECT
#undef LOWEST
