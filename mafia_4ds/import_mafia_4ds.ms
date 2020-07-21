(
	
include "layers.ms"
include "types.ms"

local mnodes
local godmat
local filename


local n_mesh_array = #()
local n_normal_array = #()

--returns array of nodes
fn CreateMesh mmesh mobj = (
	local nodes = #()
	
	if mmesh.instanceId != 0 then (
		nodes[1] = instance mnodes[mmesh.instanceId]
	)
	else (
		if mmesh.lods.count == 0 then (
			nodes[1] = Editable_mesh()
		)
		else (
			local lodId = 0
			for mlod in mmesh.lods do (	
				local lodNode = mesh mesh:mlod.mesh
				lodNode.wirecolor = color 0 0 0
				
				for j = 1 to lodNode.numFaces do (
					local matId = mlod.matIds[j]
					if matId == 0 then matId = godmat.numsubs
					setFaceMatID lodNode j matId
				)				
				
				if lodId > 0 then (  --todo: move to CreateObjects
					lodNode.name = "$lod" + (lodId as string) + "__" + mobj.name
					lodNode.parent = nodes[1]
				)

				if mmesh.lods.count > 1 then Layers.AddTo lodNode ("Lod"+(lodId as string))

				custAttributes.add lodNode MafParams_def baseObject:false 
				local gp = custAttributes.get lodNode mafParams_def baseObject:false

				gp.objectType = "Lod"
				gp.lodDist = mlod.distance
				gp.dontOptimize = true

				lodNode.material = godmat
				
				append nodes lodNode
				
				
				append n_mesh_array lodNode
				append n_normal_array mlod.normals
				
				lodId += 1
			)				
		)						
	)
	nodes
)


fn CreateMorph mmorph mobj mmesh nnode = (	
	local inc = -0.4
	local totalInc = inc	
	
	local baseMesh = mmesh.lods[1].mesh	
	local meshes = #()
	
	for chan in mmorph.sections do (
		local sectionMeshes = #()
				
		for i = 1 to mmorph.numTargets do (
			sectionMeshes[i] = copy baseMesh
		)
		
		for i = 1 to chan.vertices.count do (
			local vertId = chan.vertexLinks[i] + 1			
			local mvert = chan.vertices[i]
			
			for j = 1 to mvert.targets.count do (
				local target = mvert.targets[j]
				local vert = target.pos
				setVert sectionMeshes[j] vertId vert
			)
		)
		append meshes sectionMeshes	
		
	)
	
	local tmod = Morpher()
	addModifier nnode tmod
	tmod.Autoload_of_targets = 1
	
	--local sectionNames = #("mouth", "eyes", "brows")
	local sectionNames = #("A", "B", "C")
	local layerNames = #("layer A", "layer B", "layer C")
	
	local sectionId = 1
	local marker = 1
	
	for sectMesh in meshes do (
		local sectionName = sectionNames[sectionId]
		WM3_CreateMarker tmod marker layerNames[sectionId]
		
		local targetId = 1
		
		for targetMesh in sectMesh do (
			local tnode = mesh mesh:targetMesh
			tnode.material = godmat			
			local name = stringstream ""
			format "$morph %%" sectionName targetId to:name	
			tnode.name = name as string			
			tnode.transform = mobj.GetMatrix() * (transMatrix [totalInc, 0, 0])	
			tnode.parent = nnode
			
			hide tnode
			
			local finalId = (marker + targetId - 1)
			
			WM3_MC_BuildFromNode tmod finalId tnode				
			WM3_MC_SetName tmod finalId (sectionName + " " + (targetId as string))			
						
			targetId += 1			
			totalInc += inc	
		)
		marker = (sectionId * 10 + 1)
		sectionId += 1
	)
	
	WM3_SetCurrentMarker tmod 1		
)




fn CreateBillboard mbillboard nnode = (		
	custAttributes.add nnode MafParams_def baseObject:false
	local gp = custAttributes.get nnode MafParams_def baseObject:false

	gp.rotAxis = mbillboard.rotAxis + 1
	gp.rotMode = mbillboard.rotMode + 1
)




fn CreateGlow mglows mobj = (
	-- local nnode = point()
	-- nnode.constantscreensize = true
	-- nnode.box = true
	-- nnode.centermarker = true
	-- nnode.cross = false	
	
	-- local nnode = box length:0.1 width:0.1 height:0.1	
	-- nnode.wirecolor = color 248 128 0	
	
	
	local nnode = dummy()
	nnode.boxsize = [0.2, 0.2, 0.2]
	
	nnode
)





fn CreateMirror mmirror mobj = (
	nnode = mesh mesh:mmirror.mesh
)




fn CreateDummy mdummy mobj = (
	local dmin = mdummy.dmin
	local dmax = mdummy.dmax
	local nnode = dummy()
	nnode.boxsize = [(abs (dmin.x-dmax.x)), (abs (dmin.y-dmax.y)), (abs (dmin.z-dmax.z))]	
	
	hide nnode
		
	nnode
)


--returns array of nodes
fn CreateSector msector mobj = (
	local nodes	= #()
	
	nodes[1] = mesh mesh:msector.mesh
	nodes[1].wirecolor = (color 255 199 0)	
	
	local portalId = 0
	for mportal in msector.portals do (
		local numverts = mportal.verts.count
		local portalNode = mesh numverts:numVerts
		portalNode.name = "$portal" + (formattedPrint portalId format:".2u") + "__" + mobj.name
		
		for v = 1 to numVerts do (
			local vert = mportal.verts[v]
			setVert portalNode v vert
		)
		local face = for v = 1 to numVerts collect v
		portalNode = convertToPoly portalNode
		polyop.createPolygon portalNode face

		portalNode.wirecolor = (color 255 0 199)
		portalNode.parent = nodes[1]		
		
		custAttributes.add portalNode MafParams_def baseObject:false
		local gp = custAttributes.get portalNode MafParams_def baseObject:false	
		
		gp.objectType = "Portal"
		gp.nearRange = mportal.nearRange
		gp.farRange = mportal.farRange		
		
		Layers.AddTo portalNode "Portals"
		
		append nodes portalNode
		
		portalId += 1
	)
	nodes
)




-- returns Node
fn CreateTarget mtarget mobj = (
	--local nnode = dummy()
	--nnode.boxsize = [0.1, 0.1, 0.1]
	
	local nnode = TargetObject()
	-- local nnode = point()
	-- nnode.size = 0.1
	-- nnode.constantscreensize = false
	-- nnode.box = true
	-- nnode.centermarker = true
	-- nnode.cross = false
	-- nnode.wirecolor = color 28 122 210
	
	--for linkId in mtarget.linkIds do (
	--	local lnode = mnodes[linkId]
	--	lnode.rotation.controller = LookAt_Constraint()
	--	lnode.rotation.controller.relative = true
	--	lnode.rotation.controller.viewline_length_abs = false
	--	lnode.rotation.controller.appendTarget nnode 50
	--)
	
	for linkIds in mtarget.linkIds do (
		
	)
	
	hide nnode
	
	nnode
)


fn ConvertMatrix mtr = (
	local row = #()
	for m = 1 to 4 do (
		row[m] = [mtr[m][1], mtr[m][2], mtr[m][3]]
	)	

	matrix3 row[1] row[2] row[3] row[4]
)

fn MatrixToFloatArray mtr = (
	local floats = #()
	for m = 1 to 4 do (
		for n = 1 to 4 do (
			append floats mtr[m][n]
		)
	)
	floats
)

fn CreateBone mbone mobj = (	
	--local nnode = dummy()
	--nnode.boxsize = [0.1, 0.1, 0.1]
	local nnode = bonesys.createBone [0,0,0] [0,0,0] [0,0,0]
	nnode.showlinks = true
	nnode.width = 0.01
	nnode.height = 0.01		
	
	--format "  boneId: %\n" mbone.boneId	
	
	custAttributes.add nnode MafParams_def baseObject:false
	local gp = custAttributes.get nnode MafParams_def baseObject:false
	gp.boneId = mbone.boneid
	
	--for i = 1 to 16 do gp.boneMatrix[i] = mbone.matrix[i]
	
	gp.boneMatrix = MatrixToFloatArray mbone.matrix
	
	nnode
)



fn CreateMaterials mmats = (
	if mmats.count > 0 then (
		godmat = multimaterial numsubs:(mmats.count+1)
		godmat[mmats.count+1] = undefined
		godmat.name = filename + " Materials"	

		for m = 1 to mmats.count do (
			local mmat = mmats[m]
			local mat = MafMat4()
			mat.name = "4dsMat"+(m as string)

			local flags = mmat.flags

			--Diffuse Map
			mat.diffuseMapEnable = (bit.get flags 19)

			mat.colored = (bit.get flags 28)
			mat.mipMapping = (bit.get flags 24)
			mat.twoSided = (bit.get flags 29)
			mat.animatedDiffuse = (bit.get flags 27)
			mat.animatedAlpha = (bit.get flags 26)

			--Environment Map
			mat.envMapEnable = (bit.get flags 20)

			mat.envOverlay = (bit.get flags 9)
			mat.envMultiply = (bit.get flags 10)
			mat.envAdditive = (bit.get flags 11)
			mat.YProj = (bit.get flags 13)
			mat.YDetail = (bit.get flags 14)
			mat.ZDetail = (bit.get flags 15)

			--Additional Effect
			mat.addEffect = (bit.get flags 16)
			mat.alphaMapEnable = (bit.get flags 31)
			mat.colorKey = (bit.get flags 30)
			mat.additiveMixing = (bit.get flags 32)

			mat.ambient = mmat.ambient
			mat.diffuse = mmat.diffuse
			mat.emission = mmat.emission
			mat.opacity = mmat.opacity*100

			if mat.envMapEnable then (
				mat.envMapAmount = mmat.envMapAmount*100
				local envMapName = mmat.envMapName
				if envMapName != undefined then (
					local envMap = bitmaptex()
					envMap.filename = envMapName
					mat.envMap = envMap
				)
			)

			local diffMapName = mmat.diffMapName
			if diffMapName != undefined then (
				local diffMap = bitmaptex()
				diffMap.filename = diffMapName
				mat.diffuseMap = diffMap
				showTextureMap mat on

				if mat.alphaMapEnable then (
					local alphaMapName = mmat.alphaMapName
					if alphaMapName != undefined then (
						local alphaMap = bitmaptex()
						alphaMap.filename = alphaMapName
						mat.alphaMap = alphaMap
					)
				)
			)						

			if mat.animatedDiffuse then (
				mat.animFrames = mmat.animFrames
				mat.animPeriod = mmat.animPeriod
			)

			godmat[m] = mat
		)
	)
)

struct TBuffer (
	mskinsArrays = #(),
	skinNodesArrays = #(),
	boneNodes = #(),   --sorted in boneid order
	bones_ids = #()
)

fn CreateSkins buffer = (
	local boneNodes = buffer.boneNodes
	local bones_ids = buffer.bones_ids

	for s = 1 to buffer.mskinsArrays.count do (
		local mskins = buffer.mskinsArrays[s]
		local nodes = buffer.skinNodesArrays[s]		
		
		for q = 1 to nodes.count do (			
			local nnode = nodes[q]
			local mskin = mskins[q]
		
			local oskin = Skin()	
			addModifier nnode oskin				
			max modify mode			
			select nnode
									
			local vertId = 1			
			
			for i = 1 to boneNodes.count do (
				skinOps.AddBone oskin boneNodes[i] 1
			)
					
			for i = 1 to boneNodes.count do (			
				for j = 1 to nnode.numverts do (				
					skinOps.ReplaceVertexWeights oskin j i 0.0				
				)
			)
			
			for i = 1 to nnode.numverts do (
				skinOps.unNormalizeVertex oskin i true
			)
			
			local boneid1 = 1
			for bn in mskin.vgroups do (		
				local boneid2 = bn.boneId + 1
				
				local gp = custAttributes.get boneNodes[boneid1] MafParams_def baseObject:false
				gp.linkedBoneId = bn.boneId
				
				local parnode = boneNodes[boneid1].parent
				local parid
				if parnode != undefined then (
					parid = bones_ids[parnode.inode.handle]
				)				
				
				for j = 1 to bn.numW1Verts do (
					local weight = 1.0
					skinOps.SetVertexWeights oskin vertId boneid1 weight				
					
					vertId += 1
				)
				
				for weight in bn.weights do (								
					skinOps.SetVertexWeights oskin vertId boneid1 weight
					
					if parid != undefined then (
						skinOps.SetVertexWeights oskin vertId parid (1.0 - weight)
					)
							
					vertId += 1
				)
				boneid1 += 1
			)
		)		
	)
)

fn CreateObjects mobjects = (	
	local buffer = TBuffer()	
	
	for i = 1 to mobjects.count do (		
		local mobj = mobjects[i]		
		local nnode
		
		case mobj.objectType of (
			1: case mobj.visualType of (
				0: (  --standardmesh
					local mmesh = mobj.definitions[1]
					local nodes = CreateMesh mmesh mobj
					nnode = nodes[1]
				)
				2: (  --singlemesh
					local mmesh = mobj.definitions[1]
					local mskins = mobj.definitions[2]
					local nodes = CreateMesh mmesh mobj
					nnode = nodes[1]
								
					append buffer.mskinsArrays mskins
					append buffer.skinNodesArrays nodes
				)
				3: (  --singlemorph
					local mmesh = mobj.definitions[1]
					local mskins = mobj.definitions[2]
					local mmorph = mobj.definitions[3]
					local nodes = CreateMesh mmesh mobj
					nnode = nodes[1]
					
					append buffer.mskinsArrays mskins
					append buffer.skinNodesArrays nodes					
					
					CreateMorph mmorph mobj mmesh nnode
				)
				4: ( 
					local mmesh = mobj.definitions[1]
					local mbillboard = mobj.definitions[2]
					local nodes = CreateMesh mmesh mobj
					nnode = nodes[1]
					CreateBillboard mbillboard nnode
					
					Layers.AddTo nnode "Billboards"
				)
				5: ( --morph
					local mmesh = mobj.definitions[1]
					local mmorph = mobj.definitions[2]
					local nodes = CreateMesh mmesh mobj
					nnode = nodes[1]			
					CreateMorph mmorph mobj mmesh nnode
				)
				6: (
					local mglows = mobj.definitions[1]
					nnode = CreateGlow mglows mobj
					Layers.AddTo nnode "Glows"
				)
				8: (
					local mmirror = mobj.definitions[1]
					nnode = CreateMirror mmirror mobj
				)
			)
			5: (
				local msector = mobj.definitions[1]
				nnode = (CreateSector msector mobj)[1]
				Layers.AddTo nnode "Sectors"
			)
			6: (
				local mdummy = mobj.definitions[1]
				nnode = CreateDummy mdummy mobj
				Layers.AddTo nnode "Dummies"
			)
			7: (
				local mtarget = mobj.definitions[1]
				nnode = CreateTarget mtarget mobj
			)
			10: (
				local mbone = mobj.definitions[1]
				nnode = CreateBone mbone mobj				
				Layers.AddTo nnode "Bones"	
				
				buffer.bones_ids[nnode.inode.handle] = mbone.boneId+1
				
				buffer.boneNodes[mbone.boneId+1] = nnode					
				
				
				format "% | objId: % | boneid: %\n" mobj.name i mbone.boneid
			)
		)
		
		if mobj.cullFlags == 16 then (
			Layers.AddTo nnode "Disabled"
		)				

		nnode.name = mobj.name
		
		if mobj.parentId > 0 then (
			nnode.parent = mnodes[mobj.parentId]
			nnode.transform = mobj.GetMatrix() * nnode.parent.transform					
		)
		else (
			nnode.transform = mobj.GetMatrix()
		)			

		custAttributes.add nnode MafParams_def baseObject:false
		local gp = custAttributes.get nnode MafParams_def baseObject:false

		gp.objectType = case mobj.objectType of (
			1: case mobj.visualType of (
				6: "Dummy"
				4: "Billboard"
				default: "Mesh"
			)
			5: "Sector"
			default: "Dummy"
		)
				
		gp.renderFlags = mobj.renderFlags
		gp.renderFlags2 = mobj.renderFlags2
		gp.cullFlags = mobj.cullFlags
		if mobj.strParams != undefined then gp.strParams = mobj.strParams
		
		append mnodes nnode
	)
	
	buffer
)

fn ImportNormals = (
	max modify mode
	select n_mesh_array

	local norm = Edit_Normals()
	norm.displayLength = 0.5
	modpanel.addmodtoselection norm

	--print (n_mesh_array.count as string)
	--print (n_normal_array.count as string)

	disableRefMsgs()  --makes a huge difference, 41 seconds with vs. 904 seconds without
	for i = 1 to n_mesh_array.count do
	(
		--print (n_normal_array[i].count as string)
		local p = n_mesh_array[i]

		local pn = n_normal_array[i]
		
		for i = 1 to p.numverts do
		(
			local vert_sel = #{i} --define a bitArray specifying vertex 1
			local normal_sel = #{} --define an empty bitArray to store the result
			--call the method with the two bitArrays passed by-reference:
			norm.ConvertVertexSelection &vert_sel &normal_sel node:p
			n = (normal_sel as array)[1]
			--norm.SetNormalExplicit n node:p
			norm.setnormal n pn[i] node:p
		)

		local vert_sel = #{1..p.numverts}
		local normal_sel = #{}
		norm.ConvertVertexSelection &vert_sel &normal_sel node:p
		norm.MakeExplicit selection:normal_sel node:p
	)


	enableRefMsgs()

	norm.RebuildNormals()
	clearSelection()
)



------------------------
---------MAIN-----------
------------------------
fn Main = (
	local file = getOpenFileName types:"4DS models (*.4ds)|*.4ds|All files (*.*)|*.*" historyCategory:"4dsImport"
	if file != undefined then
	(
		--delete $*
		--gc()

		if MafiaTools.editName.text == "" then (
			MafiaTools.editName.text = getFilenameFile file			
		)
		
		filename = getFilenameFile file

		format "importing: %\n" file
		local start = timeStamp()		

		gc light:true

		local used_start = (heapsize - heapfree) / 1024.0

		with redraw off (
			mnodes = #()

			f = fopen file "rb"
			
			local m4ds = Read4ds f
			
			CreateMaterials m4ds.materials
			local buffer = CreateObjects m4ds.objects			
			
			CreateSkins buffer
			
			Layers.Hide #("Disabled")
			Layers.HideLods #{1..9}

			if MafiaTools.importNormals.checked == true then (
				ImportNormals()			
			)

			fclose f			
		)	

		local end = timeStamp()		
		if end < start then end += 86400000 --timing over midnight
		local dur = (end - start) / 1000.0		

		CompleteRedraw()

		local used_end = (heapsize - heapfree) / 1024.0
		format "memory used ~ % KiB\n" (used_end - used_start)

		gc light:true

		local message = "Importing took " + (dur as string) + " seconds\n"
		format message
		messageBox message
	)
)

Main()

)