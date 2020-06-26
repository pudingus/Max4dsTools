(
	
include "layers.ms"

local mnodes
local godmat
local filename

struct MObject
(
	parent,
	offset,
	scl,
	rot,
	cullFlags,
	name,
	userParams
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
	bones = #()	--array of TSkinLodBone
)

struct TSkinLodBone (
	matrix = #(),  --4x4 matrix - array of float (16)
	numW1Verts,
	boneId,
	dmin,
	dmax,
	weights = #()	--array of float
)


struct TMorph (
	targets = #()
)

struct TMorphTarget (
	unknown,
	channels = #()
)

struct TMorphChannel (
	aaa
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
	matrix = #(),
	boneId
)


fn ReadText f = (
	local len = ReadByte f

	local result
	if len > 0 then (
		local fmt = "%"
		local ss = StringStream ""
		for i = 1 to len do (
			format fmt (bit.intAsChar(ReadByte f)) to:ss
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





fn ReadBaseObject f = (
	local mobj = MObject()

	local parentId = ReadShort f
	if parentId > 0 then (
		mobj.parent = mnodes[parentId]
	)

	mobj.offset = ReadPoint3 f
	mobj.scl = ReadPoint3 f	
	mobj.rot = ReadQuat f
	mobj.cullFlags = ReadByte f #unsigned
	mobj.name = ReadText f 
	mobj.userParams = ReadText f

	mobj
)

fn ApplyTransform nnode mobj = (

	local offset = mobj.offset
	local scl = mobj.scl
	local rot = mobj.rot
	local matrix = matrix3 [1, 0, 0] [0, 1, 0] [0, 0, 1] [offset.x, offset.y, offset.z]
	local sclMatrix = matrix3 [scl.x, 0, 0] [0, scl.y, 0] [0, 0, scl.z] [0, 0, 0]
	local rotMatrix = ((inverse rot) as matrix3)

	if nnode.parent != undefined then (
		nnode.transform = (sclMatrix*rotMatrix*matrix*nnode.parent.transform)
	)
	else (
		nnode.transform = (sclMatrix*rotMatrix*matrix)
	)
)

n_mesh_array = #()
n_normal_array = #()



fn ReadMesh f = (
	local mmesh = TMesh()	
	mmesh.instanceId = ReadShort f	
	
	if mmesh.instanceId == 0 then (
		local numlods = ReadByte f
				
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

				local numFacegroups = readbyte f #unsigned

				for i = 1 to numFacegroups do (
					local numFaces = readshort f #unsigned				
					local offset = getNumFaces tr
					local num = offset + numFaces
					setNumFaces tr num true			-- keep topology	

					for j = 1 to numFaces do (
						local face = ReadFace f
						setFace tr (offset+j) face
					)					
					local matId = ReadShort f
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

				if mmesh.lods.count > 1 then Layers.AddLod lmesh lodId

				custAttributes.add lmesh MafParams_def baseObject:false 
				local gp = custAttributes.get lmesh mafParams_def baseObject:false

				gp.objectType = "Lod"
				gp.lodDist = mlod.distance
				gp.dontOptimize = true

				lmesh.material = godmat
				
				lodId += 1
			)				
		)						
	)
	nnode
)



fn ReadSkin f numlods = (	
	
	local mskin = TSkin()

	for i = 1 to numLods do (
		local lod = TSkinLod()
		
		local numBones = ReadByte f
		lod.numW0Verts = ReadLong f
	
		lod.dmin = ReadPoint3 f
		lod.dmax = ReadPoint3 f
	
		for i = 1 to numBones do (
			local bone = TSkinLodBone()
			
			for b = 1 to 16 do append bone.matrix (ReadFloat f)
			
			bone.numW1Verts = ReadLong f
			local numWeights = ReadLong f
			bone.boneId = ReadLong f
	
			bone.dmin = ReadPoint3 f
			bone.dmax = ReadPoint3 f
	
			for w = 1 to numWeights do (
				append bone.weights (ReadFloat f)
			)
			append lod.bones bone
		)
		append mskin.lods lod
	)	
	
	mskin
)

fn CreateSkin = (
	-- todo
)



fn ReadMorph f = (
	local mmorph = TMorph()
	local numTargets = ReadByte f

	if numTargets > 0 then (
		local numChannels = ReadByte f
		ReadByte f   --unknown	
		for i = 1 to numChannels do	(
			local numVerts = ReadShort f
	
			for v = 1 to (numTargets * numVerts) do	(
				local vert = ReadPoint3 f
				local normal = ReadPoint3 f
			)
	
			if (numTargets * numVerts) > 0 then	ReadByte f  --unknown
	
			for v = 1 to numVerts do	(
				local vertexLink = ReadShort f 
			)
		)
	
		local dmin = ReadPoint3 f
		local dmax = ReadPoint3 f
	
		for i = 1 to 4 do ReadFloat f   --unknown
	)	
	mmorph
)

fn CreateMorph = (
	-- todo
)


fn ReadBillboard f = (
	local mbillboard = TBillboard()

	mbillboard.rotAxis = ReadLong f
	mbillboard.rotMode = ReadByte f
	
	mbillboard
)

fn CreateBillboard nnode mobj = (
		
	custAttributes.add nnode MafParams_def baseObject:false
	local gp = custAttributes.get nnode MafParams_def baseObject:false

	gp.rotAxis = mbillboard.rotAxis + 1
	gp.rotMode = mbillboard.rotMode + 1
	
	--AddToBillboardLayer nnode
	Layers.AddTo nnode #billboard
	
	nnode
)




fn ReadGlow f mobj = (
	
	local mglow = TGlow()

	local numGlows = ReadByte f
	--format "[Glow] % - numGlows = %\n" mobj.name numGlows
	for i = 1 to numGlows do
	(
		local data = TGlowData()		
		
		data.position = ReadFloat f
		data.materialId = ReadShort f
		
		append mglow.glows data
		
		--format "  [glow %]\n" i
		--format "    position = %\n" position
		--format "    matID = %\n" matID
	)
	
	--format "\n"	
	
	mglow
)

fn CreateGlow mglow mobj = (
	--local nnode = point()
	--nnode.constantscreensize = true
	--nnode.box = true
	
	local nnode = dummy()
	nnode.boxsize = [0.2, 0.2, 0.2]
	Layers.AddTo nnode #glow
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

	local numVerts = ReadLong f
	local numFaces = ReadLong f

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
	
	Layers.AddTo nnode #dummy
	
	hide nnode
		
	nnode
)



fn ReadSector f = (
	local msector = TSector()	

	ReadLong f --always 2049
	ReadLong f --always 0

	local numVerts = ReadLong f
	local numFaces = ReadLong f

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

	local numPortals = ReadByte f

	for i = 1 to numPortals do (		
		local mportal = TPortal()
		local numVerts = ReadByte f
		for j = 1 to 5 do ReadLong f
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

	Layers.AddTo nnode #sector
	
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
		
		Layers.AddTo nnode #portal	
		
		portalId += 1
	)
	nnode
)



-- returns TTarget
fn ReadTarget f = (
	local mTarget = TTarget()	

	mTarget.unk1 = ReadByte f
	mTarget.unk2 = ReadByte f
	local numLinks = ReadByte f
	
	for i = 1 to numLinks do (
		append mTarget.linkIds (ReadShort f)
	)
	
	mTarget
)

-- returns Node
fn CreateTarget mtarget mobj = (
	local nnode = dummy()
	nnode.boxsize = [0.1, 0.1, 0.1]
	
	nnode
)


fn ReadBone f = (
	local mbone = TBone()	
	for i = 1 to 16 do (
		append mbone.matrix (ReadFloat f)			
	)	
	mbone.boneId = ReadLong f
	mbone
)

fn CreateBone mbone mobj = (
	local nnode = bone()
	--local nnode = dummy()
	--nnode.boxsize = [0.1, 0.1, 0.1]
	Layers.AddTo nnode #bone
	
	nnode
)

fn ReadHeader f = (
	local fourcc = ReadLong f
	local version = ReadShort f
	if version != 29 then MessageBox "Unknown 4DS version - importing might not work correctly"
	local timestamp = ReadLongLong f
)

smaterials = 0
fn ReadMaterials f = (

	local numMats = ReadShort f
	smaterials = numMats
	
	if numMats > 0 then (
		godmat = multimaterial numsubs:(numMats+1)
		godmat[numMats+1] = undefined
		godmat.name = filename + " Materials"	

		for m = 1 to numMats do (
			local mat = MafMat4()
			mat.name = "4dsMat"+(m as string)

			local flags = ReadLong f

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
				mat.animFrames = ReadLong f
				ReadShort f  --unknown
				mat.animPeriod = ReadLong f
				ReadLong f  --unknown
				ReadLong f  --unknown
			)

			godmat[m] = mat
		)
	)
)

progress = 0
sobjects = 0
fn ReadObjects f = (
	local numObjects = ReadShort f

	sobjects = numObjects

	for i = 0 to numObjects - 1 do
	(
		local objectType = ReadByte f
		local visualType
		local renderFlags = 0
		local renderFlags2 = 0

		if objectType == 1 do --visual object
		(
			visualType = ReadByte f
			renderFlags = ReadByte f
			renderFlags2 = ReadByte f
		)		
		local mobj = ReadBaseObject f
		
		format "%: %\n" i mobj.name 
		
		local nnode = case objectType of (
			1: case visualType of (
				0: (
					local mmesh = ReadMesh f 
					CreateMesh mmesh mobj
				)
				2: (
					local mmesh = ReadMesh f 
					local mskin = ReadSkin f mmesh.lods.count
					CreateMesh mmesh mobj
				)
				3: (
					local mmesh = ReadMesh f
					local mskin = ReadSkin f mmesh.lods.count
					local mmorph = ReadMorph f
					CreateMesh mmesh mobj
				)
				4: (
					local mmesh = ReadMesh f
					local mbillboard = ReadBillboard f 
					CreateMesh mmesh mobj
				)
				5: (
					local mmesh = ReadMesh f
					local mmorph = ReadMorph f
					CreateMesh mmesh mobj
				)
				6: (
					local mglow = ReadGlow f
					CreateGlow mglow mobj
				)
				8: (
					local mmirror = ReadMirror f
					CreateMirror mmirror mobj
				)
			)
			5: (
				local msector = ReadSector f
				CreateSector msector mobj
			)
			6: (
				local mdummy = ReadDummy f
				CreateDummy mdummy mobj
			)
			7: (
				local mtarget = ReadTarget f
				CreateTarget mtarget mobj
			)
			10: (
				local mbone = ReadBone f
				CreateBone mbone mobj
			)
		)
				

		nnode.name = mobj.name
		nnode.parent = mobj.parent

		ApplyTransform nnode mobj	

		custAttributes.add nnode MafParams_def baseObject:false
		local gp = custAttributes.get nnode MafParams_def baseObject:false

		if objectType == 1 then (
			if visualType == 6 then (
				gp.objectType = "Dummy"
			)
			else if visualType == 4 then (
				gp.objectType = "Billboard"
			)
			else (
				gp.objectType = "Mesh"
			)
		)
		else if objectType == 5 then (
			gp.objectType = "Sector"
		)
		else (
			gp.objectType = "Dummy"
		)

		gp.renderFlags = renderFlags
		gp.renderFlags2 = renderFlags2
		gp.cullFlags = mobj.cullFlags
		if mobj.userParams != undefined then gp.userParams = mobj.userParams
		
		append mnodes nnode
	)
)

fn ImportNormals = (
	max modify mode
	select n_mesh_array

	local norm = Edit_Normals()
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