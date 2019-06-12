plugin modifier MafObject
name:"4DS Base Object"
classID:#(0x5e873b7d, 0x41b38bb7)
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