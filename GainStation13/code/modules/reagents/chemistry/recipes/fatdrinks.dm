//GS13 drink recipes

/datum/chemical_reaction/belly_bloats
	name = "Belly Bloats"
	id = /datum/reagent/consumable/ethanol/belly_bloats
	results = list(/datum/reagent/consumable/ethanol/belly_bloats = 2)
	required_reagents = list(/datum/reagent/consumable/gibbfloats = 1, /datum/reagent/consumable/ethanol/beer = 1)

/datum/chemical_reaction/blobby_mary
	name = "Blobby Mary"
	id = /datum/reagent/consumable/ethanol/blobby_mary
	results = list(/datum/reagent/consumable/ethanol/blobby_mary = 3)
	required_reagents = list(/datum/reagent/consumable/tomatojuice = 1, /datum/reagent/consumable/ethanol/vodka = 1, /datum/reagent/consumable/lipoifier = 1)

/datum/chemical_reaction/beltbuster_mead
	name = "Beltbuster Mead"
	id = /datum/reagent/consumable/ethanol/beltbuster_mead
	results = list(/datum/reagent/consumable/ethanol/beltbuster_mead = 4)
	required_reagents = list(/datum/reagent/consumable/ethanol/mead = 1, /datum/reagent/consumable/ethanol = 1, /datum/reagent/consumable/cream = 1, /datum/reagent/consumable/lipoifier = 1)

/datum/chemical_reaction/heavy_cafe1
	name = "Heavy Cafe"
	id = /datum/reagent/consumable/heavy_cafe
	results = list(/datum/reagent/consumable/heavy_cafe = 3)
	required_reagents = list(/datum/reagent/consumable/cafe_latte = 1, /datum/reagent/consumable/sugar = 1, /datum/reagent/consumable/cream = 1)

/datum/chemical_reaction/heavy_cafe2
	name = "Heavy Cafe"
	id = /datum/reagent/consumable/heavy_cafe
	results = list(/datum/reagent/consumable/heavy_cafe = 3)
	required_reagents = list(/datum/reagent/consumable/soy_latte = 1, /datum/reagent/consumable/sugar = 1, /datum/reagent/consumable/cream = 1)

/datum/chemical_reaction/fruits_tea
	name = "Fruits Tea"
	id = /datum/reagent/consumable/fruits_tea
	results = list(/datum/reagent/consumable/fruits_tea = 3)
	required_reagents = list(/datum/reagent/consumable/berryjuice = 1, /datum/reagent/consumable/lemonjuice = 1, /datum/reagent/consumable/tea = 1)

/datum/chemical_reaction/snakebite
	name = "Snakebite"
	id = /datum/reagent/consumable/snakebite
	results = list(/datum/reagent/consumable/snakebite = 3)
	required_reagents = list(/datum/reagent/toxin = 1, /datum/reagent/consumable/limejuice = 1, /datum/reagent/consumable/lipoifier = 1)

/datum/chemical_reaction/milkshake_vanilla
	name = "Vanilla Milkshake"
	id = /datum/reagent/consumable/milkshake_vanilla
	results = list(/datum/reagent/consumable/milkshake_vanilla = 3)
	required_reagents = list(/datum/reagent/consumable/milk = 1, /datum/reagent/consumable/cream = 1, /datum/reagent/consumable/vanilla = 1)

/datum/chemical_reaction/milkshake_chocolate
	name = "Chocolate Milkshake"
	id = /datum/reagent/consumable/milkshake_chocolate
	results = list(/datum/reagent/consumable/milkshake_chocolate = 3)
	required_reagents = list(/datum/reagent/consumable/milk/chocolate_milk = 1, /datum/reagent/consumable/cream = 1, /datum/reagent/consumable/coco = 1)

/datum/chemical_reaction/heavy_cafe1
	name = "Heavy Cafe"
	id = /datum/reagent/consumable/heavy_cafe
	results = list(/datum/reagent/consumable/heavy_cafe = 3)
	required_reagents = list(/datum/reagent/consumable/cafe_latte = 1, /datum/reagent/consumable/sugar = 1, /datum/reagent/consumable/cream = 1)

/datum/chemical_reaction/oreo_classic
	name = "Heavy Cafe"
	id = /datum/reagent/consumable/oreo_classic
	results = list(/datum/reagent/consumable/oreo_classic = 3)
	required_reagents = list(/datum/reagent/consumable/flour = 2, /datum/reagent/consumable/sugar = 2, /datum/reagent/consumable/coco = 1)

/datum/chemical_reaction/oreo_milky
	name = "Heavy Cafe"
	id = /datum/reagent/consumable/oreo_milky
	results = list(/datum/reagent/consumable/oreo_milky = 3)
	required_reagents = list(/datum/reagent/consumable/flour = 2, /datum/reagent/consumable/sugar = 2, /datum/reagent/consumable/milk = 1)

/obj/item/reagent_containers/food/snacks/store/cake/hugeoreo
	name = "GlucoBomb Oreo Cookieshake"
	desc = "Are you out of your fucking mind?"
	icon = 'GainStation13/icons/obj/food/food64x64.dmi'
	icon_state = "oreo_huge"
	pixel_x = -16
	pixel_y = -16
	inhand_x_dimension = 64
	inhand_y_dimension = 64
	bonus_reagents = list(/datum/reagent/consumable/nutriment = 20, /datum/reagent/consumable/sugar = 20)
	list_reagents = list(/datum/reagent/consumable/nutriment = 200, /datum/reagent/consumable/sugar = 100, /datum/reagent/consumable/milk = 50)
	tastes = list("sugar" = 1, "sugar shock" = 1, "syrup" = 1, "slop" = 1, "overwhelming surge of calories" = 10)
	foodtype = DAIRY| JUNKFOOD

/datum/crafting_recipe/food/hugeoreo
	name = "GlucoBomb Oreo Cookieshake"
	reqs = list(
		/obj/item/reagent_containers/food/snacks/store/cake/cheese = 2,
		/datum/reagent/consumable/sugar = 100,
		/datum/reagent/consumable/milk = 100,
		/datum/reagent/consumable/cream = 50
	)
	result = /obj/item/reagent_containers/food/snacks/hugeoreo
	subcategory = CAT_CAKE
