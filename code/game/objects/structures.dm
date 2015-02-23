/obj/structure
	icon = 'icons/obj/structures.dmi'
	var/climbable

/obj/structure/blob_act()
	if(prob(50))
		del(src)

/obj/structure/ex_act(severity)
	switch(severity)
		if(1.0)
			qdel(src)
			return
		if(2.0)
			if(prob(50))
				qdel(src)
				return
		if(3.0)
			return

/obj/structure/meteorhit(obj/O as obj)
	del(src)


/obj/structure/Destroy()
	if(hascall(src, "unbuckle"))
		src:unbuckle()
	..()

/obj/structure/mech_melee_attack(obj/mecha/M)
	if(M.damtype == "brute")
		M.occupant_message("<span class='danger'>You hit [src].</span>")
		visible_message("<span class='danger'>[src] has been hit by [M.name].</span>")
		return 1
	return 0

/obj/structure/New()
	..()
	if(climbable)
		verbs += /obj/structure/proc/climb_on

/obj/structure/proc/climb_on()

	set name = "Climb structure"
	set desc = "Climbs onto a structure."
	set category = null
	set src in oview(1)

	do_climb(usr)

/obj/structure/MouseDrop_T(var/atom/movable/C, mob/user as mob)
	if(C == user)
		do_climb(user)


/obj/structure/proc/do_climb(var/mob/living/user)

	if (!can_touch(user) || !climbable)
		return

	for(var/obj/O in range(0, src))
		if(O.density == 1 && O != src && !istype(O, /obj/machinery/door/window)) //Ignores windoors, as those already block climbing, otherwise a windoor on the opposite side of a table would prevent climbing.
			user << "\red You cannot climb [src], as it is blocked by \a [O]!"
			return
	for(var/turf/T in range(0, src))
		if(T.density == 1)
			user << "\red You cannot climb [src], as it is blocked by \a [T]!"
			return
	var/turf/T = src.loc
	if(!T || !istype(T)) return

	var/obj/machinery/door/poddoor/shutters/S = locate() in T.contents
	if(S && S.density) return

	usr.visible_message("<span class='warning'>[user] starts climbing onto \the [src]!</span>")

	if(!do_after(user,50))
		return

	if (!can_touch(user) || !climbable)
		return

	S = locate() in T.contents
	if(S && S.density) return

	usr.loc = get_turf(src)
	if (get_turf(user) == get_turf(src))
		usr.visible_message("<span class='warning'>[user] climbs onto \the [src]!</span>")

/obj/structure/proc/structure_shaken()

	for(var/mob/living/M in get_turf(src))

		if(M.lying) return //No spamming this on people.

		M.Weaken(5)
		M << "\red You topple as \the [src] moves under you!"

		if(prob(25))

			var/damage = rand(15,30)
			var/mob/living/carbon/human/H = M
			if(!istype(H))
				H << "\red You land heavily!"
				M.adjustBruteLoss(damage)
				return

			var/datum/organ/external/affecting

			switch(pick(list("ankle","wrist","head","knee","elbow")))
				if("ankle")
					affecting = H.get_organ(pick("l_foot", "r_foot"))
				if("knee")
					affecting = H.get_organ(pick("l_leg", "r_leg"))
				if("wrist")
					affecting = H.get_organ(pick("l_hand", "r_hand"))
				if("elbow")
					affecting = H.get_organ(pick("l_arm", "r_arm"))
				if("head")
					affecting = H.get_organ("head")

			if(affecting)
				M << "\red You land heavily on your [affecting.display_name]!"
				affecting.take_damage(damage, 0)
				if(affecting.parent)
					affecting.parent.add_autopsy_data("Misadventure", damage)
			else
				H << "\red You land heavily!"
				H.adjustBruteLoss(damage)

			H.UpdateDamageIcon()
			H.updatehealth()
	return

/obj/structure/proc/can_touch(var/mob/user)
	if (!user)
		return 0
	if(!Adjacent(user))
		return 0
	if (user.restrained() || user.buckled)
		user << "<span class='notice'>You need your hands and legs free for this.</span>"
		return 0
	if (user.stat || user.paralysis || user.sleeping || user.lying || user.weakened)
		return 0
	if (issilicon(user))
		user << "<span class='notice'>You need hands for this.</span>"
		return 0
	return 1

