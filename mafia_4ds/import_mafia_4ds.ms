(

local mnodes
local nnode
local godmat


local lod_layers = #()
local dummy_layer
local sector_layer
local portal_layer
local bone_layer
local glow_layer

local filename


fn AddToLayer obj layerName layer = (
	if layer == undefined then (
		layer = LayerManager.getLayerFromName layerName
		if layer == undefined then (
			layer = LayerManager.newLayerFromName layerName
		)
	)
	layer.addnode obj
)

fn AddToGlowLayer obj = (
	local str = "Glows"
	AddToLayer obj str glow_layer
)

fn AddToDummyLayer obj = (
	local str = "Dummies"
	AddToLayer obj str dummy_layer
)

fn AddToSectorLayer obj = (
	local str = "Sectors"
	AddToLayer obj str sector_layer
)

fn AddToPortalLayer obj = (
	local str = "Portals"
	AddToLayer obj str portal_layer
)

fn AddToBoneLayer obj = (
	local str = "Bones"
	AddToLayer obj str bone_layer
)

fn AddToGlowLayer obj = (
	local str = "Glows"
	AddToLayer obj str glow_layer
)

fn AddToLodLayer lodId obj = (
	local layer = lod_layers[lodId + 1]
	local str = "LOD" + (lodId as string) + " LAYER"
	if layer == undefined then (
		layer = LayerManager.getLayerFromName str
		if layer == undefined then (
			layer = LayerManager.newLayerFromName str
			lod_layers[lodId + 1] = layer

			if lodId >= 1 then layer.ishidden = true
		)

	)
	layer.addnode obj
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

n_mesh_array = #()
n_normal_array = #()

sstandardmeshes = 0
fn ReadStandardMesh f mobj = (
	local numlods = 0
	duplicateID = ReadShort f
	if duplicateID != 0 then
	(
		nnode = reference mnodes[duplicateID]
	)
	else
	(
		numLods = ReadByte f

		if numLods == 0 then (
			nnode = editable_mesh()
		)

		for lodId = 0 to numLods - 1 do
		(
			local clippingRange = ReadFloat f  --clipping range

			local normals_array = #()

			local numVerts = readshort f #unsigned

			local tr = TriMesh()
			setNumVerts tr numverts
			setNumTVerts tr numverts

			for i = 1 to numVerts do
			(
				local vert = ReadPoint3 f

				local normal = ReadPoint3 f
				append normals_array [normal.x, normal.y, normal.z]

				local uv = ReadUV f

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
				--local matId = (ReadShort f) + 1 	-- coz 'material_none' is 0 in mafia, but 1 in max

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

			local lmesh = mesh mesh:tr

			lmesh.wirecolor = color 0 0 0


			if lodId == 0 then (
				nnode = lmesh
			)
			else (
				lmesh.name = "$lod" + (lodId as string) + "__" + mobj.name
				lmesh.parent = nnode
			)

			if numLods > 1 then (
				AddToLodLayer lodId lmesh
			)		


			local lmod = MafLod4()
			lmod.lodDist = clippingRange
			lmod.dontOptimize = true			
			addmodifier lmesh lmod

			lmesh.material = godmat

			append n_mesh_array lmesh
			append n_normal_array normals_array
		)
	)

	sstandardmeshes += 1

	numLods
)

ssinglemeshes = 0
fn ReadSingleMesh f mobj = (
	local numLods = ReadStandardMesh f mobj
	sstandardmeshes -= 1

	for i = 1 to numLods do (
		local numBones = ReadByte f
		local numW0Verts = ReadLong f
	
		local dmin = ReadPoint3 f
		local dmax = ReadPoint3 f
	
		for i = 1 to numBones do (
			for b = 1 to 64 do ReadByte f   --rotation matrix
			local numW1Verts = ReadLong f
			local numWeights = ReadLong f
			local boneID = ReadLong f
	
			local dmin = ReadPoint3 f
			local dmax = ReadPoint3 f
	
			for w = 1 to numWeights do (
				ReadFloat f
			)
		)
	)	

	ssinglemeshes += 1
)

fn ReadBaseMorph f mobj = (
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
)

ssinglemorphs = 0
fn ReadSingleMorph f mobj = (
	ReadSingleMesh f mobj
	ReadBaseMorph f mobj

	ssinglemorphs += 1
)

smorphs = 0
fn ReadMorph f mobj = (
	ReadStandardMesh f mobj
	sstandardmeshes -= 1
	ReadBaseMorph f mobj

	smorphs += 1
)

sbillboards = 0
fn ReadBillboard f mobj = (
	ReadStandardMesh f mobj
	sstandardmeshes -= 1

	local axis = ReadLong f
	local axisMode = ReadByte f

	--print ("Billboard: " + mobj.name)

	sbillboards += 1
)

sglows = 0
fn ReadGlow f mobj = (

	local numGlows = ReadByte f
	for i = 1 to numGlows do
	(
		local position = ReadFloat f
		local matID = ReadShort f
	)

	--nnode = point()
	--nnode.constantscreensize = true
	--nnode.box = true

	nnode = dummy()
	nnode.boxsize = [0.2, 0.2, 0.2]

	AddToGlowLayer nnode

	--print ("Glow (numGlows: " + (numGlows as string) + "): " + mobj.name)

	sglows += 1
)

smirrors = 0
fn ReadMirror f mobj = (

	local minBox = ReadPoint3 f
	local maxBox = ReadPoint3 f

	for i = 1 to 4 do unknown = ReadFloat f
	for i = 1 to 16 do reflectionMatrix = ReadFloat f
	
	local backColor = ReadColor f
	local drawDistance = ReadFloat f

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

	nnode = mesh mesh:tr

	--print ("Mirror: " + mobj.name)

	smirrors += 1
)

sdummies = 0
fn ReadDummy f mobj = (
	nnode = dummy()

	local dmin = ReadPoint3 f
	local dmax = ReadPoint3 f

	nnode.boxsize = [(abs (dmin.x-dmax.x)), (abs (dmin.y-dmax.y)), (abs (dmin.z-dmax.z))]

	AddToDummyLayer nnode

	hide nnode

	sdummies += 1
)

ssectors = 0
fn ReadSector f mobj = (
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

	nnode = mesh mesh:tr

	AddToSectorLayer nnode

	nnode.wirecolor = (color 255 199 0)

	local dmin = ReadPoint3 f
	local dmax = ReadPoint3 f

	local numPortals = ReadByte f

	for i = 0 to numPortals-1 do (

		local numVerts = ReadByte f
		ReadLong f  --always 4
		ReadLong f
		ReadLong f
		ReadLong f
		ReadLong f  --flags?

		local nearRange = ReadFloat f
		local farRange = ReadFloat f

		pmesh = mesh numverts:numVerts
		pmesh.name = "$portal" + (formattedPrint i format:".2u") + "__" + mobj.name

		for v = 1 to numVerts do (
			local vert = ReadPoint3 f
			setVert pmesh v vert
		)

		local verts = for v = 1 to numVerts collect v

		p = convertToPoly pmesh
		polyop.createPolygon p verts

		p.wirecolor = (color 255 0 199)


		AddToPortalLayer p

		local modpp = MafPortal4()
		modpp.nearRange = nearRange
		modpp.farRange = farRange
		addmodifier p modpp


		p.parent = nnode
	)

	-- print ("Sector: " + mobj.name)

	ssectors += 1
)

stargets = 0
fn ReadTarget f mobj = (
	nnode = dummy()
	nnode.boxsize = [0.1, 0.1, 0.1]

	local unk0 = ReadByte f
	local unk1 = ReadByte f
	local numLinks = ReadByte f

	-- print ("Target: " + mobj.name)
	-- print ("  unk0: " + (unk0 as string))
	-- print ("  unk1: " + (unk1 as string))
	-- print ("  numLinks: " + (numLinks as string))

	for i = 1 to numLinks do (
		local linkId = ReadShort f
		-- print ("  linkId: " + (linkId as string) + " - " + mnodes[linkid].name)
	)

	stargets += 1
)

sbones = 0
fn ReadBone f mobj = (
	--nnode = bone()
	nnode = dummy()
	nnode.boxsize = [0.1, 0.1, 0.1]
	
	for i = 1 to 64 do ReadByte f --rotation matrix	
	local boneId = ReadLong f

	-- print ("Bone: " + mobj.name)

	AddToBoneLayer nnode

	sbones += 1
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
			mat.delegate.diffuseMapEnable = (bit.get flags 19)

			mat.useColoring = (bit.get flags 28)
			mat.useMips = (bit.get flags 24)
			mat.delegate.twoSided = (bit.get flags 29)
			mat.isAnimatedM = (bit.get flags 27)

			--Environment Map
			mat.delegate.reflectionMapEnable = (bit.get flags 20)

			mat.envOverlay = (bit.get flags 9)
			mat.envMultiply = (bit.get flags 10)
			mat.envAdditive = (bit.get flags 11)
			mat.YProj = (bit.get flags 13)
			mat.YDetail = (bit.get flags 14)
			mat.ZDetail = (bit.get flags 15)

			--Additional Effect
			mat.addEffect = (bit.get flags 16)
			mat.delegate.opacityMapEnable = (bit.get flags 31)
			--mat.useAlphaMap = (bit.get flags 31)
			mat.useColorKey = (bit.get flags 30)
			mat.useAddBlend = (bit.get flags 32)

			mat.delegate.ambient = ReadColor f
			mat.delegate.diffuse = ReadColor f
			mat.delegate.selfIllumColor = ReadColor f
			mat.delegate.opacity = (ReadFloat f)*100

			if mat.delegate.reflectionMapEnable then (
				mat.delegate.reflectionMapAmount = (ReadFloat f)*100
				local envMapName = ReadText f 
				local envMap = bitmaptex()
				envMap.filename = envMapName
				mat.delegate.reflectionMap = envMap;
			)

			local diffMapName = ReadText f
			if diffMapName != undefined then (
				local diffMap = bitmaptex()
				diffMap.filename = diffMapName
				mat.delegate.diffuseMap = diffMap;
				showTextureMap mat on
			)

			if mat.delegate.opacityMapEnable then (
				local alphaMapName = ReadText f
				local alphatex = bitmaptex()
				alphatex.filename = alphaMapName
				mat.delegate.opacityMap = alphatex;
			)

			if mat.isAnimatedM then (
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

	-- if MafiaTools.importNormals.checked == true then (
	-- 	percent = 20.0 / numObjects
	-- )
	-- else (
	-- 	percent = 100.0 / numObjects
	-- )	

	for i = 0 to numObjects - 1 do
	(
		local objectType = ReadByte f
		local visualType
		local renderFlags = 0

		if objectType == 1 do --visual object
		(
			visualType = ReadByte f
			renderFlags = ReadShort f
		)
		--general block

		nnode = 0
		local mobj = ReadBaseObject f
		
		if objectType == 1 then  --VISUAL OBJECT
		(
			if visualType == 0 then ReadStandardMesh f mobj
			if visualType == 2 then (
				ReadSingleMesh f mobj;
				--print ("SingleMesh: " + mobj.name)
			)
			if visualType == 3 then (
				ReadSingleMorph f mobj
				--print ("SingleMorph: " + mobj.name)
			)
			if visualType == 4 then ReadBillboard f mobj
			if visualType == 5 then (
				ReadMorph f mobj; 
				--print ("Morph: " + mobj.name)
			)
			if visualType == 6 then ReadGlow f mobj
			if visualType == 8 then ReadMirror f mobj
		)
		if objectType == 5 then ReadSector f mobj
		if objectType == 6 then ReadDummy f mobj
		if objectType == 7 then ReadTarget f mobj
		if objectType == 10 then ReadBone f mobj

		--print ("Handle: " + (nnode.inode.handle as string))

		nnode.name = mobj.name
		nnode.parent = mobj.parent

		ApplyTransform nnode mobj


		modf = MafObject4()
		modf.renderFlags = renderFlags
		modf.cullFlags = mobj.cullFlags
		if mobj.userParams != undefined then modf.userParams = mobj.userParams
		--addmodifier nnode modf before:(nnode.modifiers.count)
		addmodifier nnode modf

		append mnodes nnode

		--progress += percent
		--if mod i 50 == 0 then progressUpdate progress
	)
)

fn ImportNormals = (
	-- percent = 80.0 / n_mesh_array.count

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
		
		
		--progress += percent
		--if mod i 50 == 0 then progressUpdate progress
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
		if MafiaTools.editName.text == "" then (
			MafiaTools.editName.text = getFilenameFile file			
		)
		
		filename = getFilenameFile file

		format "importing: %\n" file
		local start = timeStamp()		

		gc light:true

		local used_start = (heapsize - heapfree) / 1024.0

		with redraw off (
			--progressStart "4ds importing"

			mnodes = #()

			f = fopen file "rb"

			ReadHeader f
			ReadMaterials f	
			ReadObjects f

			if MafiaTools.importNormals.checked == true then (
				ImportNormals()			
			)

			fclose f		

			--progressEnd()

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