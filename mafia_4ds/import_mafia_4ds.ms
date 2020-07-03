(
	
include "layers.ms"

local mnodes
local mobjects = #()
local godmat
local filename

struct MObject
(
	objectType,
	visualType,
	renderFlags = 0,
	renderFlags2 = 0,
	parent,
	parentId,
	offset,
	scl,
	rot,
	cullFlags,
	name,
	userParams,
	--transform,
	
	fn GetMatrix = (
		local tMatrix = matrix3 [1, 0, 0] [0, 1, 0] [0, 0, 1] [offset.x, offset.y, offset.z]
		local sclMatrix = matrix3 [scl.x, 0, 0] [0, scl.y, 0] [0, 0, scl.z] [0, 0, 0]
		local rotMatrix = ((inverse rot) as matrix3)
		(sclMatrix * rotMatrix * tMatrix)		
	)
)

struct TMesh (
	instanceId,
	lods = #()
)

struct TLod (
	distance,
	mesh,
	normals = #()	
)


struct TSkin (	
	lods = #() --array of TSkinLod
)

struct TSkinLod (
	numW0Verts,
	dmin,
	dmax,
	groups = #()	--array of TSkinVertexGroup
)

struct TSkinVertexGroup (
	matrix = #(),  --4x4 matrix
	numW1Verts,
	boneId,
	dmin,
	dmax,
	weights = #()	--array of float
)


struct TMorph (
	sections = #(),
	numTargets
)

struct TMorphSection (
	vertices = #(),   --array of TMorphVertex
	vertexLinks = #()
)

struct TMorphVertex (
	targets = #()	--array of TMorphTarget
)

struct TMorphTarget (
	pos,   	--point3
	normal	--point3
)




struct TBillboard (
	rotAxis,
	rotMode
)


struct TGlow (
	glows = #() --array of TGlowData
)

struct TGlowData (
	position,  --screen offset
	materialId	
)


struct TMirror (
	dmin,
	dmax,
	unknown = #(),
	matrix = #(),
	backColor,
	drawDistance,
	mesh
)

struct TDummy (
	dmin,
	dmax
)


struct TSector (
	mesh,
	dmin,
	dmax,
	portals = #() --array of TPortal
)

struct TPortal (
	nearRange,
	farRange,
	verts = #() --array of point3
)


struct TTarget (
	unk1,
	unk2,
	linkIds = #()
)


struct TBone (
	matrix = #(), --4x4 matrix
	boneId
)


fn ReadText f = (
	local len = ReadByte f #unsigned

	local result
	if len > 0 then (
		local fmt = "%"
		local ss = StringStream ""
		for i = 1 to len do (
			format fmt (bit.intAsChar(ReadByte f #unsigned)) to:ss
		)
		result = ss as string
	)	
	result
)

fn ReadPoint3 f = (
	x = ReadFloat f
	y = ReadFloat f
	z = ReadFloat f
	[x, z, y]
)

fn ReadColor f = (
	r = (ReadFloat f) * 255
	g = (ReadFloat f) * 255
	b = (ReadFloat f) * 255
	clr = color r g b
	clr
)

fn ReadQuat f = (
	rw = ReadFloat f
	rx = ReadFloat f
	ry = ReadFloat f
	rz = ReadFloat f
	qt = quat rx rz ry rw
	qt
)

fn ReadFace f = (
	a = ReadShort f #unsigned
	b = ReadShort f #unsigned
	c = ReadShort f #unsigned
	[a+1, c+1, b+1]       --face vertex indexes are 1-based in 3ds Max
)

fn ReadUV f = (
	x = ReadFloat f
	y = ReadFloat f
	[x, 1-y, 0]
)

fn ReadMatrix4 f = (
	local mtr = #()
	for m = 1 to 4 do (	
		mtr[m] = #()				
		for n = 1 to 4 do mtr[m][n] = ReadFloat f
	)	
	mtr
)





fn ReadBaseObject f = (
	local mobj = MObject()
	
	mobj.objectType = ReadByte f #unsigned

	if mobj.objectType == 1 then (  --visual object
		mobj.visualType = ReadByte f #unsigned
		mobj.renderFlags = ReadByte f #unsigned
		mobj.renderFlags2 = ReadByte f #unsigned
	)		

	mobj.parentId = ReadShort f #unsigned
	mobj.offset = ReadPoint3 f
	mobj.scl = ReadPoint3 f	
	mobj.rot = ReadQuat f
	mobj.cullFlags = ReadByte f #unsigned
	mobj.name = ReadText f 
	mobj.userParams = ReadText f		
	
	mobj
)

local n_mesh_array = #()
local n_normal_array = #()

fn ReadMesh f = (
	local mmesh = TMesh()	
	mmesh.instanceId = ReadShort f #unsigned	
	
	if mmesh.instanceId == 0 then (
		local numlods = ReadByte f #unsigned
				
		if numlods > 0 then (
			for lodId = 0 to numlods - 1 do (
				local mlod = TLod()				
				mlod.distance = ReadFloat f								
				local numVerts = ReadShort f #unsigned
				local tr = TriMesh()
				setNumVerts tr numverts
				setNumTVerts tr numverts

				for i = 1 to numVerts do (
					local vert = ReadPoint3 f
					local normal = ReadPoint3 f					
					local uv = ReadUV f
					
					append mlod.normals normal
					setVert tr i vert
					setTVert tr i uv
				)

				local numFacegroups = ReadByte f #unsigned

				for i = 1 to numFacegroups do (
					local numFaces = ReadShort f #unsigned				
					local offset = getNumFaces tr
					local num = offset + numFaces
					setNumFaces tr num true			-- keep topology	

					for j = 1 to numFaces do (
						local face = ReadFace f
						setFace tr (offset+j) face
					)					
					local matId = ReadShort f #unsigned
					if matId == 0 then (
						matId = godmat.numsubs
					)
					for j = 1 to numFaces do (
						setFaceMatID tr (offset+j) matId
					)
				)
				
				buildTVFaces tr
				for i = 1 to tr.numfaces do (
					setTVFace tr i (getFace tr i)
				)				
				mlod.mesh = tr				
				append mmesh.lods mlod
			)			
		)
	)

	mmesh
)

fn CreateMesh mmesh mobj = (
	local nnode	
	if mmesh.instanceId != 0 then (
		nnode = instance mnodes[mmesh.instanceId]
	)
	else (
		if mmesh.lods.count == 0 then (
			nnode = Editable_mesh()
		)
		else (
			local lodId = 0
			for mlod in mmesh.lods do (	
				local lmesh = mesh mesh:mlod.mesh
				lmesh.wirecolor = color 0 0 0
				
				if lodId == 0 then nnode = lmesh
				else (
					lmesh.name = "$lod" + (lodId as string) + "__" + mobj.name
					lmesh.parent = nnode
				)

				if mmesh.lods.count > 1 then Layers.AddTo lmesh ("Lod"+(lodId as string))

				custAttributes.add lmesh MafParams_def baseObject:false 
				local gp = custAttributes.get lmesh mafParams_def baseObject:false

				gp.objectType = "Lod"
				gp.lodDist = mlod.distance
				gp.dontOptimize = true

				lmesh.material = godmat
				
				append n_mesh_array lmesh
				append n_normal_array mlod.normals
				
				lodId += 1
			)				
		)						
	)
	nnode
)



fn ReadSkin f numlods = (	
	
	local mskin = TSkin()

	for l = 1 to numLods do (
		local lod = TSkinLod()
		
		local numGroups = ReadByte f #unsigned
		lod.numW0Verts = ReadLong f #unsigned
	
		lod.dmin = ReadPoint3 f
		lod.dmax = ReadPoint3 f
	
		for i = 0 to numGroups-1 do (
			local vgroup = TSkinVertexGroup()
			
			--format "vertex group %\n" i
			
			vgroup.matrix = ReadMatrix4 f
			
			vgroup.numW1Verts = ReadLong f #unsigned
			local numWeights = ReadLong f #unsigned
			vgroup.boneId = ReadLong f #unsigned
			
			--format "  boneid: %\n" vgroup.boneId
			--format "   numW1Verts: %\n" vgroup.numW1Verts
			--format "   numWeights: %\n" numWeights
	
			vgroup.dmin = ReadPoint3 f
			vgroup.dmax = ReadPoint3 f
	
			for w = 1 to numWeights do (
				append vgroup.weights (ReadFloat f)
			)
			append lod.groups vgroup
		)
		append mskin.lods lod
	)	
	
	mskin
)



fn CreateSkin mskin nnode mobj = (
	local oskin = Skin()
	
	addModifier nnode oskin
	
	
	
	
	
	
)



fn ReadMorph f = (
	local mmorph = TMorph()
	local numTargets = ReadByte f #unsigned
	mmorph.numTargets = numTargets

	if numTargets > 0 then (
		local numLayers = ReadByte f #unsigned
		ReadByte f #unsigned   --unknown	
		for i = 1 to numLayers do	(
			local ms = TMorphSection()
			local numVerts = ReadShort f #unsigned
	
			for v = 1 to numVerts do (
				local mv = TMorphVertex()
				
				for t = 1 to numTargets do (
					local mt = TMorphTarget()
					mt.pos = ReadPoint3 f
					mt.normal = ReadPoint3 f
					append mv.targets mt
				)
				append ms.vertices mv								
			)
	
			if (numTargets * numVerts) > 0 then	ReadByte f #unsigned  --unknown
	
			for v = 1 to numVerts do	(
				local vertexLink = ReadShort f #unsigned 
				append ms.vertexLinks vertexLink
			)
			
			append mmorph.sections ms
		)
	
		local dmin = ReadPoint3 f
		local dmax = ReadPoint3 f
	
		for i = 1 to 4 do ReadFloat f   --unknown
	)	
	mmorph
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
	
	local sectionNames = #("mouth", "eyes", "brows")
	
	local sectionId = 1
	local marker = 1
	
	for sectMesh in meshes do (
		local sectionName = sectionNames[sectionId]
		WM3_CreateMarker tmod marker sectionName
		
		local targetId = 1
		
		for targetMesh in sectMesh do (
			local tnode = mesh mesh:targetMesh
			tnode.material = godmat			
			local name = stringstream ""
			format "ch % (%) | trgt %" sectionId sectionName targetId to:name	
			tnode.name = name as string			
			tnode.transform = mobj.GetMatrix() * (transMatrix [totalInc, 0, 0])	
			
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


fn ReadBillboard f = (
	local mbillboard = TBillboard()

	mbillboard.rotAxis = ReadLong f #unsigned
	mbillboard.rotMode = ReadByte f #unsigned
	
	mbillboard
)

fn CreateBillboard mbillboard nnode = (		
	custAttributes.add nnode MafParams_def baseObject:false
	local gp = custAttributes.get nnode MafParams_def baseObject:false

	gp.rotAxis = mbillboard.rotAxis + 1
	gp.rotMode = mbillboard.rotMode + 1
)


fn ReadGlow f = (
	
	local mglow = TGlow()

	local numGlows = ReadByte f #unsigned
	--format "[Glow] % - numGlows = %\n" mobj.name numGlows
	for i = 1 to numGlows do
	(
		local data = TGlowData()		
		
		data.position = ReadFloat f
		data.materialId = ReadShort f #unsigned
		
		append mglow.glows data
		
		--format "  [glow %]\n" i
		--format "    position = %\n" position
		--format "    matID = %\n" matID
	)
	
	--format "\n"	
	
	mglow
)

fn CreateGlow mglow mobj = (
	local nnode = point()
	nnode.constantscreensize = true
	nnode.box = true
	nnode.centermarker = true
	nnode.cross = false
	--nnode.wirecolor = color 248 88 0
	nnode.wirecolor = color 248 128 0
	
	--local nnode = dummy()
	--nnode.boxsize = [0.2, 0.2, 0.2]
	
	nnode
)



fn ReadMirror f = (
	local mMirror = TMirror()	

	mMirror.dmin = ReadPoint3 f
	mMirror.dmax = ReadPoint3 f

	for i = 1 to 4 do local unknown = ReadFloat f
	for i = 1 to 16 do local reflectionMatrix = ReadFloat f
	
	mMirror.backColor = ReadColor f
	mMirror.drawDistance = ReadFloat f

	local numVerts = ReadLong f #unsigned
	local numFaces = ReadLong f #unsigned

	local tr = TriMesh()
	setNumVerts tr numVerts
	setNumFaces tr numFaces

	for i = 1 to numVerts do (
		local vert = ReadPoint3 f
		setVert tr i vert
	)

	for i = 1 to numFaces do (
		local face = ReadFace f
		setFace tr i face
	)
	
	mMirror.mesh = tr
	
	mMirror
)

fn CreateMirror mmirror mobj = (
	nnode = mesh mesh:mmirror.mesh
)


fn ReadDummy f = (
	local mDummy = TDummy()	
	mDummy.dmin = ReadPoint3 f
	mDummy.dmax = ReadPoint3 f		
	mDummy
)

fn CreateDummy mdummy mobj = (
	local dmin = mdummy.dmin
	local dmax = mdummy.dmax
	local nnode = dummy()
	nnode.boxsize = [(abs (dmin.x-dmax.x)), (abs (dmin.y-dmax.y)), (abs (dmin.z-dmax.z))]	
	
	hide nnode
		
	nnode
)



fn ReadSector f = (
	local msector = TSector()	

	ReadLong f #unsigned --always 2049
	ReadLong f #unsigned --always 0

	local numVerts = ReadLong f #unsigned
	local numFaces = ReadLong f #unsigned

	local tr = TriMesh()
	setNumVerts tr numVerts
	setNumFaces tr numFaces

	for i = 1 to numVerts do (
		local vert = ReadPoint3 f
		setVert tr i vert
	)

	for i = 1 to numFaces do (
		local face = ReadFace f
		setFace tr i face
		setFaceSmoothGroup tr i 0
	)
	
	msector.mesh = tr	
	msector.dmin = ReadPoint3 f
	msector.dmax = ReadPoint3 f

	local numPortals = ReadByte f #unsigned

	for i = 1 to numPortals do (		
		local mportal = TPortal()
		local numVerts = ReadByte f #unsigned
		for j = 1 to 5 do ReadLong f #unsigned
		mportal.nearRange = ReadFloat f
		mportal.farRange = ReadFloat f
				
		for v = 1 to numVerts do (
			local vert = ReadPoint3 f
			append mportal.verts vert
		)		
		append msector.portals mportal	
	)

	
	msector
)

fn CreateSector msector mobj = (
	local nnode = mesh mesh:msector.mesh
	nnode.wirecolor = (color 255 199 0)	
	
	local portalId = 0
	for mportal in msector.portals do (
		local numverts = mportal.verts.count
		local pmesh = mesh numverts:numVerts
		pmesh.name = "$portal" + (formattedPrint portalId format:".2u") + "__" + mobj.name
		
		for v = 1 to numVerts do (
			local vert = mportal.verts[v]
			setVert pmesh v vert
		)
		local face = for v = 1 to numVerts collect v
		local p = convertToPoly pmesh
		polyop.createPolygon p face

		p.wirecolor = (color 255 0 199)
		p.parent = nnode		
		
		custAttributes.add p MafParams_def baseObject:false
		local gp = custAttributes.get p MafParams_def baseObject:false	
		
		gp.objectType = "Portal"
		gp.nearRange = mportal.nearRange
		gp.farRange = mportal.farRange		
		
		Layers.AddTo p "Portals"
		
		portalId += 1
	)
	nnode
)



-- returns TTarget
fn ReadTarget f = (
	local mTarget = TTarget()	

	mTarget.unk1 = ReadByte f #unsigned
	mTarget.unk2 = ReadByte f #unsigned
	local numLinks = ReadByte f #unsigned
	
	for i = 1 to numLinks do (
		append mTarget.linkIds (ReadShort f #unsigned)
	)
	
	mTarget
)

-- returns Node
fn CreateTarget mtarget mobj = (
	--local nnode = dummy()
	--nnode.boxsize = [0.1, 0.1, 0.1]
	
	--local nnode = TargetObject()
	local nnode = point()
	nnode.size = 0.1
	nnode.constantscreensize = false
	nnode.box = true
	nnode.centermarker = true
	nnode.cross = false
	nnode.wirecolor = color 28 122 210
	
	for linkId in mtarget.linkIds do (
		local lnode = mnodes[linkId]
		lnode.rotation.controller = LookAt_Constraint()
		lnode.rotation.controller.relative = true
		lnode.rotation.controller.viewline_length_abs = false
		lnode.rotation.controller.appendTarget nnode 50
	)
	
	--hide nnode
	
	nnode
)


fn ConvertMatrix mtr = (
	local row = #()
	for m = 1 to 4 do (
		row[m] = [mtr[m][1], mtr[m][2], mtr[m][3]]
	)	

	matrix3 row[1] row[2] row[3] row[4]
)

fn ReadBone f = (
	local mbone = TBone()	
	mbone.matrix = ReadMatrix4 f		
	mbone.boneId = ReadLong f #unsigned
	mbone
)

fn CreateBone mbone mobj = (	
	--local nnode = dummy()
	--nnode.boxsize = [0.1, 0.1, 0.1]
	local nnode = bonesys.createBone [0,0,0] [0,0,0] [0,0,0]
	nnode.showlinks = true
	nnode.width = 0.01
	nnode.height = 0.01		
	
	--format "  boneId: %\n" mbone.boneId	
	nnode
)

fn ReadHeader f = (
	local fourcc = ReadLong f #unsigned
	local version = ReadShort f #unsigned
	if version != 29 then MessageBox "Unknown 4DS version - importing might not work correctly"
	local timestamp = ReadLongLong f
)

smaterials = 0
fn ReadMaterials f = (

	local numMats = ReadShort f #unsigned
	smaterials = numMats
	
	if numMats > 0 then (
		godmat = multimaterial numsubs:(numMats+1)
		godmat[numMats+1] = undefined
		godmat.name = filename + " Materials"	

		for m = 1 to numMats do (
			local mat = MafMat4()
			mat.name = "4dsMat"+(m as string)

			local flags = ReadLong f #unsigned

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

			mat.ambient = ReadColor f
			mat.diffuse = ReadColor f
			mat.emission = ReadColor f
			mat.opacity = (ReadFloat f)*100

			if mat.envMapEnable then (
				mat.envMapAmount = (ReadFloat f)*100
				local envMapName = ReadText f 
				if envMapName != undefined then (
					local envMap = bitmaptex()
					envMap.filename = envMapName
					mat.envMap = envMap
				)
			)

			local diffMapName = ReadText f
			if diffMapName != undefined then (
				local diffMap = bitmaptex()
				diffMap.filename = diffMapName
				mat.diffuseMap = diffMap
				showTextureMap mat on

				if mat.alphaMapEnable then (
					local alphaMapName = ReadText f
					if alphaMapName != undefined then (
						local alphaMap = bitmaptex()
						alphaMap.filename = alphaMapName
						mat.alphaMap = alphaMap
					)
				)
			)
						

			if mat.animatedDiffuse then (
				mat.animFrames = ReadLong f #unsigned
				ReadShort f #unsigned  --unknown
				mat.animPeriod = ReadLong f #unsigned
				ReadLong f #unsigned  --unknown
				ReadLong f #unsigned  --unknown
			)

			godmat[m] = mat
		)
	)
)

local skinbuffer = #()
local skinNodeBuffer = #()

local bonebuffer = #()
local boneNodeBuffer = #()

local bones = #()   --key = bone id, data = node

fn CreateSkins = (
	for s = 1 to skinbuffer.count do (
		local mskin = skinbuffer[s]
		local nnode = skinNodeBuffer[s]
		
		local oskin = Skin()
	
		addModifier nnode oskin	
						
		--format "numW0Verts: %\n" mskin.lods[1].numW0Verts
		--local vertId = mskin.lods[1].numW0Verts + 1
		local vertId = 1			
		
		local id = 1
		for bonenode in bones do (
			skinOps.AddBone oskin bonenode 1
			
			-- for j = 1 to nnode.numverts do (
			-- 	skinOps.ReplaceVertexWeights oskin j id 0.0				
			-- )
			id += 1
		)
		
		local boneid1 = 1
		for bn in mskin.lods[1].groups do (			
			--format "bn: %\n" bn
			local boneid2 = bn.boneId + 1
			--local bonenode = bones[boneid2]
			--format "bonenode: %\n" bonenode
			
			for j = 1 to bn.numW1Verts do (
				local weight1 = 1.0
				local weight2 = 0.0
				skinOps.ReplaceVertexWeights oskin vertId boneid2 weight2
				skinOps.ReplaceVertexWeights oskin vertId boneid1 weight1
				
				--format "vertid: % - numW1Verts\n" vertId				
				vertId += 1
			)
			
			for weight in bn.weights do (
				local weight1 = weight
				local weight2 = 1.0 - weight
				skinOps.ReplaceVertexWeights oskin vertId boneid2 weight2
				skinOps.ReplaceVertexWeights oskin vertId boneid1 weight1
				
				--format "vertid: % - weights\n" vertId				
				vertId += 1
			)
			boneid1 += 1
		)
	)
)

progress = 0
sobjects = 0
fn ReadObjects f = (
	local numObjects = ReadShort f #unsigned

	sobjects = numObjects

	for i = 0 to numObjects - 1 do
	(				
		local mobj = ReadBaseObject f
		append mobjects mobj
		
		
		--format "%: %\n" i mobj.name 
		
		local nnode
		
		case mobj.objectType of (
			1: case mobj.visualType of (
				0: (
					local mmesh = ReadMesh f 
					nnode = CreateMesh mmesh mobj
				)
				2: (
					local mmesh = ReadMesh f 
					local mskin = ReadSkin f mmesh.lods.count
					nnode = CreateMesh mmesh mobj		
								
					append skinbuffer mskin
					append skinNodebuffer nnode
					
					--CreateSkin mskin nnode mobj
				)
				3: (
					local mmesh = ReadMesh f
					local mskin = ReadSkin f mmesh.lods.count
					local mmorph = ReadMorph f
					nnode = CreateMesh mmesh mobj
					
					append skinbuffer mskin
					append skinNodebuffer nnode
					
					
					CreateMorph mmorph mobj mmesh nnode
					
					--CreateSkin mskin nnode mobj
				)
				4: (
					local mmesh = ReadMesh f
					local mbillboard = ReadBillboard f 
					nnode = CreateMesh mmesh mobj
					CreateBillboard mbillboard nnode
					
					Layers.AddTo nnode "Billboards"
				)
				5: (
					local mmesh = ReadMesh f
					local mmorph = ReadMorph f
					nnode = CreateMesh mmesh mobj
				)
				6: (
					local mglow = ReadGlow f
					nnode = CreateGlow mglow mobj
					Layers.AddTo nnode "Glows"
				)
				8: (
					local mmirror = ReadMirror f
					nnode = CreateMirror mmirror mobj
				)
			)
			5: (
				local msector = ReadSector f
				nnode = CreateSector msector mobj
				Layers.AddTo nnode "Sectors"
			)
			6: (
				local mdummy = ReadDummy f
				nnode = CreateDummy mdummy mobj
				Layers.AddTo nnode "Dummies"
			)
			7: (
				local mtarget = ReadTarget f
				nnode = CreateTarget mtarget mobj
			)
			10: (
				local mbone = ReadBone f
				nnode = CreateBone mbone mobj				
				Layers.AddTo nnode "Bones"	
				
				
				bones[mbone.boneId+1] = nnode
				
				append bonebuffer mbone
				append boneNodeBuffer nnode				
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
		
		--nnode.transform = GetTransform mobj
		
		-- if mobj.objectType != 10 then (
			
		-- 	--nnode.parent = mobj.parent
		-- 	nnode.transform = GetTransform mobj
		-- )
			

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
		if mobj.userParams != undefined then gp.userParams = mobj.userParams
		
		append mnodes nnode
	)
	
	--print bones
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

			ReadHeader f
			ReadMaterials f	
			ReadObjects f
			
			CreateSkins()
			
			Layers.Hide #("Disabled")
			Layers.HideLods #{1..9}

			if MafiaTools.importNormals.checked == true then (
				ImportNormals()			
			)

			fclose f		
			
			format "\n-----------------------------------------------------------\n"	
			format "StandardMeshes: %\n" sstandardmeshes
			format "SingleMeshes: %\n" ssinglemeshes
			format "Morphs: %\n" smorphs
			format "SingleMorphs: %\n" ssinglemorphs
			format "Billboards: %\n" sbillboards
			format "Glows: %\n" sglows
			format "Mirrors: %\n" smirrors
			format "Sectors: %\n" ssectors
			format "Dummies: %\n" sdummies
			format "Targets: %\n" stargets
			format "Bones: %\n\n" sbones	

			format "Materials: %\n" smaterials
			format "Total objects: %\n\n" sobjects 		

			--if (smirrors > 0) or (sglows > 0) or (stargets > 0) then MessageBox "its here!"
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