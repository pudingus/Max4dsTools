--4ds importer plugin for 3dsmax by Mr F



utility MafiaImport "4DS Import v4.1"
(
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


	button btn "Import" pos:[55,10] width:50

	on btn pressed do
	(
		meshname=""

		file=GetOpenFileName types:"4DS models (*.4ds)|*.4ds|All files (*.*)|*.*"
		if file!=undefined do
		(

			Mafia_Material = #()
			Mafia_Object = #()


			f = fopen file "rb"
			-- FILE START
			fourcc = ReadLong f
			version = ReadShort f
			if version!=29 do MessageBox "4DS version is not 29 - strange"
			timestamp = ReadLongLong f

			-- MATERIALS
			mats = ReadShort f

			for m=1 to mats do
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
					envMapName=""
					for bb=1 to nameLength do
					(
						envMapName = envMapName + (bit.intAsChar (readbyte f))
					)
					envtex = bitmaptex()
					envtex.filename = envMapName
					mat.delegate.reflectionMap = envtex;
					--MessageBox (envMapName)
				)

				diffMapNameLength = readbyte f
				if diffMapNameLength!=0 do
				(
					mat.delegate.diffuseMapEnable=true
					diffMapName=""
					for bb=1 to diffMapNameLength do
					(
						diffMapName = diffMapName + (bit.intAsChar (readbyte f))
					)
					diffMap = bitmaptex()
					diffMap.filename = diffMapName
					mat.delegate.diffuseMap = diffMap;
					showTextureMap mat on
				)

				if HasAlpha==true do
				(
					mat.delegate.opacityMapEnable=true
					alphaMapNameLength = readbyte f
					alphaMapName=""
					for bb=1 to alphaMapNameLength do
					(
						alphaMapName = alphaMapName + (bit.intAsChar (readbyte f))
					)
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


				Mafia_Material = append Mafia_Material mat
				--b = box()
				--b.material=mat
			)

			--OBJECTS

			objs = ReadShort f
			for o=1 to objs do
			(
				isGlow=false
				isMirror=false
				isMorph=false
				isSngm=false
				isBBRD=false
				--noHier=false

				frameType = ReadByte f
				--	if frameType==1 do
				--	(
				--		frameType=ReadByte f
				--		if frameType==0 do
				--		(
				--			frameType=ReadByte f
				--			if (frameType==0 or frameType==128) do
				--			(
				--				frameType=ReadByte f
				--				if frameType==42 do frameType=704643073
				--			)
				--		)
				--		if frameType==05 do
				--		(
				--			frameType=ReadByte f
				--			if frameType==0 do
				--			(
				--				frameType=ReadByte f
				--				if frameType==42 do frameType=704644609
				--			)
				--		)
				--	)


				if frameType==1 do --default object
				(
					visualType = ReadByte f

					if visualType==2 do isSngm=true   --Singlemesh
					-- 3 SNGMRPH
					if visualType==3 do    --Singlemorph
					(
						isSngm=true
						isMorph=true
					)
					if visualType==4 do isBBRD=true   --Billboard
					if visualType==5 do isMorph=true
					if visualType==6 do isGlow=true
					if visualType==8 do isMirror=true

					visualFlags = ReadShort f

					--if (visualFlags==0) and (visualType==6) do noHier=true
				)


				--general block

				nmesh = 0

				parent_=0

				--if noHier==false do
				--(
					parent_ = ReadShort f
					if parent_<0 do parent_=0
					if parent_>0 do parent_ = Mafia_Object[parent_]
				--)

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
				--	rotation = eulerangles 0 0 0
				--	rotation = (quatToEuler rotation2 order:1)
				--	tmp=rotation.x
				--	rotation.x=rotation.y
				--	rotation.y=tmp
				--	rotation.z = rotation.z - 180

				--MessageBox (frameType as string)

				cullingFlags = ReadByte f

				nameLength = ReadByte f
				meshname=""
				for bb=1 to nameLength do
				(
					meshname = meshname + (bit.intAsChar (readbyte f))
				)

				userPropertiesLength = ReadByte f
				userProperties=""
				for bb=1 to userPropertiesLength do
				(
					userProperties = userProperties + (bit.intAsChar (readbyte f))
				)

				--FRAME_VISUAL
				if frameType==1 do
				(
					--VISUAL_OBJECT
					if (isGlow==false) and (isMirror==false) do
					(
						dupl = ReadShort f
						if dupl!=0 then --MessageBox "Duplicate!"
						(
							--MessageBox "Duplicate!"
							nmesh = reference Mafia_Object[dupl]
							ApplyTransformations nmesh parent_ pos scaletion rotation
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


								if parent_!=0 do nmesh.parent=parent_


								if l==1 do nmesh.name = meshname
								if l>1 do nmesh.name = "LOD"+((l-1) as string)+meshname

								/*"Note: The optional tverts array feature is currently broken.
									The texture vertices are set correctly,
									but no texture faces are built internally. Until this gets fixed,
									you can work around by building the texture faces yourself:"
								*/
								buildTVFaces nmesh
								for i = 1 to nmesh.numfaces do(setTVFace nmesh i (getFace nmesh i))


								ApplyTransformations nmesh parent_ pos scaletion rotation


								nmesh.material = mult



								--Singlemesh
								if isSngm==true do
								(
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
									--MessageBox ((ftell f) as string)
								)


								if isMorph==true do
								(
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

								if isBBRD==true do
								(
									ReadByte f
									ReadByte f
									ReadByte f
									ReadByte f
									ReadByte f
								)


							)
						)
					)


					if isGlow==true do
					(
						-- glow
						--if noHier==false then
						--(
							b = ReadByte f
							for bb=1 to b do
							(
								ReadFloat f
								ReadShort f
							)
						--)
						--else
						--(
						--	ReadFloat f
						--	ReadFloat f
						--	ReadFloat f
						--	ReadFloat f
						--	ReadFloat f
						--	ReadFloat f
						--)

						nmesh=dummy()
						if parent_!=0 do nmesh.parent=parent_

						nmesh.boxsize=[1,1,1]

						nmesh.name = meshname
						ApplyTransformations nmesh parent_ pos scaletion rotation
					)

					if isMirror==true do
					(
						-- mirror
						for bb=1 to 30 do
						(
							ReadFloat f
						)

						verts=ReadLong f
						faces=ReadLong f
						nmesh = editable_mesh()
						nmesh.name=meshname
						if parent_!=0 do nmesh.parent=parent_
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


						ApplyTransformations nmesh parent_ pos scaletion rotation

					)

				)

				--FRAME_DUMMY
				if frameType==6 do
				(
					nmesh=dummy()
					if parent_!=0 do nmesh.parent=parent_

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
					if parent_!=0 then
					(
						in coordsys parent nmesh.pos = pos
						in coordsys parent scale nmesh (scaletion*nmesh.parent.scale)
						in coordsys parent rotate nmesh (rotation*nmesh.parent.rotation)
					)
					else
					(
						in coordsys world nmesh.pos = pos
						in coordsys world scale nmesh scaletion
						in coordsys world rotate nmesh rotation

					)
				)

				--FRAME_SECTOR
				if frameType==5 do
				(

					ReadLong f --always 2049
					ReadLong f --always 0


					verts = ReadLong f
					faces = ReadLong f
					--for bb=1 to (verts*12) do
					--(
					--	readbyte f
					--)
					--for bb=1 to (faces*6) do
					--(
					--	readbyte f
					--)

					--mesh=dummy()
					--if parent_!=0 do mesh.parent=parent_
					--mesh.boxsize=[1,1,1]

					--for bb=1 to 24 do
					--(
					--	readbyte f
					--)
					nmesh = editable_mesh()
					nmesh.name=meshname
					if parent_!=0 do nmesh.parent=parent_
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

					ApplyTransformations nmesh parent_ pos scaletion rotation

					dminx = ReadFloat f
					dminy = ReadFloat f
					dminz = ReadFloat f
					dmaxx = ReadFloat f
					dmaxy = ReadFloat f
					dmaxz = ReadFloat f
					--mesh.boxsize=[(abs (dminx-dmaxx)),(abs (dminy-dmaxy)),(abs (dminz-dmaxz))]

					numPortals = ReadByte f
					for bb=1 to numPortals do
					(
						numVerts = readbyte f --numVertices
						readlong f  --always 4
						readlong f
						readlong f
						readlong f
						readlong f  --flags?

						nearRange = readfloat f
						farRange = readfloat f

						pmesh = Editable_mesh()
						pmesh.name = meshname+"__PORTAL"+(bb as string)
						setNumVerts pmesh verts

						for cc=1 to numVerts do
						(
							vx = readfloat f
							vy = readfloat f
							vz = readfloat f
							setVert pmesh (cc+1) vx (vz) vy--fucking max' yz swaping
						)

						modp = MafSubtype()
						modp.subtypeName = "Portal"
						addmodifier pmesh modp

					)

					modf = MafSubtype()
					modf.subtypeName = "Sektor"
					addmodifier nmesh modf

				)

				--FRAME_JOINT
				if frameType==10 do
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

					mesh=dummy()
					mesh.name=meshname
					mesh.boxsize=[0.1,0.1,0.1]
					if parent_!=0 do mesh.parent=parent_
					ApplyTransformations nmesh parent_ pos scaletion rotation
					for b=1 to 64 do
					(
						--rotation matrix
						ReadByte f
					)
					ReadLong f
				)

				--FRAME_TARGET
				if frameType==7 do
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

					mesh=dummy()
					mesh.name=meshname
					mesh.boxsize=[1,1,1]
					if parent_!=0 do mesh.parent=parent_
					ApplyTransformations nmesh parent_ pos scaletion rotation

					ReadByte f
					ReadByte f
					bob=ReadByte f

					for b=1 to bob do
					(
						ReadShort f
					)

				)

				--addModifier mesh (MafSubtype())

				--modf = MafSubtype()
				--modf.subtypeName = "Sektorrrr"
				--addmodifier mesh modf
				--print "kekrrrr"

				Mafia_Object = append Mafia_Object nmesh
				--MessageBox (meshname+((ftell f)as string))

			)

			select (for o in objects where isKindOf o Editable_Mesh collect o)
			--modPanel.addModToSelection (Normalmodifier flip:on) ui:on
			--max move
			--convertTo selection Editable_Patch
			--convertTo selection  TriMeshGeometry
			selection.wirecolor = color 0 0 0
			--collapsestack selection


			MessageBox ("Last object: "+meshname+" ends at "+((ftell f) as string))
			fclose f

		)
	)
)