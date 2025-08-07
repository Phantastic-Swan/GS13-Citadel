/obj/item/melee/baton/stunsword/fattening
	name = "fattening stunsword"
	desc = "functions the same as it's standard counterpart, but fattens targets when used aggressively."
	force = 20
	damtype = FAT

/obj/item/melee/baton/fattening
	name = "fattening stunbaton"
	desc = "functions the same as it's standard counterpart, but fattens targets when used aggressively."
	force = 20
	damtype = FAT

/obj/item/melee/baton/fattening/update_icon_state()
	if(turned_on)
		icon_state = "stunbaton_active"
	else if(!cell)
		icon_state = "stunbaton_nocell"
	else
		icon_state = "stunbaton"

/obj/item/melee/baton/stunsword/fattening/update_icon_state()
	if(turned_on)
		icon_state = "stunsword_active"
	else if(!cell)
		icon_state = "stunsword_nocell"
	else
		icon_state = "stunsword"
