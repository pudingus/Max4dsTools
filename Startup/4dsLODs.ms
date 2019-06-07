plugin modifier MafLOD
name:"4DS LOD"
classID:#(0x25688ade, 0x191139f7)
(
	fn filt obj = superclassof obj == GeometryClass

	parameters main rollout:params
	(
		lodNum type:#integer default:2 ui:ui_lodNum
		lodDist type:#float default:4 ui:ui_lodDist
		lodMesh type:#node ui:ui_lodMesh
	)
	rollout params "4DS LOD Params"
	(
		spinner ui_lodNum "LOD num" align:#right fieldwidth:48  type:#integer
		spinner ui_lodDist "LOD distance" align:#right fieldwidth:48 range:[0,9999,10] scale:1
		pickbutton ui_lodMesh "LOD mesh" align:#center fieldwidth:48 filter:filt
		on ui_lodMesh picked obj do
		(
			ui_lodMesh.text = obj.name
			--layermanager.newlayerfromname ("4DS_LOD"+(lodNum as string))
			--newlayer = layermanager.getlayerfromname ("4DS_LOD"+(lodNum as string))
			--newlayer.isHidden = true
			--newlayer.addNode obj
		)
		on params open do
		(
			if lodMesh != undefined then ui_lodMesh.text = lodMesh.name
		)
	)
)