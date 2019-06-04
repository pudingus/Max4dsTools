--4ds importer plugin for 3dsmax by Mr F



utility MafiaImport "4DS Import v4.1"
(
	local Mafia_Material
	local Mafia_Object
	local pos
	local scaletion
	local rotation
	--local parentID
	local meshname = ""
	local nmesh

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


			append Mafia_Material mat
			--b = box()
			--b.material=mat
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

	fn ReadStandardMesh f parentID = (
		duplicateID = ReadShort f
		if duplicateID != 0 then --MessageBox "Duplicate!"
		(
			--MessageBox "Duplicate!"
			nmesh = reference Mafia_Object[duplicateID]
			ApplyTransformations nmesh parentID pos scaletion rotation
		)
		else
		(
			numLods = ReadByte f


			for l=1 to numLods do
			(
				ReadFloat f  --clipping range



				verts_array = #()
				normals_array = #()
				tverts_array = #()
				faces_array = #()

				verts_count = readshort f #unsigned

				verts_array.count = verts_count
				normals_array.count = verts_count
				tverts_array.count = verts_count

				for i = 1 to verts_count do
				(
					x = readfloat f; y = readfloat f; z = readfloat f
					norm_x = readfloat f; norm_y = readfloat f; norm_z = readfloat f
					u = readfloat f; v = readfloat f
					verts_array[i] = [x, z, y]
					normals_array[i] = [norm_x, norm_z, norm_y]
					tverts_array[i] = [u, 1-v, 0]
				)



				facegroups_count = readbyte f #unsigned

				mult = MultiMaterial()
				mult.numsubs=facegroups_count

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
						append material_array i
						--setFaceMatID nmesh totalCount i
						totalCount = totalCount + 1
					)
					matnum = (ReadShort f)
					if matnum>0 do mult[i] = Mafia_Material[matnum]
				)


				nmesh = mesh vertices:verts_array faces:faces_array materialIDs:material_array tverts:tverts_array

				nmesh.wirecolor = color 0 0 0


				if parentID!=0 do nmesh.parent=parentID


				if l==1 do nmesh.name = meshname
				if l>1 do nmesh.name = "LOD"+((l-1) as string)+meshname

				/*"Note: The optional tverts array feature is currently broken.
					The texture vertices are set correctly,
					but no texture faces are built internally. Until this gets fixed,
					you can work around by building the texture faces yourself:"
				*/
				buildTVFaces nmesh
				for i = 1 to nmesh.numfaces do(setTVFace nmesh i (getFace nmesh i))


				ApplyTransformations2 nmesh parentID pos scaletion rotation


				nmesh.material = mult
			)
		)
	)

	fn ReadSingleMesh f parentID = (
		ReadStandardMesh f

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

	fn ReadBaseMorph f parentID = (
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

	fn ReadSingleMorph f parentID = (
		ReadSingleMesh f
		ReadBaseMorph f
	)

	fn ReadMorph f parentID = (
		ReadStandardMesh f
		ReadBaseMorph f
	)

	fn ReadBillboard f parentID = (
		ReadStandardMesh f
		ReadByte f   --axis
		ReadByte f
		ReadByte f
		ReadByte f
		ReadByte f   --axis mode
	)

	fn ReadGlow f parentID = (

		b = ReadByte f
		for bb=1 to b do
		(
			ReadFloat f
			ReadShort f
		)

		nmesh=dummy()
		if parentID!=0 do nmesh.parent=parentID

		nmesh.boxsize=[1,1,1]

		nmesh.name = meshname
		ApplyTransformations nmesh parentID pos scaletion rotation

	)

	fn ReadMirror f parentID = (

		for bb=1 to 30 do
		(
			ReadFloat f
		)

		verts=ReadLong f
		faces=ReadLong f
		nmesh = editable_mesh()
		nmesh.name=meshname
		if parentID!=0 do nmesh.parent=parentID
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


		ApplyTransformations nmesh parentID pos scaletion rotation
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

				parentID = 0


				parentID = ReadShort f
				if parentID < 0 do parentID = 0
				if parentID > 0 do parentID = Mafia_Object[parentID]


				x = ReadFloat f
				y = ReadFloat f
				z = ReadFloat f
				pos = point3 x z y

				sx = ReadFloat f
				sy = ReadFloat f
				sz = ReadFloat f
				scaletion = point3 sx sz sy

				rw = ReadFloat f
				rx = ReadFloat f
				ry = ReadFloat f
				rz = ReadFloat f
				rotation = quat rx rz ry rw


				--MessageBox (frameType as string)

				cullingFlags = ReadByte f

				nameLength = ReadByte f
				meshname = readText f nameLength

				userPropertiesLength = ReadByte f
				userProperties = readText f userPropertiesLength


				--VISUAL OBJECT
				if objectType == 1 do
				(
					if visualType == 0 do ReadStandardMesh f parentID
					if visualType == 2 do ReadSingleMesh f parentID
					if visualType == 3 do ReadSingleMorph f parentID
					if visualType == 4 do ReadBillboard f parentID
					if visualType == 5 do ReadMorph f parentID
					if visualType == 6 do ReadGlow f parentID
					if visualType == 8 do ReadMirror f parentID
				)

				--FRAME_SECTOR
				if objectType==5 do
				(

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
					nmesh.name = meshname
					if parentID != 0 do nmesh.parent=parentID


					ApplyTransformations nmesh parentID pos scaletion rotation

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
						pmesh.name = meshname+"__PORTAL"+(bb as string)

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
						addmodifier pmesh modp

						p.parent = nmesh

						append portals_array p
					)

					group portals_array name:"PORTALS"

					modf = MafSubtype()
					modf.subtypeName = "Sektor"
					addmodifier nmesh modf

				)

				--FRAME_DUMMY
				if objectType==6 do
				(
					nmesh=dummy()
					if parentID!=0 do nmesh.parent=parentID

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

					nmesh.name = meshname
					ApplyTransformations3 nmesh parentID pos scaletion rotation
				)

					--FRAME_TARGET
				if objectType==7 do
				(
					-- target
					mark = ReadByte f
					b = readbyte f
					meshname=""
					for bb=1 to b do
					(
						meshname = meshname + (bit.intAsChar (readbyte f))
					)

					b = readbyte f
					subtype=""
					for bb=1 to b do
					(
						subtype = subtype + (bit.intAsChar (readbyte f))
					)

					nmesh=dummy()
					nmesh.name=meshname
					nmesh.boxsize=[1,1,1]
					if parentID!=0 do nmesh.parent=parentID
					ApplyTransformations nmesh parentID pos scaletion rotation

					ReadByte f
					ReadByte f
					bob=ReadByte f

					for b=1 to bob do
					(
						ReadShort f
					)

				)

				--FRAME_JOINT
				if objectType==10 do
				(
					-- bone
					mark = ReadByte f
					b = readbyte f
					meshname=""
					for bb=1 to b do
					(
						meshname = meshname + (bit.intAsChar (readbyte f))
					)
					b = readbyte f
					subtype=""
					for bb=1 to b do
					(
						subtype = subtype + (bit.intAsChar (readbyte f))
					)

					nmesh=dummy()
					nmesh.name=meshname
					nmesh.boxsize=[0.1,0.1,0.1]
					if parentID!=0 do nmesh.parent=parentID
					ApplyTransformations nmesh parentID pos scaletion rotation
					for b=1 to 64 do
					(
						--rotation matrix
						ReadByte f
					)
					ReadLong f
				)



				--addModifier mesh (MafSubtype())

				--modf = MafSubtype()
				--modf.subtypeName = "Sektorrrr"
				--addmodifier mesh modf
				--print "kekrrrr"

				Mafia_Object = append Mafia_Object nmesh
				--MessageBox (meshname+((ftell f)as string))

			)

			--select (for o in objects where isKindOf o Editable_Mesh collect o)
			--modPanel.addModToSelection (Normalmodifier flip:on) ui:on
			--max move
			--convertTo selection Editable_Patch
			--convertTo selection  TriMeshGeometry
			--selection.wirecolor = color 0 0 0
			--collapsestack selection


			MessageBox ("Last object: "+meshname+" ends at "+((ftell f) as string))
			fclose f

		)
	)
)