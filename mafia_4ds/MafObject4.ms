plugin modifier MafObject4
name:"4DS Base Object v4"
classID:#(0x61e87622, 0x3623b669)
(
	parameters main rollout:params
	(
		subtypeName type:#string default:"" ui:ui_subtypeName
		renderFlags type:#integer ui:ui_cullFlags
		cullFlags type:#integer ui:ui_cullFlags
		userParams type:#string default:"" ui:ui_userParams
	)
	rollout params "4DS Base Object"
	(
		edittext ui_subtypeName "Subtype:"
		spinner ui_renderFlags "renderFlags:" range:[-10000,10000,0]  type:#integer
		spinner ui_cullFlags "cullFlags:" range:[-10000,10000,0]  type:#integer
		edittext ui_userParams "Params:"
	)
)