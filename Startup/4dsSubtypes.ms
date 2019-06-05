plugin modifier MafSubtype
name:"4DS Subtype"
classID:#(0x5e873b7d, 0x41b38bb7)
(
	parameters main rollout:params
	(
		subtypeName type:#string default:"" ui:ui_subtypeName
		nearRange type:#float ui:ui_nearRange
		farRange type:#float ui:ui_farRange

		cullFlags type:#integer ui:ui_cullFlags
		userParams type:#string ui:ui_userParams
	)
	rollout params "4DS Subtype"
	(
		edittext ui_subtypeName "Subtype:"
		spinner ui_nearRange "nearRange:" range:[-1000,1000,10]
		spinner ui_farRange "farRange:" range:[-1000,1000,10]
		spinner ui_cullFlags "cullFlags:" range:[-10000,10000,10]  type:#integer
		edittext ui_userParams "userParams:"
	--	on params open do
	--	(
	--		ui_subtypeName.text = subtypeName
	--	)
	)
)