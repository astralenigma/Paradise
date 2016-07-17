/mob/living/carbon/human/proc/change_appearance(var/flags = APPEARANCE_ALL_HAIR, var/location = src, var/mob/user = src, var/check_species_whitelist = 1, var/list/species_whitelist = list(), var/list/species_blacklist = list(), var/datum/topic_state/state = default_state)
	var/datum/nano_module/appearance_changer/AC = new(location, src, check_species_whitelist, species_whitelist, species_blacklist)
	AC.flags = flags
	AC.ui_interact(user, state = state)

/mob/living/carbon/human/proc/change_species(var/new_species)
	if(!new_species || species == new_species || !(new_species in all_species))
		return

	set_species(new_species)
	reset_hair()
	return 1

/mob/living/carbon/human/proc/change_gender(var/gender, var/update_dna = 1)
	var/obj/item/organ/external/head/H = organs_by_name["head"]
	if(src.gender == gender)
		return

	src.gender = gender

	var/datum/sprite_accessory/hair/current_hair = hair_styles_list[H.h_style]
	if(current_hair.gender != NEUTER && current_hair.gender != src.gender)
		reset_head_hair()

	var/datum/sprite_accessory/hair/current_fhair = facial_hair_styles_list[H.f_style]
	if(current_fhair.gender != NEUTER && current_fhair.gender != src.gender)
		reset_facial_hair()

	if(update_dna)
		update_dna()
	sync_organ_dna(assimilate = 0)
	update_body()
	return 1

/mob/living/carbon/human/proc/change_hair(var/hair_style)
	var/obj/item/organ/external/head/H = get_organ("head")
	if(!hair_style || H.h_style == hair_style || !(hair_style in hair_styles_list))
		return

	H.h_style = hair_style

	update_hair()
	return 1

/mob/living/carbon/human/proc/change_facial_hair(var/facial_hair_style)
	var/obj/item/organ/external/head/H = get_organ("head")
	if(!facial_hair_style || H.f_style == facial_hair_style || !(facial_hair_style in facial_hair_styles_list))
		return

	H.f_style = facial_hair_style

	update_fhair()
	return 1

/mob/living/carbon/human/proc/change_head_accessory(var/head_accessory_style)
	var/obj/item/organ/external/head/H = get_organ("head")
	if(!head_accessory_style || H.ha_style == head_accessory_style || !(head_accessory_style in head_accessory_styles_list))
		return

	H.ha_style = head_accessory_style

	update_head_accessory()
	return 1

/mob/living/carbon/human/proc/change_markings(var/marking_style, var/location = "body")
	var/list/marking_styles = params2list(m_styles)
	if(!marking_style || marking_styles[location] == marking_style || !(marking_style in marking_styles_list))
		return

	var/datum/sprite_accessory/body_markings/marking = marking_styles_list[marking_style]
	if(marking.name != "None" && marking.marking_location != location)
		return

	var/obj/item/organ/external/head/head_organ = get_organ("head")
	if(location == "head" && head_organ.alt_head && head_organ.alt_head != "None")
		var/datum/sprite_accessory/body_markings/head/H = marking_styles_list[marking_style]
		if(marking.name != "None" && (!H.heads_allowed || !(head_organ.alt_head in H.heads_allowed)))
			return

	marking_styles[location] = marking_style
	m_styles = list2params(marking_styles)

	if(location == "tail")
		stop_tail_wagging()
	else
		update_markings()
	return 1

/mob/living/carbon/human/proc/change_body_accessory(var/body_accessory_style)
	var/found
	if(!body_accessory_style || (src.body_accessory && src.body_accessory.name == body_accessory_style))
		return

	for(var/B in body_accessory_by_name)
		if(B == body_accessory_style)
			src.body_accessory = body_accessory_by_name[body_accessory_style]
			found = 1

	if(!found)
		return

	var/list/marking_styles = params2list(m_styles)
	marking_styles["tail"] = "None"
	m_styles = list2params(marking_styles)
	update_tail_layer()
	return 1

/mob/living/carbon/human/proc/change_alt_head(var/alternate_head)
	var/obj/item/organ/external/head/H = get_organ("head")
	if(H.alt_head == alternate_head || (H.status & ORGAN_ROBOT) || !(species.bodyflags & HAS_ALT_HEADS) || !(alternate_head in alt_heads_list))
		return

	H.alt_head = alternate_head

	//Handle head markings if they're incompatible with the new alt head.
	var/list/marking_styles = params2list(m_styles)
	if(marking_styles["head"])
		var/head_marking = marking_styles["head"]
		var/datum/sprite_accessory/body_markings/head/head_marking_style = marking_styles_list[head_marking]
		if(!head_marking_style.heads_allowed || !(H.alt_head in head_marking_style.heads_allowed))
			marking_styles["head"] = "None"
			m_styles = list2params(marking_styles)
			update_markings()

	update_body(1, 1) //Update the body and force limb icon regeneration to update the head with the new icon.
	return 1

/mob/living/carbon/human/proc/reset_hair()
	reset_head_hair()
	reset_facial_hair()
	reset_head_accessory()
	var/list/marking_styles = params2list(m_styles)
	if(marking_styles["head"] && marking_styles["head"] != "None") //Resets head markings.
		reset_markings()

/mob/living/carbon/human/proc/reset_head_hair()
	var/obj/item/organ/external/head/H = get_organ("head")
	var/list/valid_hairstyles = generate_valid_hairstyles()
	if(valid_hairstyles.len)
		H.h_style = pick(valid_hairstyles)
	else
		//this shouldn't happen
		H.h_style = "Bald"

	update_hair()

/mob/living/carbon/human/proc/reset_facial_hair()
	var/obj/item/organ/external/head/H = get_organ("head")
	var/list/valid_facial_hairstyles = generate_valid_facial_hairstyles()
	if(valid_facial_hairstyles.len)
		H.f_style = pick(valid_facial_hairstyles)
	else
		//this shouldn't happen
		H.f_style = "Shaved"
	update_fhair()

/mob/living/carbon/human/proc/reset_markings(var/location)
	var/list/valid_markings
	var/list/marking_styles = params2list(m_styles)

	if(location)
		valid_markings = generate_valid_markings(location)
		if(valid_markings.len)
			marking_styles[location] = pick(valid_markings)
		else
			//this shouldn't happen
			marking_styles[location] = "None"
	else
		for(var/m_location in list("head", "body", "tail"))
			valid_markings = generate_valid_markings(m_location)
			if(valid_markings.len)
				marking_styles[m_location] = pick(valid_markings)
			else
				//this shouldn't happen
				marking_styles[m_location] = "None"

	m_styles = list2params(marking_styles)

	update_markings()
	stop_tail_wagging()

/mob/living/carbon/human/proc/reset_head_accessory()
	var/obj/item/organ/external/head/H = get_organ("head")
	var/list/valid_head_accessories = generate_valid_head_accessories()
	if(valid_head_accessories.len)
		H.ha_style = pick(valid_head_accessories)
	else
		//this shouldn't happen
		H.ha_style = "None"
	update_head_accessory()

/mob/living/carbon/human/proc/change_eye_color(var/red, var/green, var/blue)
	if(red == r_eyes && green == g_eyes && blue == b_eyes)
		return

	r_eyes = red
	g_eyes = green
	b_eyes = blue

	update_eyes()
	update_body()
	return 1

/mob/living/carbon/human/proc/change_hair_color(var/red, var/green, var/blue)
	var/obj/item/organ/external/head/H = get_organ("head")
	if(red == H.r_hair && green == H.g_hair && blue == H.b_hair)
		return

	H.r_hair = red
	H.g_hair = green
	H.b_hair = blue

	update_hair()
	return 1

/mob/living/carbon/human/proc/change_facial_hair_color(var/red, var/green, var/blue)
	var/obj/item/organ/external/head/H = get_organ("head")
	if(red == H.r_facial && green == H.g_facial && blue == H.b_facial)
		return

	H.r_facial = red
	H.g_facial = green
	H.b_facial = blue

	update_fhair()
	return 1

/mob/living/carbon/human/proc/change_head_accessory_color(var/red, var/green, var/blue)
	var/obj/item/organ/external/head/H = get_organ("head")
	if(red == H.r_headacc && green == H.g_headacc && blue == H.b_headacc)
		return

	H.r_headacc = red
	H.g_headacc = green
	H.b_headacc = blue

	update_head_accessory()
	return 1

/mob/living/carbon/human/proc/change_marking_color(var/colour, var/location = "body")
	var/list/marking_colours = params2list(m_colours)
	marking_colours[location] = sanitize_hexcolor(marking_colours[location])
	if(colour == marking_colours[location])
		return

	marking_colours[location] = colour
	m_colours = list2params(marking_colours)

	if(location == "tail")
		update_tail_layer()
	else
		update_markings()
	return 1


/mob/living/carbon/human/proc/change_skin_color(var/red, var/green, var/blue)
	if(red == r_skin && green == g_skin && blue == b_skin || !(species.bodyflags & HAS_SKIN_COLOR))
		return

	r_skin = red
	g_skin = green
	b_skin = blue

	force_update_limbs()
	update_body()
	return 1

/mob/living/carbon/human/proc/change_skin_tone(var/tone)
	if(s_tone == tone || !((species.bodyflags & HAS_SKIN_TONE) || (species.bodyflags & HAS_ICON_SKIN_TONE)))
		return

	s_tone = tone

	force_update_limbs()
	update_body()
	return 1

/mob/living/carbon/human/proc/update_dna()
	check_dna()
	dna.ready_dna(src)

/mob/living/carbon/human/proc/generate_valid_species(var/check_whitelist = 1, var/list/whitelist = list(), var/list/blacklist = list())
	var/list/valid_species = new()
	for(var/current_species_name in all_species)
		var/datum/species/current_species = all_species[current_species_name]

		if(check_whitelist && config.usealienwhitelist && !check_rights(R_ADMIN, 0, src)) //If we're using the whitelist, make sure to check it!
			if((whitelist.len && !(current_species_name in whitelist)) || (blacklist.len && (current_species_name in blacklist)) || ((current_species.flags & IS_WHITELISTED) && !is_alien_whitelisted(src, current_species_name)))
				continue

		valid_species += current_species_name

	return valid_species

/mob/living/carbon/human/proc/generate_valid_hairstyles()
	var/list/valid_hairstyles = new()
	var/obj/item/organ/external/head/H = get_organ("head")
	for(var/hairstyle in hair_styles_list)
		var/datum/sprite_accessory/S = hair_styles_list[hairstyle]

		if((gender == MALE && S.gender == FEMALE) || (gender == FEMALE && S.gender == MALE))
			continue
		if(H.species.flags & ALL_RPARTS) //If the user is a species who can have a robotic head...
			var/datum/robolimb/robohead = all_robolimbs[H.model]
			if(!H)
				return
			if(H.species.name in S.species_allowed) //If this is a hairstyle native to the user's species...
				if(robohead.is_monitor && (robohead.company in S.models_allowed)) //Check to see if they have a head with an ipc-style screen and that the head's company is in the screen style's allowed models list.
					valid_hairstyles += hairstyle //Give them their hairstyles if they do.
					continue
				else //If they don't have the default head, they shouldn't be getting any hairstyles they wouldn't normally.
					continue
			else
				if(robohead.is_monitor) //If the hair style is not native to the user's species and they're using a head with an ipc-style screen, don't let them access it.
					continue
				else
					if("Human" in S.species_allowed) //If the user has a robotic head and the hairstyle can fit humans, let them use it as a wig for their humanoid robot head.
						valid_hairstyles += hairstyle
					continue
		else //If the user is not a species who can have robotic heads, use the default handling.
			if(!(H.species.name in S.species_allowed)) //If the user's head is not of a species the hair style allows, skip it. Otherwise, add it to the list.
				continue
			valid_hairstyles += hairstyle

	return valid_hairstyles

/mob/living/carbon/human/proc/generate_valid_facial_hairstyles()
	var/list/valid_facial_hairstyles = new()
	var/obj/item/organ/external/head/H = get_organ("head")
	for(var/facialhairstyle in facial_hair_styles_list)
		var/datum/sprite_accessory/S = facial_hair_styles_list[facialhairstyle]

		if((gender == MALE && S.gender == FEMALE) || (gender == FEMALE && S.gender == MALE))
			continue
		if(H.species.flags & ALL_RPARTS) //If the user is a species who can have a robotic head...
			var/datum/robolimb/robohead = all_robolimbs[H.model]
			if(!H)
				continue // No head, no hair
			if(H.species.name in S.species_allowed) //If this is a facial hair style native to the user's species...
				if(robohead.is_monitor && (robohead.company in S.models_allowed)) //Check to see if they have a head with an ipc-style screen and that the head's company is in the screen style's allowed models list.
					valid_facial_hairstyles += facialhairstyle //Give them their facial hair styles if they do.
					continue
				else //If they don't have the default head, they shouldn't be getting any facial hair styles they wouldn't normally.
					continue
			else

				if(robohead.is_monitor) //If the facial hair style is not native to the user's species and they're using a head with an ipc-style screen, don't let them access it.
					continue
				else
					if("Human" in S.species_allowed) //If the user has a robotic head and the facial hair style can fit humans, let them use it as a postiche for their humanoid robot head.
						valid_facial_hairstyles += facialhairstyle
					continue
		else //If the user is not a species who can have robotic heads, use the default handling.
			if(!(H.species.name in S.species_allowed)) //If the user's head is not of a species the facial hair style allows, skip it. Otherwise, add it to the list.
				continue
			valid_facial_hairstyles += facialhairstyle

	return valid_facial_hairstyles

/mob/living/carbon/human/proc/generate_valid_head_accessories()
	var/list/valid_head_accessories = new()
	var/obj/item/organ/external/head/H = get_organ("head")
	for(var/head_accessory in head_accessory_styles_list)
		var/datum/sprite_accessory/S = head_accessory_styles_list[head_accessory]

		if(!(H.species.name in S.species_allowed)) //If the user's head is not of a species the head accessory style allows, skip it. Otherwise, add it to the list.
			continue
		valid_head_accessories += head_accessory

	return valid_head_accessories

/mob/living/carbon/human/proc/generate_valid_markings(var/location = "body")
	var/list/valid_markings = new()
	var/obj/item/organ/external/head/H = get_organ("head")
	for(var/marking in marking_styles_list)
		var/datum/sprite_accessory/body_markings/S = marking_styles_list[marking]
		if(S.name == "None")
			valid_markings += marking
			continue
		if(S.marking_location != location) //If the marking isn't for the location we desire, skip.
			continue
		if(!(species.name in S.species_allowed)) //If the user's head is not of a species the marking style allows, skip it. Otherwise, add it to the list.
			continue
		if(location == "tail")
			if(!body_accessory)
				if(S.tails_allowed)
					continue
			else
				if(!S.tails_allowed || !(body_accessory in S.tails_allowed))
					continue
		if(location == "head")
			var/datum/sprite_accessory/body_markings/head/M = marking_styles_list[S.name]
			if(H.species.flags & ALL_RPARTS)//If the user is a species that can have a robotic head...
				var/datum/robolimb/robohead = all_robolimbs[H.model]
				if(!(S.models_allowed && (robohead.company in S.models_allowed))) //Make sure they don't get markings incompatible with their head.
					continue
			else if(H.alt_head && H.alt_head != "None") //If the user's got an alt head, validate markings for that head.
				if(!(H.alt_head in M.heads_allowed))
					continue
			else
				if(M.heads_allowed)
					continue
		valid_markings += marking

	return valid_markings

/mob/living/carbon/human/proc/generate_valid_body_accessories()
	var/list/valid_body_accessories = new()
	for(var/B in body_accessory_by_name)
		var/datum/body_accessory/A = body_accessory_by_name[B]
		if(check_rights(R_ADMIN, 1, src))
			valid_body_accessories = body_accessory_by_name.Copy()
		else
			if(!istype(A))
				valid_body_accessories += "None" //The only null entry should be the "None" option.
				continue
			if(!(species.name in A.allowed_species)) //If the user is not of a species the body accessory style allows, skip it. Otherwise, add it to the list.
				continue
			valid_body_accessories += B

	return valid_body_accessories

/mob/living/carbon/human/proc/generate_valid_alt_heads()
	var/list/valid_alt_heads = list()
	valid_alt_heads["None"] = alt_heads_list["None"] //The only null entry should be the "None" option, and there should always be a "None" option.
	for(var/alternate_head in alt_heads_list)
		var/datum/sprite_accessory/alt_heads/head = alt_heads_list[alternate_head]
		if(!(species.name in head.species_allowed))
			continue

		valid_alt_heads[alternate_head] = alt_heads_list[alternate_head]

	return valid_alt_heads