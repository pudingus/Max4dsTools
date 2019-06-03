--4ds importer plugin for 3dsmax by Mr F

utility MafiaImport "4DS Import v4.1"
(
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

				mesh = 0

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
							mesh = reference Mafia_Object[dupl]
							if parent_!=0 then
							(
								in coordsys parent mesh.pos.x = x
								in coordsys parent mesh.pos.y = z
								in coordsys parent mesh.pos.z = y --fucking max' yz swaping
								in coordsys local scale mesh scaletion
								in coordsys parent rotate mesh (rotation*mesh.parent.rotation)--(eulerangles rotation.x rotation.y rotation.z)
							)
							else
							(
								in coordsys world mesh.pos.x = x
								in coordsys world mesh.pos.y = z
								in coordsys world mesh.pos.z = y --fucking max' yz swaping
								in coordsys world scale mesh scaletion
								in coordsys world rotate mesh rotation
							)
						)
						else
						(
							numLods = ReadByte f


							for l=1 to numLods do
							(
								ReadFloat f  --clipping range

								mesh = editable_mesh()
								if parent_!=0 do mesh.parent=parent_
								meshop.setMapSupport mesh 1 true

								numVerts = ReadShort f #unsigned
								setNumVerts mesh numVerts
								setNumTVerts mesh numVerts
								p3 = point3 0 0 0


								for ve=0 to (numVerts-1) do
								(
									vx=ReadFloat f
									vy=ReadFloat f
									vz=ReadFloat f
									vnx=ReadFloat f
									vny=ReadFloat f
									vnz=ReadFloat f
									vu=ReadFloat f
									vv=ReadFloat f
									setVert mesh (ve+1) vx (vz) vy--fucking max' yz swaping
									p3.x = vnx
									p3.y = (vnz)
									p3.z = vny--fucking max' yz swaping
									setNormal mesh (ve+1) p3
									p3.x = vu
									p3.y = (1-vv)
									p3.z = 0
									setTVert mesh (ve+1) p3
								)


								numFaceGroups = ReadByte f
								mult = MultiMaterial()
								mult.numsubs=numFaceGroups
								lasttris=0

								for s=1 to numFaceGroups do
								(
									numFaces = ReadShort f #unsigned
									setNumFaces mesh ((getNumFaces mesh)+numFaces) true

									for t=1 to numFaces do
									(
										v0=(ReadShort f #unsigned)+1
										v1=(ReadShort f #unsigned)+1
										v2=(ReadShort f #unsigned)+1
										setFace mesh (t+lasttris) v0 v2 v1
										setFaceMatID mesh (t+lasttris) s
										--setTVFace mesh t v0 v1 v2
									)

									lasttris=lasttris+numFaces

									matnum = (ReadShort f)
									if matnum>0 do mult[s] = Mafia_Material[matnum]
									--if matnum==0 do mult[s]=standard()
								)

								buildTVFaces mesh

								for fa=1 to mesh.numfaces do
								(
									setTVFace mesh fa (getface mesh fa)
								)
								update mesh

								if l==1 do mesh.name = meshname
								if l>1 do mesh.name = "LOD"+((l-1) as string)+meshname

								if parent_!=0 then
								(
									in coordsys parent mesh.pos.x = x
									in coordsys parent mesh.pos.y = z
									in coordsys parent mesh.pos.z = y --fucking max' yz swaping
									in coordsys local scale mesh scaletion
									in coordsys world rotate mesh (rotation*mesh.parent.rotation)--(eulerangles rotation.x rotation.y rotation.z)
								)
								else
								(
									in coordsys world mesh.pos.x = x
									in coordsys world mesh.pos.y = z
									in coordsys world mesh.pos.z = y --fucking max' yz swaping
									in coordsys world scale mesh scaletion
									in coordsys world rotate mesh rotation
								)

								mesh.material = mult

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

						mesh=dummy()
						if parent_!=0 do mesh.parent=parent_

						mesh.boxsize=[1,1,1]

						mesh.name = meshname
						if parent_!=0 then
						(
							in coordsys parent mesh.pos.x = x
							in coordsys parent mesh.pos.y = z
							in coordsys parent mesh.pos.z = y --fucking max' yz swaping
							in coordsys local scale mesh scaletion
							in coordsys parent rotate mesh (rotation*mesh.parent.rotation)
						)
						else
						(
							in coordsys world mesh.pos.x = x
							in coordsys world mesh.pos.y = z
							in coordsys world mesh.pos.z = y --fucking max' yz swaping
							in coordsys world scale mesh scaletion
							in coordsys world rotate mesh rotation
						)
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
						mesh = editable_mesh()
						mesh.name=meshname
						if parent_!=0 do mesh.parent=parent_
						setNumVerts mesh verts
						setNumFaces mesh faces true

						for ve=0 to (verts-1) do
						(
							vx=ReadFloat f
							vy=ReadFloat f
							vz=ReadFloat f
							setVert mesh (ve+1) vx (vz) vy--fucking max' yz swaping
						)

						for t=1 to faces do
						(
							v0=(ReadShort f)+1
							v1=(ReadShort f)+1
							v2=(ReadShort f)+1
							setFace mesh t v0 v2 v1
						)


						if parent_!=0 then
						(
							in coordsys parent mesh.pos.x = x
							in coordsys parent mesh.pos.y = z
							in coordsys parent mesh.pos.z = y --fucking max' yz swaping
							in coordsys local scale mesh scaletion
							in coordsys parent rotate mesh (rotation*mesh.parent.rotation)--(eulerangles rotation.x rotation.y rotation.z)
						)
						else
						(
							in coordsys world mesh.pos.x = x
							in coordsys world mesh.pos.y = z
							in coordsys world mesh.pos.z = y --fucking max' yz swaping
							in coordsys world scale mesh scaletion
							in coordsys world rotate mesh rotation
						)

					)

				)

				--FRAME_DUMMY
				if frameType==6 do
				(
					mesh=dummy()
					if parent_!=0 do mesh.parent=parent_

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
					mesh.boxsize=[(abs (dminx-dmaxx)),(abs (dminy-dmaxy)),(abs (dminz-dmaxz))]

					mesh.name = meshname
					if parent_!=0 then
					(
						in coordsys parent mesh.pos.x = x
						in coordsys parent mesh.pos.y = z
						in coordsys parent mesh.pos.z = y --fucking max' yz swaping
						in coordsys parent scale mesh (scaletion*mesh.parent.scale)
						in coordsys parent rotate mesh (rotation*mesh.parent.rotation)
					)
					else
					(
						in coordsys world mesh.pos.x = x
						in coordsys world mesh.pos.y = z
						in coordsys world mesh.pos.z = y --fucking max' yz swaping
						in coordsys world scale mesh scaletion
						in coordsys world rotate mesh rotation

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
					mesh = editable_mesh()
					mesh.name=meshname
					if parent_!=0 do mesh.parent=parent_
					setNumVerts mesh verts
					setNumFaces mesh faces true


					for ve=0 to (verts-1) do
					(
						vx=ReadFloat f
						vy=ReadFloat f
						vz=ReadFloat f
						setVert mesh (ve+1) vx (vz) vy--fucking max' yz swaping
					)

					for t=1 to faces do
					(
						v0=(ReadShort f)+1
						v1=(ReadShort f)+1
						v2=(ReadShort f)+1
						setFace mesh t v0 v2 v1
					)

					if parent_!=0 then
					(
						in coordsys parent mesh.pos.x = x
						in coordsys parent mesh.pos.y = z
						in coordsys parent mesh.pos.z = y --fucking max' yz swaping
						in coordsys local scale mesh scaletion
						in coordsys parent rotate mesh (rotation*mesh.parent.rotation)--(eulerangles rotation.x rotation.y rotation.z)
					)
					else
					(
						in coordsys world mesh.pos.x = x
						in coordsys world mesh.pos.y = z
						in coordsys world mesh.pos.z = y --fucking max' yz swaping
						in coordsys world scale mesh scaletion
						in coordsys world rotate mesh rotation
					)

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
					addmodifier mesh modf

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
					if parent_!=0 then
					(
						in coordsys parent mesh.pos.x = x
						in coordsys parent mesh.pos.y = z
						in coordsys parent mesh.pos.z = y --fucking max' yz swaping
						in coordsys local scale mesh scaletion
						in coordsys parent rotate mesh (rotation*mesh.parent.rotation)--(eulerangles rotation.x rotation.y rotation.z)
					)
					else
					(
						in coordsys world mesh.pos.x = x
						in coordsys world mesh.pos.y = z
						in coordsys world mesh.pos.z = y --fucking max' yz swaping
						in coordsys world scale mesh scaletion
						in coordsys world rotate mesh rotation
					)
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
					if parent_!=0 then
					(
						in coordsys parent mesh.pos.x = x
						in coordsys parent mesh.pos.y = z
						in coordsys parent mesh.pos.z = y --fucking max' yz swaping
						in coordsys local scale mesh scaletion
						in coordsys parent rotate mesh (rotation*mesh.parent.rotation)--(eulerangles rotation.x rotation.y rotation.z)

					)
					else
					(
						in coordsys world mesh.pos.x = x
						in coordsys world mesh.pos.y = z
						in coordsys world mesh.pos.z = y --fucking max' yz swaping
						in coordsys world scale mesh scaletion
						in coordsys world rotate mesh rotation
					)

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

				Mafia_Object = append Mafia_Object mesh
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