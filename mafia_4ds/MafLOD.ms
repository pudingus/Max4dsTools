plugin modifier MafLOD
name:"4DS LOD"
classID:#(0x25688ade, 0x191139f7)
(
	parameters main rollout:params
	(
		lodDist type:#float default:4 ui:ui_lodDist
	)
	rollout params "4DS LOD Params"
	(
		spinner ui_lodDist "LOD distance" align:#right fieldwidth:48 range:[0,9999,10] scale:1
	)
)