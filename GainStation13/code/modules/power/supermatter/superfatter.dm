#define HALLUCINATION_RANGE(P) (min(7, round(P ** 0.25)))


#define GRAVITATIONAL_ANOMALY "gravitational_anomaly"
#define FLUX_ANOMALY "flux_anomaly"
#define PYRO_ANOMALY "pyro_anomaly"

/obj/machinery/power/supermatter_crystal/superfatter_crystal
	name = "superfatter crystal"
	desc = "A strangely translucent and orange-ish crystal."
	icon = 'GainStation13/icons/turf/supermatter.dmi' // GS13 EDIT 'icons/obj/supermatter.dmi'
	icon_state = "caloritematter"
	base_icon_state = "caloritematter"
	
	var/ignore_prefs = TRUE

/obj/machinery/power/supermatter_crystal/superfatter_crystal/shard
	name = "superfatter shard"
	desc = "A strangely translucent and orange-ish crystal that looks like it used to be part of a larger structure."
	icon_state = "caloritematter_shard"
	anchored = FALSE
	gasefficency = 0.125
	explosion_power = 12
	layer = ABOVE_MOB_LAYER
	moveable = TRUE

/obj/machinery/power/supermatter_crystal/superfatter_crystal/dust_mob(mob/living/nom, vis_msg, mob_msg, cause)
	// . = ..()
	if(nom.incorporeal_move || nom.status_flags & GODMODE) //try to keep supermatter sliver's + hemostat's dust conditions in sync with this too
		return
	if(!vis_msg)
		vis_msg = "<span class='danger'>[nom] reaches out and touches [src], inducing a resonance... [nom.p_their()] body starts to wobble and swell before being engulfed by a mountain of fat!</span>"
	if(!mob_msg)
		mob_msg = "<span class='userdanger'>You reach out and touch [src]. Your body starts swelling and all you can feel is your increasing weight.</span>"
	if(!cause)
		cause = "contact"
	nom.visible_message(vis_msg, mob_msg, "<span class='hear'>You hear a strange, soft noise and feel as if your belt became a little tight.</span>")
	investigate_log("has been attacked ([cause]) by [key_name(nom)]", INVESTIGATE_SUPERMATTER)
	playsound(get_turf(src), 'sound/effects/supermatter.ogg', 50, TRUE)
	if(istype(nom, mob/living/carbon/human))
		fatten_mob(nom)

/obj/machinery/power/supermatter_crystal/superfatter_crystal/blob_act(obj/structure/blob/B)
	return

/obj/machinery/power/supermatter_crystal/superfatter_crystal/attack_tk(mob/user)
	return

/obj/machinery/power/supermatter_crystal/superfatter_crystal/attack_paw(mob/user)
	return

/obj/machinery/power/supermatter_crystal/superfatter_crystal/attack_alien(mob/user)
	return

/obj/machinery/power/supermatter_crystal/superfatter_crystal/attack_animal(mob/living/simple_animal/S)
	return

/obj/machinery/power/supermatter_crystal/superfatter_crystal/attack_robot(mob/user)
	return

/obj/machinery/power/supermatter_crystal/superfatter_crystal/proc/fatten_mob(mob/living/carbon/human/fatty)
	var/fattening_type = FATTENING_TYPE_MAGIC
	var/gain_amount = 3500
	if(ignore_prefs)
		fattening_type = FATTENING_TYPE_ALMIGHTY

	var/datum/preferences/preferences = fatty?.client?.prefs
	if(!istype(preferences) || HAS_TRAIT(fatty, TRAIT_NO_HELPLESSNESS))
		fatty.adjust_fatness(gain_amount, fattening_type, TRUE)
		return

	if(preferences.helplessness_no_movement)
		gain_amount = clamp(gain_amount, max(3500, preferences.helplessness_no_movement), 6000)
		fatty.adjust_fatness(gain_amount, fattening_type, TRUE)

/obj/machinery/power/supermatter_crystal/superfatter_crystal/Bumped(atom/movable/AM)
	if(isliving(AM))
		AM.visible_message("<span class='danger'>\The [AM] slams into \the [src] inducing a resonance... [AM.p_their()] body starts to wobble and swell before being engulfed by a mountain of fat!</span>",\
		"<span class='userdanger'>You slam into \the [src] as your body starts expanding. Before long, you find yourself sitting next to the crystal, unable to move...</span>",\
		"<span class='hear'>You hear a strange, soft noise and feel as if your belt became a little tight.</span>")
	// else if(isobj(AM) && !iseffect(AM)) // items fattening? :clueless:
	// 	AM.visible_message("<span class='danger'>\The [AM] smacks into \the [src] and becomes rapidly engulfed in fat.</span>", null,\
	// 	"<span class='hear'>You hear a strange, soft noise and feel as if your belt became a little tight.</span>")
	else
		return

	playsound(get_turf(src), 'sound/effects/supermatter.ogg', 50, TRUE)
	if(istype(nom, mob/living/carbon/human))
		fatten_mob(nom)

/obj/machinery/power/supermatter_crystal/superfatter_crystal/process_atmos()
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

	if(!removed || !removed.total_moles() || (isspaceturf(T) && !isshuttleturf(T))) //we're in space or there is no gas to process
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


	var/h2obonus = 1 - (gas_comp[GAS_H2O] * 0.25)//At min this value should be 0.75

	//We're concerned about pluoxium being too easy to abuse at low percents, so we make sure it's at least 15% of the mix
	if(gas_comp[GAS_PLUOXIUM] < 0.15)
		threshold_mod[GAS_PLUOXIUM] = 0

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
	if (combined_gas > POWERLOSS_INHIBITION_MOLE_THRESHOLD && abs(powerloss_inhibition_gas) > POWERLOSS_INHIBITION_GAS_THRESHOLD) //If there are more then 20 mols, and more then 20% co2
		powerloss_dynamic_scaling = clamp(powerloss_dynamic_scaling + clamp(powerloss_inhibition_gas - powerloss_dynamic_scaling, -0.02, 0.02), -1, 1)
	else
		powerloss_dynamic_scaling = clamp(powerloss_dynamic_scaling - 0.05, 0, 1)
	//Ranges from 0 to 1 (1-(value between 0 and 1 * ranges from 1 to 1.5(mol / 500)))
	//0 means full inhibition, 1 means no inhibition
	//We take the mol count, and scale it to be our inhibitor
	powerloss_inhibitor = clamp(1-(powerloss_dynamic_scaling * clamp(combined_gas/POWERLOSS_INHIBITION_MOLE_BOOST_THRESHOLD, 1, 1.5)), 0, 2)

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

	if(prob(10))
		//(1 + (tritRad + pluoxDampen * bzDampen * o2Rad * plasmaRad / (10 - bzrads))) * freonbonus
		var/rad_power = power * max(0, (1 + (power_transmission_bonus/(10-radioactivity_modifier)))) / 10
		radiation_pulse(src, rad_power)//freonbonus))// RadModBZ(500%)
	if(radioactivity_modifier >= 2 && prob(6 * radioactivity_modifier))
		src.fire_nuclear_particle()

	//Power * 0.55 * a value between 1 and 0.8
	var/device_energy = power * REACTION_POWER_MODIFIER

	//Calculate how much gas to release
	//Varies based on power and gas content
	removed.adjust_moles(GAS_FAT, max((device_energy * dynamic_heat_modifier) / PLASMA_RELEASE_MODIFIER, 0))
	//Varies based on power, gas content, and heat
	removed.adjust_moles(GAS_O2, max((device_energy * dynamic_heat_modifier + effective_temperature - T20C) / OXYGEN_RELEASE_MODIFIER, 0))

	var/heat_released = device_energy * dynamic_heat_modifier
	// if (power > 4500)
	// 	heat_released = heat_released * sqrt(removed.total_moles()) * THERMAL_RELEASE_MODIFIER//**2 // OH LAWD HE COMIN
	// if (power <= 4500 && power > 2000)
	// 	heat_released = heat_released * sqrt(removed.total_moles()) * THERMAL_RELEASE_MODIFIER // big boy
	// if (power <= 2000 && power > 1000)
	// 	heat_released = heat_released * THERMAL_RELEASE_MODIFIER // normal mode
	// if (power <= 1000)
	// 	heat_released = heat_released // easy mode, since the crystal is effectively off
	removed.adjust_heat(heat_released)
	removed.set_temperature(max(0, min(removed.return_temperature(), 2500 * dynamic_heat_modifier)))

	if(produces_gas)
		env.merge(removed)
		air_update_turf()

	/*********
	END CITADEL CHANGES
	*********/

	//Makes em go mad and accumulate rads.
	// for(var/mob/living/carbon/human/l in fov_viewers(src, HALLUCINATION_RANGE(power))) // If they can see it without mesons on.  Bad on them.
	// 	if(!istype(l.glasses, /obj/item/clothing/glasses/meson))
	// 		var/D = sqrt(1 / max(1, get_dist(l, src)))
	// 		if(!l.hallucination)
	// 			to_chat(l, "<span class='warning'>Looking at the supermatter unprotected gives you a headache...</span>")
	// 		l.hallucination += power * hallucination_power * D
	// 		l.hallucination = clamp(l.hallucination, 0, 200)

	for(var/mob/living/carbon/human/person in range(src, HALLUCINATION_RANGE(power)))
		var/rads = (power / 10) * sqrt( 1 / max(get_dist(person, src),1) )
		// l.rad_act(rads)
		if(!rads || (rads < RAD_MOB_SKIN_PROTECTION) || HAS_TRAIT(src, TRAIT_RADIMMUNE))
			return

		rads -= RAD_BACKGROUND_RADIATION // This will always be at least 1 because of how skin protection is calculated

		var/blocked = (100 - person.getarmor(null, RAD)) / 100

		// apply_effect((rads*RAD_MOB_COEFFICIENT)/max(1, (radiation**2)*RAD_OVERDOSE_REDUCTION), EFFECT_IRRADIATE, blocked)
		var/fat_gained = (rads * RAD_MOB_COEFFICIENT) * blocked
		person.adjust_fatness(fat_gained, FATTENING_TYPE_RADIATIONS)

	//Transitions between one function and another, one we use for the fast inital startup, the other is used to prevent errors with fusion temperatures.
	//Use of the second function improves the power gain imparted by using co2
	if(power_changes)
		power = max(power - min(((power/500)**3) * powerloss_inhibitor, power * 0.83 * powerloss_inhibitor) - 1, 0)
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

#undef HALLUCINATION_RANGE
#undef GRAVITATIONAL_ANOMALY
#undef FLUX_ANOMALY
#undef PYRO_ANOMALY
