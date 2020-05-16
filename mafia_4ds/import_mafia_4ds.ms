(

--local Mafia_Material
local Mafia_Object
local nnode
local godmat
local lod_layers
local dummy_layer
local sector_layer
local portal_layer
local bone_layer
local glow_layer

fn ReadText f _length = (
	local result = ""
	for i = 1 to _length do (
		result += bit.intAsChar(readByte f)
	)
	result
)

fn ReadPoint3 f = (
	x = ReadFloat f
	y = ReadFloat f
	z = ReadFloat f
	p3 = point3 x z y
	p3
)

fn ReadPoint2 f = (
	x = ReadFloat f
	y = ReadFloat f
	p2 = point2 x y
	p2
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
	_parentID,
	_offset,
	_scale,
	_rotation,
	_cullingFlags,
	_name,
	_params
)


fn ReadBaseObject f = (
	mobj = MObject()

	parentID = ReadShort f
	if parentID < 0 do parentID = 0
	if parentID > 0 do parentID = Mafia_Object[parentID]
	mobj._parentID = parentID


	mobj._offset = ReadPoint3 f
	mobj._scale = ReadPoint3 f
	
	mobj._rotation = ReadQuat f

	mobj._cullingFlags = ReadByte f #unsigned

	nameLength = ReadByte f #unsigned
	mobj._name = ReadText f nameLength

	paramsLength = ReadByte f #unsigned
	mobj._params = ReadText f paramsLength


	mobj
)

fn ApplyTransform nnode mobj = (

	pos = mobj._offset
	scaletion = mobj._scale
	rotation = mobj._rotation
	parentID = mobj._parentID
	matrix = matrix3 [1, 0, 0] [0, 1, 0] [0, 0, 1] [pos.x, pos.y, pos.z]
	sclMatrix = matrix3 [scaletion.x, 0, 0] [0, scaletion.y, 0] [0, 0, scaletion.z] [0, 0, 0]
	rotMatrix = ((inverse rotation) as matrix3)

	if parentID != 0 then
	(
		nnode.transform = (sclMatrix*rotMatrix*matrix*nnode.parent.transform)
	)
	else (
		nnode.transform = (sclMatrix*rotMatrix*matrix)
	)
)

n_mesh_array = #()
n_normal_array = #()

sstandardmeshes = 0
fn ReadStandardMesh f mobj = (
	duplicateID = ReadShort f
	if duplicateID != 0 then
	(
		nnode = reference Mafia_Object[duplicateID]
	)
	else
	(
		numLods = ReadByte f

		if numLods == 0 then (
			nnode = editable_mesh()
		)

		for lodId = 0 to numLods - 1 do
		(
			clippingRange = ReadFloat f  --clipping range

			verts_array = #()
			normals_array = #()
			tverts_array = #()
			faces_array = #()

			numVerts = readshort f #unsigned

			for i = 1 to numVerts do
			(
				vert = ReadPoint3 f
				append verts_array [vert.x, vert.y, vert.z]

				normal = ReadPoint3 f
				append normals_array [normal.x, normal.y, normal.z]

				uv = ReadPoint2 f
				append tverts_array [uv.x, 1-uv.y, 0]
			)


			numFacegroups = readbyte f #unsigned

			material_array = #()

			matidOrder = #()

			totalCount = 1
			for i = 1 to numFacegroups do (

				numFaces = readshort f #unsigned

				for j = 1 to numFaces do (
					a = readshort f #unsigned
					b = readshort f #unsigned
					c = readshort f #unsigned

					append faces_array [a+1, c+1, b+1]	--face vertex indexes are 1-based in 3ds Max

					totalCount = totalCount + 1
				)
				matnum = (ReadShort f)
				append matidOrder (matnum+1)

				for j = 1 to numFaces do (
					append material_array (matnum+1)	-- coz 'material_none' is 0 in mafia, but 1 in max
				)
			)

			lmesh = mesh vertices:verts_array faces:faces_array materialIDs:material_array tverts:tverts_array

			buildTVFaces lmesh
			for i = 1 to lmesh.numfaces do (
				setTVFace lmesh i (getFace lmesh i)
				setFaceSmoothGroup lmesh i 1
			)

			lmesh.wirecolor = color 0 0 0


			if lodId == 0 then (
				nnode = lmesh
			)
			else (
				lmesh.name = "$lod" + (lodId as string) + "__" + mobj._name
				lmesh.parent = nnode
				--ApplyTransform lmesh mobj
			)

			if numLods > 1 then (
				local layer = lod_layers[lodId+1]

				if layer == undefined then (
					layer = LayerManager.newLayerFromName ("LOD" + (lodId as string) + " LAYER")
					append lod_layers layer
				)
				layer.addnode lmesh

				if lodId >= 1 then layer.ishidden = true
			)		


			lmod = MafLod4()
			lmod.matidOrder = matidOrder
			lmod.lodDist = clippingRange
			lmod.dontOptimize = true			
			addmodifier lmesh lmod

			lmesh.material = godmat

			append n_mesh_array lmesh
			append n_normal_array normals_array
		)
	)

	sstandardmeshes += 1
)

ssinglemeshes = 0
fn ReadSingleMesh f mobj = (
	ReadStandardMesh f mobj
	sstandardmeshes -= 1

	bones=ReadByte f
	ReadLong f

	dmin = ReadPoint3 f
	dmax = ReadPoint3 f

	for bo=1 to bones do
	(
		for b=1 to 64 do
		(
			--rotation matrix
			ReadByte f
		)
		ReadLong f
		numfloats=ReadLong f
		numbone=ReadLong f

		dmin = ReadPoint3 f
		dmax = ReadPoint3 f

		for b=1 to numfloats do
		(
			ReadFloat f
		)
	)

	ssinglemeshes += 1
)

fn ReadBaseMorph f mobj = (
	-- morph
	morphPoses = ReadByte f
	morphVGroups = ReadByte f
	ReadByte f

	for m = 1 to morphVGroups do
	(
		morphedVerts = ReadShort f

		for bb=1 to (morphPoses*morphedVerts) do
		(
			-- morph bounds
			smin = ReadPoint3 f
			smax = ReadPoint3 f
		)

		ReadByte f

		for bb=1 to morphedVerts do
		(
			ReadShort f -- vertex numbers
		)
	)

	-- min/max
	dmin = ReadPoint3 f
	dmax = ReadPoint3 f

	v = ReadPoint3 f 	-- ?

	vvv = ReadFloat f	-- ?
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
	ReadByte f   --axis
	ReadByte f
	ReadByte f
	ReadByte f
	ReadByte f   --axis mode

	--print ("Billboard: " + mobj._name)

	sbillboards += 1
)

sglows = 0
fn ReadGlow f mobj = (

	numGlows = ReadByte f
	for i = 1 to numGlows do
	(
		position = ReadFloat f
		matID = ReadShort f
	)

	--nnode=dummy()

	nnode = point()
	nnode.constantscreensize = true
	nnode.box = true

	--nnode.boxsize=[1,1,1]
	if glow_layer == undefined then glow_layer = LayerManager.newLayerFromName "Glows"
	glow_layer.addnode nnode

	--print ("Glow (numGlows: " + (numGlows as string) + "): " + mobj._name)

	sglows += 1
)

smirrors = 0
fn ReadMirror f mobj = (

	minBox = ReadPoint3 f
	maxBox = ReadPoint3 f

	for i = 1 to 4 do unknown = ReadFloat f
	for i = 1 to 16 do reflectionMatrix = ReadFloat f
	
	backColor = ReadColor f
	drawDistance = ReadFloat f

	numVerts = ReadLong f
	numFaces = ReadLong f

	verts_array = #()
	faces_array = #()

	for i = 1 to numVerts do (
		p3 = ReadPoint3 f
		append verts_array [p3.x, p3.y, p3.z]
	)

	for i = 1 to numFaces do (
		a = readshort f #unsigned
		b = readshort f #unsigned
		c = readshort f #unsigned

		append faces_array [a+1, c+1, b+1]	--face vertex indexes are 1-based in 3ds Max
	)

	nnode = mesh vertices:verts_array faces:faces_array

	--print ("Mirror: " + mobj._name)

	smirrors += 1
)

sdummies = 0
fn ReadDummy f mobj = (
	nnode = dummy()

	dmin = ReadPoint3 f
	dmax = ReadPoint3 f

	nnode.boxsize = [(abs (dmin.x-dmax.x)), (abs (dmin.y-dmax.y)), (abs (dmin.z-dmax.z))]


	if dummy_layer == undefined then dummy_layer = LayerManager.newLayerFromName "Dummies"
	dummy_layer.addnode nnode

	hide nnode

	sdummies += 1
)

ssectors = 0
fn ReadSector f mobj = (
	ReadLong f --always 2049
	ReadLong f --always 0


	verts = ReadLong f
	faces = ReadLong f


	verts_array = #()
	faces_array = #()

	for i = 1 to verts do (
		vert = ReadPoint3 f
		append verts_array [vert.x, vert.y, vert.z]
	)

	for i = 1 to faces do (
		a = readshort f #unsigned
		b = readshort f #unsigned
		c = readshort f #unsigned
		append faces_array [a+1, c+1, b+1] --vertex indexes in face are counted from 1 in 3ds Max
	)

	nnode = mesh vertices:verts_array faces:faces_array

	if sector_layer == undefined then sector_layer = LayerManager.newLayerFromName "Sectors"
	sector_layer.addnode nnode

	nnode.wirecolor = (color 255 199 0)

	dmin = ReadPoint3 f
	dmax = ReadPoint3 f

	portals_array = #()

	numPortals = ReadByte f
	for bb=1 to numPortals do
	(
		numVerts = readbyte f
		readlong f  --always 4
		readlong f
		readlong f
		readlong f
		readlong f  --flags?

		nearRange = readfloat f
		farRange = readfloat f

		pmesh = mesh numverts:numVerts numfaces:10
		pmesh.name = "$portal" + ((bb-1) as string) + "__" + mobj._name
		--pmesh.name = mobj._name+"__PORTAL"+(bb as string)

		vertIds_array = #()

		for cc=1 to numVerts do
		(
			vert = ReadPoint3 f
			setVert pmesh cc vert.x vert.y vert.z
			append vertIds_array cc
		)

		p = convertToPoly pmesh

		polyop.createPolygon p vertIds_array


		p.wirecolor = (color 255 0 199)


		if portal_layer == undefined then portal_layer = LayerManager.newLayerFromName "Portals"
		portal_layer.addnode p

		modpp = MafPortal4()
		modpp.nearRange = nearRange
		modpp.farRange = farRange
		addmodifier p modpp


		p.parent = nnode

		append portals_array p
	)

	--group portals_array name:"PORTALS"

	-- print ("Sector: " + mobj._name)

	ssectors += 1
)

stargets = 0
fn ReadTarget f mobj = (
	nnode = dummy()
	nnode.boxsize = [0.1, 0.1, 0.1]

	unk0 = ReadByte f
	unk1 = ReadByte f
	numLinks = ReadByte f

	-- print ("Target: " + mobj._name)
	-- print ("  unk0: " + (unk0 as string))
	-- print ("  unk1: " + (unk1 as string))
	-- print ("  numLinks: " + (numLinks as string))


	for i = 1 to numLinks do
	(
		linkId = ReadShort f
		-- print ("  linkId: " + (linkId as string) + " - " + Mafia_Object[linkid].name)
	)

	

	stargets += 1
)

sbones = 0
fn ReadBone f mobj = (
	nnode = bone()
	
	for i = 1 to 64 do
	(
		--rotation matrix
		ReadByte f
	)
	boneId = ReadLong f

	-- print ("Bone: " + mobj._name)

	if bone_layer == undefined then bone_layer = LayerManager.newLayerFromName "Bones"
	bone_layer.addnode nnode

	sbones += 1
)

fn ReadHeader f = (
	fourcc = ReadLong f
	version = ReadShort f
	if version != 29 then MessageBox "Unknown 4DS version - importing might not work correctly"
	timestamp = ReadLongLong f
)

smaterials = 0
fn ReadMaterials f = (

	numMats = ReadShort f
	smaterials = numMats
	
	if numMats > 0 then (
		numsubs = numMats + 1
		godmat = multimaterial numsubs:numsubs
		godmat[1] = undefined
		godmat.name = "$MAFIA_MATERIALS"
	

		for m = 2 to numsubs do
		(
			mat = MafMat4()
			mat.name = "4DSMat"+(m as string)

			flags = ReadLong f

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

			if mat.delegate.reflectionMapEnable == true do
			(
				mat.delegate.reflectionMapAmount = (ReadFloat f)*100
				nameLength = readbyte f
				envMapName = readtext f namelength
				envMap = bitmaptex()
				envMap.filename = envMapName
				mat.delegate.reflectionMap = envMap;
			)

			diffMapNameLength = readbyte f
			if diffMapNameLength != 0 do
			(
				diffMapName = readtext f diffMapNameLength
				diffMap = bitmaptex()
				diffMap.filename = diffMapName
				mat.delegate.diffuseMap = diffMap;
				showTextureMap mat on
			)

			if mat.delegate.opacityMapEnable == true do
			(
				alphaMapNameLength = readbyte f
				alphaMapName=readtext f alphaMapNameLength
				alphatex = bitmaptex()
				alphatex.filename = alphaMapName
				mat.delegate.opacityMap = alphatex;
			)

			if mat.isAnimatedM == true do
			(
				--for bb=1 to 18 do
				--(
				--	readbyte f
				--)
				mat.animFrames = ReadLong f
				ReadShort f
				mat.animPeriod = ReadLong f
				ReadLong f
				ReadLong f
			)


			godmat[m] = mat
			--append Mafia_Material mat
			--b = box()
			--b.material=mat
		)
	)
)

progress = 0
sobjects = 0
fn ReadObjects f = (
	sector_layer = LayerManager.getLayerFromName "Sectors"
	portal_layer = LayerManager.getLayerFromName "Portals"
	dummy_layer = LayerManager.getLayerFromName "Dummies"

	lod_layers = #()

	numObjects = ReadShort f

	sobjects = numObjects

	-- if MafiaTools.importNormals.checked == true then (
	-- 	percent = 20.0 / numObjects
	-- )
	-- else (
	-- 	percent = 100.0 / numObjects
	-- )	

	for i = 0 to numObjects - 1 do
	(
		objectType = ReadByte f
		local visualType
		local renderFlags = 0

		if objectType == 1 do --visual object
		(
			visualType = ReadByte f
			renderFlags = ReadShort f
		)
		--general block

		nnode = 0
		mobj = ReadBaseObject f
		
		if objectType == 1 then  --VISUAL OBJECT
		(
			if visualType == 0 then ReadStandardMesh f mobj
			if visualType == 2 then (
				ReadSingleMesh f mobj;
				--print ("SingleMesh: " + mobj._name)
			)
			if visualType == 3 then (
				ReadSingleMorph f mobj
				--print ("SingleMorph: " + mobj._name)
			)
			if visualType == 4 then ReadBillboard f mobj
			if visualType == 5 then (
				ReadMorph f mobj; 
				--print ("Morph: " + mobj._name)
			)
			if visualType == 6 then ReadGlow f mobj
			if visualType == 8 then ReadMirror f mobj
		)
		if objectType == 5 then ReadSector f mobj
		if objectType == 6 then ReadDummy f mobj
		if objectType == 7 then ReadTarget f mobj
		if objectType == 10 then ReadBone f mobj

		--print ("Handle: " + (nnode.inode.handle as string))

		nnode.name=mobj._name
		if mobj._parentID!=0 do nnode.parent=mobj._parentID
		ApplyTransform nnode mobj


		modf = MafObject4()
		--modf.subtypeName = cyp
		modf.renderFlags = renderFlags
		modf.cullFlags = mobj._cullingFlags
		modf.userParams = mobj._params
		--addmodifier nnode modf before:(nnode.modifiers.count)
		addmodifier nnode modf

		append Mafia_Object nnode

		--progress += percent
		--if mod i 50 == 0 then progressUpdate progress
	)
)

fn ImportNormals = (
	-- percent = 80.0 / n_mesh_array.count

	max modify mode
	select n_mesh_array

	norm = Edit_Normals()
	modpanel.addmodtoselection norm

	--print (n_mesh_array.count as string)
	--print (n_normal_array.count as string)

	disableRefMsgs()  --makes a huge difference, 41 seconds with vs. 904 seconds without
	for i = 1 to n_mesh_array.count do
	(
		--print (n_normal_array[i].count as string)
		p = n_mesh_array[i]

		pn = n_normal_array[i]
		
		for i = 1 to p.numverts do
		(
			my_verts = #{i} --define a bitArray specifying vertex 1
			my_normals = #{} --define an empty bitArray to store the result
			--call the method with the two bitArrays passed by-reference:
			norm.ConvertVertexSelection &my_verts &my_normals node:p
			n = (my_normals as array)[1]
			--norm.SetNormalExplicit n node:p
			norm.setnormal n pn[i] node:p
		)

		my_verts = #{1..p.numverts}
		my_normals = #{}
		norm.ConvertVertexSelection &my_verts &my_normals node:p
		norm.MakeExplicit selection:my_normals node:p
		
		
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
	local file = getOpenFileName types:"4DS models (*.4ds)|*.4ds|All files (*.*)|*.*"
	if file != undefined do
	(
		local start = timeStamp()

		with redraw off (
			--progressStart "4ds importing"

			--Mafia_Material = #()
			Mafia_Object = #()

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

		local message = "Importing took " + (dur as string) + " seconds"
		format message
		messageBox message
	)
)
Main()

)
