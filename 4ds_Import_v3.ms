--4ds importer plugin for 3dsmax by Mr F

utility MafiaImport "4DS Import v3"
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
				header = ReadLong f
				mark = ReadShort f
--					if mark!=29 do MessageBox "4DS mark is not 29 - strange"
				something0 = ReadLong f
				something1 = ReadLong f
			
			-- MATERIALS
				mats = ReadShort f

					for m=1 to mats do
					(
						mat = standard()
						mat.name = "4DSMat"+(m as string)
						
						settings = ReadLong f
						mat.ambient.red = (ReadFloat f)*255
						mat.ambient.green = (ReadFloat f)*255
						mat.ambient.blue = (ReadFloat f)*255
						mat.diffuse.red = (ReadFloat f)*255
						mat.diffuse.green = (ReadFloat f)*255
						mat.diffuse.blue = (ReadFloat f)*255
						mat.selfIllumColor.red = (ReadFloat f)*255
						mat.selfIllumColor.green = (ReadFloat f)*255
						mat.selfIllumColor.blue = (ReadFloat f)*255
						mat.opacity = (ReadFloat f)*100
						
						--HasColor = (bit.get settings 8)
						--HasDiff = (bit.get settings 22)
						HasEnv = ((bit.get settings (32-12)) or (bit.get settings (32-23)))
						HasAlpha = (bit.get settings 31)
						--AddEnv = (bit.get settings 5)
						--EnvSigned = (bit.get settings 6)
						--EnvAddSmooth = (bit.get settings 7)
						--Smoothing = (bit.get settings 8)
						Anim = (bit.get settings (32-5))
						--TwoSided = (bit.get settings 28)
						--AddEffect = (bit.get settings 9)
						Mask = (bit.get settings 30) 
						--AddBlend= (bit.get settings 25)
						--AddBlend2= (bit.get settings 31)
						
						--sets = "!" + (HasColor as string) + " " + (HasDiff as string) +" "+ (HasEnv as string) +" "+ (HasAlpha as string) +" "+ (Anim as string) +" "+ (TwoSided as string) +" "+ (AddEffect as string) +" "+ (Mask as string) +" "+ (AddBlend as string) +" "+ (AddBlend2 as string)						sets="!"
						--sets = "!"
						--for o=0 to 31 do
						--(
						--	if (bit.get settings (32-o))==true do sets=sets+"1"
						--	if (bit.get settings (32-o))==false do sets=sets+"0"
						--)
						
						--sets=(HasEnv as string) + " "+ (HasAlpha as string) + " "+ (Anim as string) + " "+ (Mask as string)
						--MessageBox (sets)
						if HasEnv==true do
						(
							mat.reflectionMapEnable=true
							mat.reflectionMapAmount = (ReadFloat f)*100
							b = readbyte f
							envtexname=""
								for bb=1 to b do
								(
									envtexname = envtexname + (bit.intAsChar (readbyte f))
								)
								envtex = bitmaptex()
								envtex.filename = envtexname
								mat.reflectionMap = envtex;
								--MessageBox (envtexname)
						)
						
							b = readbyte f
							if b!=0 do
							(
								mat.diffuseMapEnable=true
								difftexname=""
								for bb=1 to b do
								(
									difftexname = difftexname + (bit.intAsChar (readbyte f))
								)
								difftex = bitmaptex()
								difftex.filename = difftexname
								mat.diffuseMap = difftex;
								showTextureMap mat on
							)
						
							if HasAlpha==true do
							(
								mat.opacityMapEnable=true
								b = readbyte f
								alphatexname=""
									for bb=1 to b do
									(
										alphatexname = alphatexname + (bit.intAsChar (readbyte f))
									)
									alphatex = bitmaptex()
									alphatex.filename = alphatexname
									mat.opacityMap = alphatex;
							)
							
							if Anim==true do
							(
								for bb=1 to 18 do
								(
									readbyte f
								)
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
					
							oclass = ReadByte f
						--	if oclass==1 do
						--	(
						--		oclass=ReadByte f
						--		if oclass==0 do
						--		(
						--			oclass=ReadByte f
						--			if (oclass==0 or oclass==128) do
						--			(
						--				oclass=ReadByte f
						--				if oclass==42 do oclass=704643073
						--			)
						--		)
						--		if oclass==05 do
						--		(
						--			oclass=ReadByte f
						--			if oclass==0 do
						--			(
						--				oclass=ReadByte f
						--				if oclass==42 do oclass=704644609
						--			)
						--		)
						--	)
						
						
							if oclass==1 do
							(
								preclass = ReadByte f
								
									if preclass==2 do isSngm=true
									-- 3 SNGMRPH
									if preclass==3 do 
									(
										isSngm=true
										isMorph=true
									)
									if preclass==4 do isBBRD=true
									if preclass==5 do isMorph=true
									if preclass==6 do isGlow=true
									if preclass==8 do isMirror=true
								
								postclass = ReadShort f
								
									--if (postclass==0) and (preclass==6) do noHier=true
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
													
						--MessageBox (oclass as string)
							
						if oclass==1 do
						(
							
							--default object
							mark = ReadByte f
--							if mark!=9 do MessageBox "Object mark is not 9: strange"
								b = readbyte f
								meshname=""
									for bb=1 to b do
									(
										meshname = meshname + (bit.intAsChar (readbyte f))
									)
--									MessageBox meshname
							--if o>100 do MessageBox ("Default object: "+meshname)
								b = readbyte f
								subtype=""
									for bb=1 to b do
									(
										subtype = subtype + (bit.intAsChar (readbyte f))
									)
									
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
										lod = ReadByte f
										
										
										for l=1 to lod do
										(
											ReadShort f
											ReadShort f
											
											mesh = editable_mesh()
											if parent_!=0 do mesh.parent=parent_	
											meshop.setMapSupport mesh 1 true
			
											verts = ReadShort f #unsigned
											setNumVerts mesh verts
											setNumTVerts mesh verts
											p3 = point3 0 0 0
											
											
											for ve=0 to (verts-1) do
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
												
												
										
							
											
											surfs = ReadByte f
											mult = MultiMaterial()
											mult.numsubs=surfs
											lasttris=0
											
											for s=1 to surfs do
											(
												tris = ReadShort f #unsigned
												setNumFaces mesh ((getNumFaces mesh)+tris) true
												
												for t=1 to tris do
												(
													v0=(ReadShort f #unsigned)+1
													v1=(ReadShort f #unsigned)+1
													v2=(ReadShort f #unsigned)+1
													setFace mesh (t+lasttris) v0 v2 v1
													setFaceMatID mesh (t+lasttris) s
													--setTVFace mesh t v0 v1 v2
												)
												
												lasttris=lasttris+tris
												
											
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
						
						if oclass==6 do
						(
							--dummy
							mark = ReadByte f
--							if mark!=9 do MessageBox "Object mark is not 9: strange"
								b = readbyte f
								meshname=""
									for bb=1 to b do
									(
										meshname = meshname + (bit.intAsChar (readbyte f))
									)
--							MessageBox ("Dummy: "+meshname)
								b = readbyte f
								subtype=""
									for bb=1 to b do
									(
										subtype = subtype + (bit.intAsChar (readbyte f))
									)
								
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
						
						
						if oclass==5 do
						(
					--	MessageBox ((ftell f) as string)
							--sector
							mark = ReadByte f
--							if mark!=125 do MessageBox "Object mark is not 125: strange"
								b = readbyte f
								meshname=""
									for bb=1 to b do
									(
										meshname = meshname + (bit.intAsChar (readbyte f))
									)
							--MessageBox ("Sector: "+meshname)
									for bb=1 to 9 do
									(
										readbyte f
									)
								
								verts = ReadLong f
								faces = ReadLong f
								--	for bb=1 to (verts*12) do
								--	(
								--		readbyte f
								--	)
								--	for bb=1 to (faces*6) do
								--	(
								--		readbyte f
								--	)
									
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
								
								windows = ReadByte f
									for bb=1 to windows do
									(
										verts=readbyte f
											readbyte f
										for bb=1 to 7 do
										(
											readbyte f
										)
										for bb=1 to 16 do
										(
											readbyte f
										)
										ReadFloat f
										for bb=1 to (verts*12) do
										(
											readbyte f
										)
									)

						)
						
					
						if oclass==10 do
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
						
						if oclass==7 do
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
						
						Mafia_Object = append Mafia_Object mesh
						---MessageBox (meshname+((ftell f)as string))
						
					)
					
			select (for o in objects where isKindOf o Editable_Mesh collect o)		
			--modPanel.addModToSelection (Normalmodifier flip:on) ui:on
			--max move
			convertTo selection Editable_Patch
			convertTo selection  TriMeshGeometry
			selection.wirecolor = color 0 0 0
			--collapsestack selection
			
		
			MessageBox ("Last object: "+meshname+" ends at "+((ftell f) as string))
			fclose f
		)
	)

	
)