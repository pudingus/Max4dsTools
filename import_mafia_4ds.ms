--4ds importer plugin for 3dsmax by Mr F




Mafia_Material
Mafia_Object
nmesh
godMat
lod_layers
dummy_layer
sector_layer
portal_layer
cyp

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

fn ReadHeader f = (
	fourcc = ReadLong f
	version = ReadShort f
	if version!=29 do MessageBox "Unknown 4DS version - importing might not work correctly"
	timestamp = ReadLongLong f
)

fn ReadMats f numMats = (

	numsubs = numMats + 1
	godMat = multimaterial numsubs:numsubs
	godmat[1] = undefined
	godmat.name = "$MAFIA_MATERIALS"

	for m=1 to numMats do
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



		mat.delegate.ambient.red = (ReadFloat f)*255
		mat.delegate.ambient.green = (ReadFloat f)*255
		mat.delegate.ambient.blue = (ReadFloat f)*255
		mat.delegate.diffuse.red = (ReadFloat f)*255
		mat.delegate.diffuse.green = (ReadFloat f)*255
		mat.delegate.diffuse.blue = (ReadFloat f)*255
		mat.delegate.selfIllumColor.red = (ReadFloat f)*255
		mat.delegate.selfIllumColor.green = (ReadFloat f)*255
		mat.delegate.selfIllumColor.blue = (ReadFloat f)*255
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


		godMat[m+1] = mat
		append Mafia_Material mat
		--b = box()
		--b.material=mat
	)

)

fn ApplyTransform nmesh mobj = (

	pos = mobj._offset
	scaletion = mobj._scale
	rotation = mobj._rotation
	parentID = mobj._parentID
	matrix = matrix3 [1, 0, 0] [0, 1, 0] [0, 0, 1] [pos.x, pos.y, pos.z]
	sclMatrix = matrix3 [scaletion.x, 0, 0] [0, scaletion.y, 0] [0, 0, scaletion.z] [0, 0, 0]
	rotMatrix = ((inverse rotation) as matrix3)

	if parentID != 0 then
	(
		nmesh.transform = (sclMatrix*rotMatrix*matrix*nmesh.parent.transform)
	)
	else (
		nmesh.transform = (sclMatrix*rotMatrix*matrix)
	)
)

matidOrder = #()

fn ReadStandardMesh f mobj = (
	duplicateID = ReadShort f
	local baseMesh
	if duplicateID != 0 then --MessageBox "Duplicate!"
	(
		--MessageBox "Duplicate!"
		nmesh = reference Mafia_Object[duplicateID]
		--ApplyTransformations nmesh mobj._parentID pos scaletion rotation
		ApplyTransform nmesh mobj
		baseMesh = nmesh
	)
	else
	(
		numLods = ReadByte f


		for l=1 to numLods do
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

			--mult = MultiMaterial()
			--mult.numsubs=numFacegroups

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
					append material_array (matnum+1)	-- coz 'nomaterial' is 0 in mafia, but 1 in max
				)
			)



			nmesh = mesh vertices:verts_array faces:faces_array materialIDs:material_array tverts:tverts_array


			buildTVFaces nmesh

			for i = 1 to nmesh.numfaces do (
				setTVFace nmesh i (getFace nmesh i)
			)



			nmesh.wirecolor = color 0 0 0


			if mobj._parentID!=0 do nmesh.parent=mobj._parentID

			if l == 1 then (
				baseMesh = nmesh
				nmesh.name = mobj._name

			)
			if l > 1 then (
				nmesh.name = "$lod" + ((l-1) as string) + "__" + mobj._name
				--nmesh.name = mobj._name+"__LOD"+((l-1) as string)
				--hide nmesh

			)

			if numLods > 1 then (
				if lod_layers[l] == undefined then (
					layer = LayerManager.newLayerFromName ("LOD" + ((l-1) as string) + " LAYER")
					layer.addnode nmesh
					append lod_layers layer

				)
				else (
					layer = lod_layers[l]
					layer.addnode nmesh
				)
				if l > 1 then layer.ishidden = true
			)



			ApplyTransform nmesh mobj

			if l > 1 then
				nmesh.parent = baseMesh




			if MafiaTools.importNormals.checked == true then (
				-- Create an edit_normals modifier
				-- (because setting them with setnormal() doesn't seem to work...)
				mesh_norm = edit_normals()
				addmodifier nmesh mesh_norm
				max modify mode
				modpanel.setcurrentobject mesh_norm
				for i = 1 to nmesh.numfaces do
				(
					for j in 1 to 3 do
					(
						local n = mesh_norm.getnormalid i j
						local v = mesh_norm.getvertexid i j
						--mesh_norm.SetFaceNormalSpecified i j
						mesh_norm.SetNormalExplicit n
						mesh_norm.setnormal n normals_array[v]
					)
				)
			)

			lmod = MafLod4()
			lmod.matidOrder = matidOrder
			lmod.lodDist = clippingRange

			addmodifier nmesh lmod

			print (matidOrder as string)


			nmesh.material = godMat
		)
	)
	--cyp = "Mesh"
	baseMesh
)

fn ReadSingleMesh f mobj = (
	nmesh=ReadStandardMesh f mobj

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
	--cyp = "SingleMesh"
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

fn ReadSingleMorph f mobj = (
	ReadSingleMesh f mobj
	ReadBaseMorph f mobj
	--cyp = "SingleMorph"
)

fn ReadMorph f mobj = (
	nmesh=ReadStandardMesh f mobj
	ReadBaseMorph f mobj
	--cyp = "Morph"
)

fn ReadBillboard f mobj = (
	nmesh=ReadStandardMesh f
	ReadByte f   --axis
	ReadByte f
	ReadByte f
	ReadByte f
	ReadByte f   --axis mode
	--cyp = "Billboard"
)

fn ReadGlow f mobj = (

	b = ReadByte f
	for bb=1 to b do
	(
		ReadFloat f
		ReadShort f
	)

	nmesh=dummy()
	if mobj._parentID!=0 do nmesh.parent=mobj._parentID
	nmesh.boxsize=[1,1,1]
	nmesh.name = mobj._name

	ApplyTransform nmesh mobj
	--cyp = "Glow"
)

fn ReadMirror f mobj = (

	for bb=1 to 30 do
	(
		ReadFloat f
	)

	numVerts=ReadLong f
	numFaces=ReadLong f
	verts_array = #()
	faces_array = #()

	for i = 1 to numVerts do (
		p3 = ReadPoint3 f
		append verts_array [p3.x, p3.y, p3.z]
	)

	for i = 1 to numFaces do (
		p3 = ReadPoint3 f      --face vertex index
		append faces_array [p3.x, p3.y, p3.z]
	)

	nmesh = mesh vertices:verts_array faces:faces_array
	nmesh.name = mobj._name
	if mobj._parentID!=0 do nmesh.parent=mobj._parentID

	ApplyTransform nmesh mobj
	--cyp = "Mirror"
)

fn ReadDummy f mobj = (
	nmesh=dummy()
	if mobj._parentID!=0 do nmesh.parent=mobj._parentID

	dmin = ReadPoint3 f
	dmax = ReadPoint3 f

	nmesh.boxsize=[(abs (dmin.x-dmax.x)),(abs (dmin.y-dmax.y)),(abs (dmin.z-dmax.z))]
	nmesh.name = mobj._name

	ApplyTransform nmesh mobj


	if dummy_layer == undefined then dummy_layer = LayerManager.newLayerFromName "Dummies"
	dummy_layer.addnode nmesh

	hide nmesh
	--cyp = "Dummy"
)

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

	nmesh = mesh vertices:verts_array faces:faces_array
	nmesh.name = mobj._name
	if mobj._parentID != 0 do nmesh.parent=mobj._parentID


	ApplyTransform nmesh mobj

	if sector_layer == undefined then sector_layer = LayerManager.newLayerFromName "Sectors"
	sector_layer.addnode nmesh

	nmesh.wirecolor = (color 255 199 0)

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


		p.parent = nmesh

		append portals_array p
	)

	--group portals_array name:"PORTALS"

	cyp = "Sector"
)

fn ReadTarget f mobj = (
	nmesh=dummy()
	nmesh.name=mobj._name
	nmesh.boxsize=[1,1,1]
	if mobj._parentID!=0 do nmesh.parent=mobj._parentID

	ApplyTransform nmesh mobj

	ReadByte f
	ReadByte f
	bob=ReadByte f

	for b=1 to bob do
	(
		ReadShort f
	)
	--cyp = "Target"
)

fn ReadBone f mobj = (
	nmesh=dummy()
	nmesh.name=mobj._name
	nmesh.boxsize=[0.1,0.1,0.1]
	if mobj._parentID!=0 do nmesh.parent=mobj._parentID
	ApplyTransform nmesh mobj
	for b=1 to 64 do
	(
		--rotation matrix
		ReadByte f
	)
	ReadLong f
	--cyp = "Bone"
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

	rw = ReadFloat f
	rx = ReadFloat f
	ry = ReadFloat f
	rz = ReadFloat f
	mobj._rotation = quat rx rz ry rw

	mobj._cullingFlags = ReadByte f #unsigned

	nameLength = ReadByte f #unsigned
	mobj._name = ReadText f nameLength

	paramsLength = ReadByte f #unsigned
	mobj._params = ReadText f paramsLength


	mobj
)

fn setCommandPanelRedraw act =
(
	WM_SETREDRAW = 0x000B
	--windows.sendmessage (windows.getchildhwnd #max "Command Panel")[1] WM_SETREDRAW act 0

	--windows.sendmessage (windows.getMAXHWND()) WM_SETREDRAW act 0

	--windows.sendmessage (windows.getChildHWND #max "Command Panel")[1] WM_SETREDRAW act 0

)



------------------------
---------MAIN-----------
------------------------
--aaa()

file=GetOpenFileName types:"4DS models (*.4ds)|*.4ds|All files (*.*)|*.*"
if file!=undefined do
(
	progressStart "4ds importing"


	Mafia_Material = #()
	Mafia_Object = #()


	f = fopen file "rb"
	-- FILE START
	ReadHeader f

	-- MATERIALS
	numMats = ReadShort f
	ReadMats f numMats


	--OBJECTS

	sector_layer = LayerManager.getLayerFromName "Sectors"
	portal_layer = LayerManager.getLayerFromName "Portals"
	dummy_layer = LayerManager.getLayerFromName "Dummies"

	lod_layers = #()

	numObjects = ReadShort f

	percent = 100.0 / numObjects
	progress = 0

	with redraw off (
		--setCommandPanelRedraw 0
		--disableRefMsgs()



	for o=1 to numObjects do
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

		nmesh = 0

		mobj = ReadBaseObject f

		--print (" ****** " + mobj._name)

		cyp = ""

		--VISUAL OBJECT
		if objectType == 1 do
		(
			if visualType == 0 do nmesh=ReadStandardMesh f mobj
			if visualType == 2 do ReadSingleMesh f mobj
			if visualType == 3 do ReadSingleMorph f mobj
			if visualType == 4 do ReadBillboard f mobj
			if visualType == 5 do ReadMorph f mobj
			if visualType == 6 do ReadGlow f mobj
			if visualType == 8 do ReadMirror f mobj
		)

		--SECTOR
		if objectType==5 do ReadSector f mobj

		--DUMMY
		if objectType==6 do ReadDummy f mobj

		--TARGET
		if objectType==7 do ReadTarget f mobj

		--BONE
		if objectType==10 do ReadBone f mobj



		--addModifier mesh (MafSubtype())

		--modf = MafSubtype()
		--modf.subtypeName = "Sektorrrr"
		--addmodifier mesh modf
		--print "kekrrrr"


		modf = MafObject4()
		modf.subtypeName = cyp
		modf.renderFlags = renderFlags
		modf.cullFlags = mobj._cullingFlags
		modf.userParams = mobj._params
		--addmodifier nmesh modf before:(nmesh.modifiers.count)
		addmodifier nmesh modf

		append Mafia_Object nmesh


		progress += percent
		progressUpdate progress
	)
	--enableRefMsgs()
	--setCommandPanelRedraw 1
	--completeredraw()


	)


	--MessageBox ("Last object: "+meshname+" ends at "+((ftell f) as string))
	fclose f

	progressEnd()


)
