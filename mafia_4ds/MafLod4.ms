plugin modifier MafLod4
name:"4DS LOD v4"
classID:#(0x6b1c55fc, 0xdfe4a7)
(
	parameters main rollout:params
	(
		lodDist type:#float default:4 ui:lodDist
		dontOptimize type:#boolean default:false ui:dontOptimize
	)
	rollout params "4DS LOD Params"
	(
		spinner lodDist "LOD distance" align:#right fieldwidth:48 range:[0,9999,10] scale:1		
		group "Exporter:" (
			checkbox dontOptimize "Don't optimize vertices"
		)
	)
)