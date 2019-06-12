--4ds importer plugin for 3dsmax by Mr F



utility MafiaImport "4DS Import v4.1"
(
	local Mafia_Material
	local Mafia_Object
	local nmesh
	local godMat
	local lod_layers
	local dummy_layer
	local sector_layer
	local portal_layer
	local cyp

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
		p3 = point3 x y z
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
		godmat.name = "MAFIA_MATERIALS"

		for m=1 to numMats do
		(
			mat = MafMat()
			mat.name = "4DSMat"+(m as string)

			flags = ReadLong f

			HasEnv = ((bit.get flags 20) or (bit.get flags 9))
			HasAlpha = (bit.get flags 31)
			Anim = (bit.get flags 27)
			Mask = (bit.get flags 30)

			mat.useMips = (bit.get flags 24)
			mat.useAddBlend = (bit.get flags 32)
			mat.useAddRefl = (bit.get flags 11)
			mat.diffReflAxis = (bit.get flags 13)
			mat.useColorKey = (bit.get flags 30)
			mat.useAnim = (bit.get flags 27)
			mat.useAnimAlpha = (bit.get flags 26)


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

			if HasEnv==true do
			(
				mat.delegate.reflectionMapEnable=true
				mat.delegate.reflectionMapAmount = (ReadFloat f)*100
				nameLength = readbyte f
				envMapName = readtext f namelength
				envtex = bitmaptex()
				envtex.filename = envMapName
				mat.delegate.reflectionMap = envtex;
				--MessageBox (envMapName)
			)

			diffMapNameLength = readbyte f
			if diffMapNameLength!=0 do
			(
				mat.delegate.diffuseMapEnable=true
				diffMapName=readtext f diffMapNameLength
				diffMap = bitmaptex()
				diffMap.filename = diffMapName
				mat.delegate.diffuseMap = diffMap;
				showTextureMap mat on
			)

			if HasAlpha==true do
			(
				mat.delegate.opacityMapEnable=true
				alphaMapNameLength = readbyte f
				alphaMapName=readtext f alphaMapNameLength
				alphatex = bitmaptex()
				alphatex.filename = alphaMapName
				mat.delegate.opacityMap = alphatex;
			)

			if Anim==true do
			(
				--for bb=1 to 18 do
				--(
				--	readbyte f
				--)
				mat.animFrames = ReadLong f
				ReadShort f
				mat.animDelay = ReadLong f
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
					append verts_array [vert.x, vert.z, vert.y]

					normal = ReadPoint3 f
					append normals_array (point3 normal.x normal.z normal.y)

					uv = ReadPoint2 f
					append tverts_array [uv.x, 1-uv.y, 0]
				)


				numFacegroups = readbyte f #unsigned

				--mult = MultiMaterial()
				--mult.numsubs=numFacegroups

				material_array = #()

				totalCount = 1
				for i = 1 to numFacegroups do (

					numFaces = readshort f #unsigned
					for j = 1 to numFaces do (
						a = readshort f #unsigned
						b = readshort f #unsigned
						c = readshort f #unsigned

						append faces_array [a+1, c+1, b+1]	--face vertex indexes are 1-based in 3ds Max
						--append material_array i
						--setFaceMatID nmesh totalCount i
						totalCount = totalCount + 1
					)
					matnum = (ReadShort f)

					for j = 1 to numFaces do (
						append material_array (matnum+1)	-- coz 'nomaterial' is 0 in mafia, but 1 in max
					)
				)

				--nmesh = mesh vertices:verts_array faces:faces_array tverts:tverts_array
				nmesh = mesh vertices:verts_array faces:faces_array materialIDs:material_array tverts:tverts_array


				--setting normals for some reason crashes 3ds max
				--for i = 1 to verts_count do
				--(
				--	normal = normals_array[i]
				--	setNormal nmesh i normal
				--)

				buildTVFaces nmesh

				for i = 1 to nmesh.numfaces do (
					--id = material_array[i]
					--print ("** face id: " + (i as string) + " -- mat id: " + id as string)
					--setFaceMatID nmesh i id
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

				/*
				if numLods > 1 then (
					nmesh.name = mobj._name+"_LOD"+((l-1) as string)
				)
				else (
					nmesh.name = mobj._name
				)*/

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


				/*
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
						mesh_norm.setnormal n normals_array[v]
					)
				)*/

				lmod = MafLOD()
				--lmod.lodNum = (l-1)
				lmod.lodDist = clippingRange

				--if l > 1 then (
				--	lmod.lodMesh = nmesh
				--)

				addmodifier nmesh lmod

				--if l > 1 then (
				--	lsmod = MafSubtype()
				--	lsmod.subtypeName = "LOD"
				--	addmodifier nmesh lsmod
				--)


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
			append verts_array [p3.x, p3.z, p3.y]
		)

		for i = 1 to numFaces do (
			p3 = ReadPoint3 f      --face vertex index
			append faces_array [p3.x, p3.z, p3.y]
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

		nmesh.boxsize=[(abs (dmin.x-dmax.x)),(abs (dmin.z-dmax.z)),(abs (dmin.y-dmax.y))]
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
			append verts_array [vert.x, vert.z, vert.y]
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
				setVert pmesh cc vert.x vert.z vert.y
				append vertIds_array cc
			)

			p = convertToPoly pmesh

			polyop.createPolygon p vertIds_array

			--verts_list = #()
			--for cc=1 to p.numVerts do
			--(
			--	append verts_list (p.verts)
			--)
			--result = polyop.capHolesByVert p p.verts
			--print (result as string)

			p.wirecolor = (color 255 0 199)


			if portal_layer == undefined then portal_layer = LayerManager.newLayerFromName "Portals"
			portal_layer.addnode p


			--modp = MafSubtype()
			--modp.subtypeName = "Portal"
			--addmodifier pmesh modp

			modpp = MafPortal()
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


		pos = ReadPoint3 f
		mobj._offset = point3 pos.x pos.z pos.y

		scl = ReadPoint3 f
		mobj._scale = point3 scl.x scl.z scl.y

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

	button btn "Import" pos:[55,10] width:50

	on btn pressed do
	(

		file=GetOpenFileName types:"4DS models (*.4ds)|*.4ds|All files (*.*)|*.*"
		if file!=undefined do
		(

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

			objs = ReadShort f
			for o=1 to objs do
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

				print (" ****** " + mobj._name)

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


				modf = MafObject()
				modf.subtypeName = cyp
				modf.renderFlags = renderFlags
				modf.cullFlags = mobj._cullingFlags
				modf.userParams = mobj._params
				addmodifier nmesh modf before:(nmesh.modifiers.count)

				append Mafia_Object nmesh
			)


			--MessageBox ("Last object: "+meshname+" ends at "+((ftell f) as string))
			fclose f

		)
	)
)