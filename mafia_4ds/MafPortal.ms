plugin modifier MafPortal
name:"4DS Sector Portal"
classID:#(0x5f873c8d, 0x4fb38eb7)
(
	parameters main rollout:params
	(
		nearRange type:#float ui:ui_nearRange
		farRange type:#float ui:ui_farRange
	)
	rollout params "4DS Sector Portal"
	(
		spinner ui_nearRange "nearRange:" range:[-900000,900000,0]
		spinner ui_farRange "farRange:" range:[-900000,900000,0]
	)
)