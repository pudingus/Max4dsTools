plugin modifier MafObject4
name:"4DS Base Object v4"
classID:#(0x61e87622, 0x3623b669)
(
	parameters main rollout:params
	(
		renderFlags type:#integer ui:ui_cullFlags
		cullFlags type:#integer ui:ui_cullFlags
		userParams type:#string default:"" ui:ui_userParams
	)
	rollout params "4DS Base Object"
	(
		spinner ui_renderFlags "renderFlags:" range:[0,65535,0]  type:#integer
		spinner ui_cullFlags "cullFlags:" range:[0,255,0]  type:#integer
		edittext ui_userParams "params:"
	)
)