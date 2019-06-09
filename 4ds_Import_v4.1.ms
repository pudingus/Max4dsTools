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

	fn ReadText f _length = (
		local result = ""
		for i = 1 to _length do (
			result += bit.intAsChar(readByte f)
		)
		result
	)

	fn ReadHeader f = (
		fourcc = ReadLong f
		version = ReadShort f
		if version!=29 do MessageBox "4DS version is not 29 - strange"
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
		matrix = matrix3 [scaletion.x, 0, 0] [0, scaletion.y, 0] [0, 0, scaletion.z] [pos.x, pos.y, pos.z]
		rotMatrix = ((inverse rotation) as matrix3)

		if parentID != 0 then
		(
			nmesh.transform = (rotMatrix*matrix*nmesh.parent.transform)
		)
		else (
			nmesh.transform = (rotMatrix*matrix)
		)
	)

	--parent local parent
	fn ApplyTransformations nmesh par pos scl rot = (
		if par != 0 then
		(
			in coordsys parent nmesh.pos = pos
			in coordsys local scale nmesh scl
			in coordsys parent rotate nmesh (rot*nmesh.parent.rotation)--(eulerangles rotation.x rotation.y rotation.z)
		)
		else
		(
			in coordsys world nmesh.pos = pos
			in coordsys world scale nmesh scl
			in coordsys world rotate nmesh rot
		)
	)

	--parent local world
	fn ApplyTransformations2 nmesh par pos scl rot = (
		if par != 0 then
		(
			in coordsys parent nmesh.pos = pos
			in coordsys local scale nmesh scl
			in coordsys world rotate nmesh (rot*nmesh.parent.rotation)--(eulerangles rotation.x rotation.y rotation.z)
		)
		else
		(
			in coordsys world nmesh.pos = pos
			in coordsys world scale nmesh scl
			in coordsys world rotate nmesh rot
		)
	)

	--parent parent parent     DUMMY
	fn ApplyTransformations3 nmesh par pos scl rot = (
		if par != 0 then
		(
			in coordsys parent nmesh.pos = pos
			in coordsys parent scale nmesh (scl*nmesh.parent.scale)
			in coordsys parent rotate nmesh (rot*nmesh.parent.rotation)--(eulerangles rotation.x rotation.y rotation.z)
		)
		else
		(
			in coordsys world nmesh.pos = pos
			in coordsys world scale nmesh scl
			in coordsys world rotate nmesh rot
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

				verts_count = readshort f #unsigned

				verts_array.count = verts_count
				--normals_array.count = verts_count
				tverts_array.count = verts_count

				for i = 1 to verts_count do
				(
					x = readfloat f; y = readfloat f; z = readfloat f
					norm_x = readfloat f; norm_y = readfloat f; norm_z = readfloat f
					u = readfloat f; v = readfloat f
					verts_array[i] = [x, z, y]

					p3 = point3 norm_x norm_z norm_y
					append normals_array p3
					tverts_array[i] = [u, 1-v, 0]
				)


				facegroups_count = readbyte f #unsigned

				--mult = MultiMaterial()
				--mult.numsubs=facegroups_count

				material_array = #()

				totalCount = 1
				for i = 1 to facegroups_count do (

					faces_count = readshort f #unsigned
					for j = 1 to faces_count do (
						a = readshort f #unsigned
						b = readshort f #unsigned
						c = readshort f #unsigned
						--vertex indexes in face are counted from 1 in 3ds Max
						append faces_array [a+1, c+1, b+1]
						--append material_array i
						--setFaceMatID nmesh totalCount i
						totalCount = totalCount + 1
					)
					matnum = (ReadShort f)

					for j = 1 to faces_count do (
						append material_array (matnum+1)
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
					nmesh.name = mobj._name+"__LOD"+((l-1) as string)
					hide nmesh
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
						layer = LayerManager.newLayerFromName ("LOD LAYER " + ((l-1) as string))
						layer.addnode nmesh
						append lod_layers layer
					)
					else (
						layer = lod_layers[l]
						layer.addnode nmesh
					)
				)




				--ApplyTransformations2 nmesh mobj._parentID pos scaletion rotation


				ApplyTransform nmesh mobj


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
				lmod.lodNum = (l-1)
				lmod.lodDist = clippingRange

				if l > 1 then (
					lmod.lodMesh = nmesh
				)

				addmodifier baseMesh lmod

				if l > 1 then (
					lsmod = MafSubtype()
					lsmod.subtypeName = "LOD"
					addmodifier nmesh lsmod
				)


				nmesh.material = godMat
			)
		)
		baseMesh
	)

	fn ReadSingleMesh f mobj = (
		nmesh=ReadStandardMesh f mobj

		bones=ReadByte f
		ReadLong f
		dminx = ReadFloat f
		dminy = ReadFloat f
		dminz = ReadFloat f
		dmaxx = ReadFloat f
		dmaxy = ReadFloat f
		dmaxz = ReadFloat f

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
			dminx = ReadFloat f
			dminy = ReadFloat f
			dminz = ReadFloat f
			dmaxx = ReadFloat f
			dmaxy = ReadFloat f
			dmaxz = ReadFloat f
			for b=1 to numfloats do
			(
				ReadFloat f
			)
		)
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
				sminx=ReadFloat f
				sminy=ReadFloat f
				sminz=ReadFloat f
				smaxx=ReadFloat f
				smaxy=ReadFloat f
				smaxz=ReadFloat f
			)

			ReadByte f

			for bb=1 to morphedVerts do
			(
				ReadShort f -- vertex numbers
			)
		)

		-- min/max
		dminx = ReadFloat f
		dminy = ReadFloat f
		dminz = ReadFloat f
		dmaxx = ReadFloat f
		dmaxy = ReadFloat f
		dmaxz = ReadFloat f

		vx = ReadFloat f
		vy = ReadFloat f
		vz = ReadFloat f
		vvv = ReadFloat f

		--ReadByte f
		--MessageBox ((ftell f) as string)
		--MessageBox ((ftell f) as string)
	)

	fn ReadSingleMorph f mobj = (
		ReadSingleMesh f mobj
		ReadBaseMorph f mobj
	)

	fn ReadMorph f mobj = (
		nmesh=ReadStandardMesh f mobj
		ReadBaseMorph f mobj
	)

	fn ReadBillboard f mobj = (
		nmesh=ReadStandardMesh f
		ReadByte f   --axis
		ReadByte f
		ReadByte f
		ReadByte f
		ReadByte f   --axis mode
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
		--ApplyTransformations nmesh mobj._parentID pos scaletion rotation
		ApplyTransform nmesh mobj

	)

	fn ReadMirror f mobj = (

		for bb=1 to 30 do
		(
			ReadFloat f
		)

		verts=ReadLong f
		faces=ReadLong f
		nmesh = editable_mesh()
		nmesh.name=mobj._name
		if mobj._parentID!=0 do nmesh.parent=mobj._parentID
		setNumVerts nmesh verts
		setNumFaces nmesh faces true

		for ve=0 to (verts-1) do
		(
			vx=ReadFloat f
			vy=ReadFloat f
			vz=ReadFloat f
			setVert nmesh (ve+1) vx (vz) vy--fucking max' yz swaping
		)

		for t=1 to faces do
		(
			v0=(ReadShort f)+1
			v1=(ReadShort f)+1
			v2=(ReadShort f)+1
			setFace nmesh t v0 v2 v1
		)


		--ApplyTransformations nmesh mobj._parentID pos scaletion rotation
		ApplyTransform nmesh mobj
	)

	fn ReadDummy f mobj = (
		nmesh=dummy()
		if mobj._parentID!=0 do nmesh.parent=mobj._parentID

		--for bb=1 to 24 do
		--(
		--	readbyte f
		--)

		dminx = ReadFloat f
		dminy = ReadFloat f
		dminz = ReadFloat f
		dmaxx = ReadFloat f
		dmaxy = ReadFloat f
		dmaxz = ReadFloat f
		nmesh.boxsize=[(abs (dminx-dmaxx)),(abs (dminy-dmaxy)),(abs (dminz-dmaxz))]

		nmesh.name = mobj._name
		--ApplyTransformations3 nmesh mobj._parentID pos scaletion rotation

		ApplyTransform nmesh mobj


		dummy_layer.addnode nmesh

		hide nmesh
	)

	fn ReadSector f mobj = (
		ReadLong f --always 2049
		ReadLong f --always 0


		verts = ReadLong f
		faces = ReadLong f


		verts_array = #()
		faces_array = #()

		for i = 1 to verts do (
			x = readfloat f
			y = readfloat f
			z = readfloat f
			append verts_array [x, z, y]
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


		--ApplyTransformations nmesh mobj._parentID pos scaletion rotation
		ApplyTransform nmesh mobj

		sector_layer.addnode nmesh

		nmesh.wirecolor = (color 255 199 0)

		dminx = ReadFloat f
		dminy = ReadFloat f
		dminz = ReadFloat f
		dmaxx = ReadFloat f
		dmaxy = ReadFloat f
		dmaxz = ReadFloat f
		--mesh.boxsize=[(abs (dminx-dmaxx)),(abs (dminy-dmaxy)),(abs (dminz-dmaxz))]

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
			pmesh.name = mobj._name+"__PORTAL"+(bb as string)

			verts_array = #()

			for cc=1 to numVerts do
			(
				vx = readfloat f
				vy = readfloat f
				vz = readfloat f
				setVert pmesh cc vx vz vy
				append verts_array cc
			)

			p = convertToPoly pmesh

			polyop.createPolygon p verts_array

			--verts_list = #()
			--for cc=1 to p.numVerts do
			--(
			--	append verts_list (p.verts)
			--)
			--result = polyop.capHolesByVert p p.verts
			--print (result as string)

			p.wirecolor = (color 255 0 199)


			portal_layer.addnode p


			modp = MafSubtype()
			modp.subtypeName = "Portal"
			modp.nearRange = nearRange
			modp.farRange = farRange
			addmodifier pmesh modp

			p.parent = nmesh

			append portals_array p
		)

		--group portals_array name:"PORTALS"

		cyp = "Sektor"
	)

	fn ReadTarget f mobj = (
		nmesh=dummy()
		nmesh.name=mobj._name
		nmesh.boxsize=[1,1,1]
		if mobj._parentID!=0 do nmesh.parent=mobj._parentID
		--ApplyTransformations nmesh mobj._parentID pos scaletion rotation
		ApplyTransform nmesh mobj

		ReadByte f
		ReadByte f
		bob=ReadByte f

		for b=1 to bob do
		(
			ReadShort f
		)
	)

	fn ReadBone f mobj = (
		nmesh=dummy()
		nmesh.name=mobj._name
		nmesh.boxsize=[0.1,0.1,0.1]
		if mobj._parentID!=0 do nmesh.parent=mobj._parentID
		--ApplyTransformations nmesh mobj._parentID pos scaletion rotation
		ApplyTransform nmesh mobj
		for b=1 to 64 do
		(
			--rotation matrix
			ReadByte f
		)
		ReadLong f
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

		x = ReadFloat f
		y = ReadFloat f
		z = ReadFloat f
		mobj._offset = point3 x z y

		sx = ReadFloat f
		sy = ReadFloat f
		sz = ReadFloat f
		mobj._scale = point3 sx sz sy

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

			sector_layer = LayerManager.newLayerFromName "Sectors"
			portal_layer = LayerManager.newLayerFromName "Portals"
			dummy_layer = LayerManager.newLayerFromName "Dummies"

			lod_layers = #()

			objs = ReadShort f
			for o=1 to objs do
			(

				objectType = ReadByte f
				local visualType
				local visualFlags

				if objectType == 1 do --visual object
				(
					visualType = ReadByte f
					visualFlags = ReadShort f
				)


				--general block

				nmesh = 0

				mobj = ReadBaseObject f

				print (" ****** " + mobj._name)

				cyp = "idk"

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


				modf = MafSubtype()
				modf.subtypeName = cyp
				modf.cullFlags = mobj._cullingFlags
				modf.userParams = mobj._params
				addmodifier nmesh modf

				append Mafia_Object nmesh
			)


			--MessageBox ("Last object: "+meshname+" ends at "+((ftell f) as string))
			fclose f

		)
	)
)