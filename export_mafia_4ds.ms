-- 4ds exporter script by Mr F

fn WriteText f _text = (
	if _text == undefined then (
		MessageBox "writetext undefined"
		print "writetext undefined"
		writebyte f 0 #unsigned
	)
	else (
		writebyte f _text.count #unsigned
		for i = 1 to _text.count do
			writebyte f (bit.charasint _text[i])
	)
)

fn writeMaterial f mat =
(
	sets = 0
	sets += (bit.set 0 1 true)
	--sets += (bit.set 0 16 true) --separate render state ?
			--sets += (bit.set 0 26 true)
			--sets += (bit.set 0 31 true)
		--mipmapping
	if classof mat == Standard then sets += (bit.set 0 24 true)
	if classof mat == MafMat4 do
	(

		sets += (bit.set 0 19 mat.delegate.diffuseMapEnable)
		sets += (bit.set 0 28 mat.useColoring)
		sets += (bit.set 0 24 mat.useMips)
		sets += (bit.set 0 29 mat.delegate.twoSided)
		sets += (bit.set 0 27 mat.isAnimatedM)
		sets += (bit.set 0 20 mat.delegate.reflectionMapEnable)
		sets += (bit.set 0 9 mat.envOverlay)
		sets += (bit.set 0 10 mat.envMultiply)
		sets += (bit.set 0 11 mat.envAdditive)
		sets += (bit.set 0 13 mat.YProj)
		sets += (bit.set 0 14 mat.YDetail)
		sets += (bit.set 0 15 mat.ZDetail)
		sets += (bit.set 0 16 mat.addEffect)
		sets += (bit.set 0 31 mat.delegate.opacityMapEnable)
		sets += (bit.set 0 30 mat.useColorKey)
		sets += (bit.set 0 32 mat.useAddBlend)




/*
		sets += (bit.set 0 24 mat.useMips)
		sets += (bit.set 0 32 mat.useAddBlend)
		sets += (bit.set 0 30 mat.useColorKey)
		sets += (bit.set 0 27 mat.useAnim)
		if mat.useAnim == true do
		(
			isAnim = true
			animFrames = mat.animFrames
			animDelay = mat.animDelay
			sets += (bit.set 0 26 mat.useAnimAlpha)
			--sets += (bit.set 0 16 true)
			--sets += (bit.set 0 31 true)
		)

		if (mat.useColorKey or mat.useAddBlend or mat.delegate.opacityMapEnable) then (
			sets += (bit.set 0 16 1)
		)

		isAddRefl = mat.useAddRefl
		isDiffReflAxis = mat.diffReflAxis
		mat = mat[#Standard]*/
	)




	WriteLong f  sets --(262145) -- settings
	--ambient
	WriteFloat f (mat.delegate.ambient.r/255.0)
	WriteFloat f (mat.delegate.ambient.g/255.0)
	WriteFloat f (mat.delegate.ambient.b/255.0)
	--diffuse
	WriteFloat f (mat.delegate.diffuse.r/255.0)
	WriteFloat f (mat.delegate.diffuse.g/255.0)
	WriteFloat f (mat.delegate.diffuse.b/255.0)
	--selfIllum
	if mat.delegate.useSelfIllumColor==true do
	(
		WriteFloat f (mat.delegate.selfIllumColor.r/255.0)
		WriteFloat f (mat.delegate.selfIllumColor.g/255.0)
		WriteFloat f (mat.delegate.selfIllumColor.b/255.0)
	)
	if mat.delegate.useSelfIllumColor==false do
	(
		WriteFloat f 0
		WriteFloat f 0
		WriteFloat f 0
	)
	--opacity
	WriteFloat f (mat.delegate.opacity / 100.0)

	--reflection map
	if mat.delegate.reflectionMapEnable == true do
	(
		WriteFloat f (mat.delegate.reflectionMapAmount/100.0)
		filename = filenameFromPath mat.delegate.reflectionMap.filename
		writetext f filename
	)

	--diffuse map
	if mat.delegate.diffuseMapEnable == false then WriteByte f 0
	if mat.delegate.diffuseMapEnable == true then (
		filename = filenameFromPath mat.delegate.diffusemap.filename
		writetext f filename
	)

	--opacity map
	if mat.delegate.opacityMapEnable == true then (
		filename = filenameFromPath mat.delegate.opacitymap.filename
		writetext f filename
	)

	if mat.isAnimatedM == true do
	(
		WriteByte f animFrames
		WriteByte f 0
		WriteLong f 0
		WriteLong f animDelay
		WriteLong f 0
		WriteLong f 0
	)
)

fn WritePoint3 f p3 = (
	writefloat f p3.x
	writefloat f p3.z
	writefloat f p3.y
)

fn SplitVertsByNormals theMesh =
(
	verts = getNumVerts theMesh
	for v = 1 to verts do
	(
		vfaces = (meshop.getFacesUsingVert theMesh #{v}) as array
		useit = true
		smgr = undefined
		--if vfaces.count == 1 then useit = true
		if vfaces.count > 1 do
		(
			for vf = 1 to vfaces.count do
			(
				if smgr == undefined then smgr = getFaceSmoothGroup theMesh vfaces[vf]
				if (getFaceSmoothGroup theMesh vfaces[vf]) != smgr do
				(
					theVertPos = getVert theMesh v
					newIndex = theMesh.numverts+1
					setNumVerts theMesh newIndex true
					setVert theMesh newIndex theVertPos
					fc = getFace theMesh vfaces[vf]
					if v==fc.x then setFace theMesh vfaces[vf] [newIndex,fc.y,fc.z]
					if v==fc.y then setFace theMesh vfaces[vf] [fc.x,newIndex,fc.z]
					if v==fc.z then setFace theMesh vfaces[vf] [fc.x,fc.y,newIndex]
				)
			)
		)

		--if useit == false do
		--(
		--)

	)

	update theMesh

)


arr = #()

--following one function written not by me. unfortunately i forgot where did i get it
fn SplitVertsByMapVerts theMesh =
(

	--first collect two arrays of bitarrays - one containing the map vertices for each mesh vertex,
	--the other containing the faces using each mesh vertex:
	--convertToMesh theMesh
	lastVert = theMesh.numverts
	lastFace = theMesh.numfaces
	VertsUsage = for v = 1 to lastVert collect #{}
	FaceUsage = for v = 1 to lastVert collect #{}
	for f = 1 to lastFace do
	(
		--get face vertex indexes
		theFace = getFace theMesh f

		theMapFace = meshop.getMapFace theMesh 1 f
		append VertsUsage[theFace.x] theMapFace.x
		append VertsUsage[theFace.y] theMapFace.y
		append VertsUsage[theFace.z] theMapFace.z
		append FaceUsage [theFace.x] f
		append FaceUsage [theFace.y] f
		append FaceUsage [theFace.z] f
	)
	--Now we can go though the mesh vertex array and see if we have 2 or more map vertices.
	--If yes, we count from 2 to the number of map verts and create new mesh vertices with the
	--same position as the current mesh vertex. Then we go through the list of collected faces
	--using that vertex and see which of the 3 components matches the current vertex and its
	--corresponding map vertex matches the current map vertex. We repoint that component of the face
	--to the new mesh vertex. Thus, for each previously existing map vertex, we get a new mesh vertex
	--at the end of the vertex list.

	arr = #()

	for v = 1 to VertsUsage.count do
	(
		theMapVertsArray = VertsUsage[v] as array
		if theMapVertsArray.count > 1 do
		(
			theFacesArray = FaceUsage[v] as array
			theVertPos = getVert theMesh v
			vertNorm = getNormal theMesh v
			/*vfaces = (meshop.getFacesUsingVert theMesh #{v}) as array
			useit = true
			smgr = undefined
			--if vfaces.count == 1 then useit = true
			if vfaces.count > 1 do
			(
				for vf = 1 to vfaces.count do
				(
					if smgr == undefined then smgr = getFaceSmoothGroup theMesh vfaces[vf]
					if (getFaceSmoothGroup theMesh vfaces[vf]) != smgr then useit = false
				)
			)
			if useit == true then arr = append arr #(v,vertNorm)*/
			arr = append arr #(v,vertNorm)
			for mapv = 2 to theMapVertsArray.count do
			(
				theMapVert = theMapVertsArray[mapv]
				newIndex = theMesh.numverts+1
				setNumVerts theMesh newIndex true
				setVert theMesh newIndex theVertPos
				--setNormal theMesh newIndex vertNorm
				arr = append arr #(newIndex,vertNorm)
				for f in theFacesArray do
				(
					theFaceDef = getFace theMesh f
					theMapFaceDef = meshOp.getMapFace theMesh 1 f
					if theMapFaceDef.x == theMapVert and theFaceDef.x == v do
					(
						theFaceDef.x = newIndex
						setFace theMesh f theFaceDef
					)
					if theMapFaceDef.y == theMapVert and theFaceDef.y == v do
					(
						theFaceDef.y = newIndex
						setFace theMesh f theFaceDef
					)
					if theMapFaceDef.z == theMapVert and theFaceDef.z == v do
					(
						theFaceDef.z = newIndex
						setFace theMesh f theFaceDef
					)
				)--end f loop
			)--end v loop
		)
	)
	update theMesh

)


fn nowgo file =
(
	f = fopen file "wb"

	WriteLong f 5456948 -- 4DS
	WriteShort f 29		--format version
	WriteLong f 343586816	--timestamp
	WriteLong f 29382754	--timestamp part 2

	scenemats2 = #()

	found = false
	i = 1
	while ((i <= scenematerials.count) and (found == false)) do
	(
		mat = scenematerials[i]
		print (i as string)
		if (mat.name == "$MAFIA_MATERIALS") then
		(
			print ("found: " + mat.name)
			found = true
			for j = 2 to mat.numSubs do
			(
				append scenemats2 mat[j]
				--print (mat[j] as string)
			)
		)
		i += 1
	)

	numMats = scenemats2.count
	print ("nummats: " + numMats as string)

	-- Materials
	WriteShort f numMats

	scenemats = scenemats2--#()

	for mat in scenemats2 do
	(
		writeMaterial f mat
		--print (mat.name as string)
	)

	-- Objects

	-- ######## COUNTING OBJECTS #########

	count=0

	for obj in $* do
	(
		if ( (Superclassof obj == Geometryclass  and classof obj != TargetObject) or classof obj == Dummy) then
		(
			ss = substring obj.name 1 4
			ss2 = substring obj.name 1 7
			mods = obj.modifiers
			if ((ss != "$lod") and (ss2 != "$portal")) then count += 1
		)
	)

	--num objects
	WriteShort f count #unsigned

	percent = 100.0 / count
	progress = 0

	objnum = 0
	parentArray = #()

	-- ######## WRITING OBJECTS #########

	--for obj in selection do
	for obj in $* do
	(
		ss = substring obj.name 1 4
		ss2 = substring obj.name 1 7
		mods = obj.modifiers
		objmod = mods[MafObject4]
		stype = ""
		if objmod != undefined then stype = objmod.subtypeName

		if  (( (Superclassof obj == Geometryclass and classof obj != TargetObject) or classof obj == Dummy)) and ((ss2 != "$portal") and (ss != "$lod")) then
		(
			print (" *******  " + ((obj.name) as string))

			--displayTempPrompt ((obj.name) as string) 1000


			objnum += 1
			parentArray = append parentArray obj

			--object type
			if stype == "Sector" then
			(
				WriteByte f 5
			)

			if classof obj == Dummy then
			(
				WriteByte f 6
			)
			if ((classof obj != Dummy) and (stype != "Sector")) then
			(
				WriteLong f 704643073
			)


			-- general block
			 -- hierarchy
			parentID = 0
			if obj.parent == undefined then WriteShort f 0
			if obj.parent != undefined do
			(
				for p = 1 to parentArray.count do
				(
					if parentArray[p] == obj.parent then (
						WriteShort f p
						parentID = p
					)
				)
			)
			
			in coordsys parent
			(
				WritePoint3 f obj.pos
				WritePoint3 f obj.scale

				q = obj.rotation
				WriteFloat f q.w
				WriteFloat f q.x
				WriteFloat f q.z
				WriteFloat f q.y
			)
			
			/*otrans = obj.objectTransform 
			if obj.parent != undefined then
			(
				otrans = obj.objectTransform * inverse obj.parent.objectTransform
			)

			WritePoint3 f otrans.translationpart
			WritePoint3 f otrans.scalepart

			q = otrans.rotationpart
			WriteFloat f q.w
			WriteFloat f q.x
			WriteFloat f q.z
			WriteFloat f q.y
*/

			if objmod == undefined then (
				if stype == "Sector" then
				(
					WriteByte f 125 #unsigned -- culling flag
				)
				else (
					WriteByte f 9 #unsigned -- culling flag
				)
			)
			else (
				cullingFlags = objmod.cullFlags
				writebyte f cullingFlags #unsigned
			)



			writetext f obj.name

			userParams = ""
			if objmod != undefined then userParams = objmod.userParams

			writetext f userParams        --write user parameters

			if stype == "Sector" then (
				WriteLong f 2049 #unsigned
				WriteLong f 0 #unsigned
				WriteLong f (obj.numverts) #unsigned
				Writelong f (obj.numfaces) #unsigned

				for i = 1 to obj.numverts do (
					pos = getvert obj i
					WritePoint3 f pos
				)

				for i = 1 to obj.numfaces do (
					vi = getface obj i
					writeshort f ((vi.x - 1) as integer) #unsigned
					writeshort f ((vi.z - 1) as integer) #unsigned
					writeshort f ((vi.y - 1) as integer) #unsigned
				)

				--for i = 1 to 6 do writefloat f 0    --bounding box
				WritePoint3 f obj.min
				WritePoint3 f obj.max

				numportals = 0
				portals_array = #()

				for child in obj.children  do (
					if child.modifiers[MafPortal4] != undefined then (
						append portals_array child
						numportals += 1
					)
				)

				WriteByte f numportals
				for portal in portals_array do (
					writebyte f (portal.numverts) #unsigned

					writelong f 4 #unsigned  						--always 4
					for j = 1 to 4 do writelong f 0  #unsigned  	--unknown


					modp = portal.modifiers[MafPortal4]

					nearRange = 0
					farRange = 10
					if (modp != undefined) then (
						nearRange = modp.nearRange
						farRange = modp.farRange
					)

					writefloat f nearRange   --nearrange
					writefloat f farRange  --farrange

					for j = 1 to portal.numverts do (
						pos = polyop.getvert portal j
						WritePoint3 f pos
					)
				)

			)
			else (





				if classof obj == Dummy then
				(
					in coordsys local
					(
						WritePoint3 f obj.min
						WritePoint3 f obj.max
					)
				)

				else
				(
					WriteShort f 0        --not duplicate


					lods_array = #()
					append lods_array obj
					for i = 1 to 9 do (
						found = false
						j = 1
						while (j <= obj.children.count) and (found == false) do (
							child = obj.children[j]
							ss = substring child.name 1 5   -- $lod1
							if ss == ("$lod" + (i as string)) then (
								found = true
								append lods_array child
							)
							j += 1
						)
					)

					numLods = lods_array.count
					writebyte f numLods

					for ilod = 1 to numLods do
					(
						print ("LOD" + ((ilod-1) as string) + ": " + lods_array[ilod].name)

						splitUV = MafiaTools.splitUV.checked
						splitNormal = MafiaTools.splitNormal.checked








						if splitUV == true then (

							lodmesh = snapshotAsMesh lods_array[ilod]
							if splitNormal == true then SplitVertsByNormals lodmesh
							SplitVertsByMapVerts lodmesh


							if MafiaTools.exportNormals.checked == true then (
								local mesh_norm = lods_array[ilod].modifiers[Edit_Normals]

								local norm_array = #()
								norm_array.count = lods_array[ilod].numverts

								-- Iterate through each normal and store its data for later use
								if mesh_norm != undefined then
								(
									max modify mode
									modpanel.setcurrentobject mesh_norm

									for j = 1 to mesh_norm.getnumfaces() do
									(
										for k in 1 to 3 do
										(
											local n = mesh_norm.getnormalid j k
											local v = mesh_norm.getvertexid j k

											if norm_array[v] == undefined then
												norm_array[v] = (mesh_norm.getnormal n)
										)
									)
								)
								else
								(
									for j = 1 to lods_array[ilod].numverts do
										norm_array[j] = (getnormal lods_array[ilod] j)
								)
							)










							writefloat f 0

							verts=getnumverts lodmesh
							WriteShort f verts #unsigned

							for i=1 to verts do
							(
								p01=GetVert lodmesh i
								--p01 -= obj.pos
								p01 = p01 * (inverse obj.transform)--(inverse obj.rotation)
								WriteFloat f p01.x
								WriteFloat f p01.z
								WriteFloat f p01.y




								p01=GetNormal lodmesh i
								for a = 1 to arr.count do
								(
									if (arr[a])[1] == i do
									(
										p01 = (arr[a])[2]
									--	print "!"
									)
								)
								--p01 = p01 * (inverse obj.transform)--(inverse obj.rotation)
								--p01 = normalize p01
								--p01 = [0,1,0]
								WriteFloat f p01.x
								WriteFloat f p01.z
								WriteFloat f p01.y


/*								writefloat f norm_array[i].x	-- Normal
								writefloat f norm_array[i].z
								writefloat f norm_array[i].y*/


								if meshop.getMapSupport lodmesh 1 then (
									face = ( (meshOp.getFacesUsingVert lodmesh #{i}) as array )[1]
									faceverts1 = getFace lodmesh face
									faceverts = #(faceverts1.x,faceverts1.y,faceverts1.z)
									corrVert = 1
									for j = 1 to faceverts.count do
									(
										if faceverts[j] == i then corrVert = j
									)
									mapface = meshOp.getMapFace lodmesh 1 face
									mapvert = mapface[corrVert]
									p01 = meshOp.getMapVert lodmesh 1 mapvert
									--p01=GetTVert m i
									WriteFloat f p01.x
									WriteFloat f (1-p01.y)
								)
								else (
									WriteFloat f 0
									WriteFloat f 0
								)
							)

							isMatIdUsed = #{}
							faces=getnumfaces lodmesh
							for i=1 to faces do
							(
								id = getFaceMatID lodmesh i
								isMatIdUsed[id] = true
							)
							isMatIdUsed = isMatIdUsed as array

							numFacegroups = isMatIdUsed.count
							WriteByte f numFacegroups -- facegroups

							facegroupFaces = #()
							facegroupMats = #()
							facegroupMats.count = numFacegroups
							for i = 1 to numFacegroups do
							(
								facegroupFaces[i] = #()
								for j = 1 to faces do
								(
									id = getFaceMatID lodmesh j
									if id == isMatIdUsed[i] then (
										facegroupFaces[i] =append facegroupFaces[i] j
										facegroupMats[i] = id
									)
								)
							)

							--for i = 1 to numFacegroups do
							for i = numFacegroups to 1 by - 1 do
							(
								--faces=getnumfaces m
								faces = facegroupFaces[i].count
								WriteShort f faces #unsigned

								for j=1 to faces do
								(
									p01=GetFace lodmesh (facegroupFaces[i])[j]
									x01=(p01.x-1) as integer
									y01=(p01.y-1) as integer
									z01=(p01.z-1) as integer
									WriteShort f x01
									WriteShort f z01
									WriteShort f y01
								)
								matid = ((facegroupMats[i]) - 1)
								WriteShort f matid #unsigned

							)
						) --end if splitUV == true
						else (





							lodmesh = lods_array[ilod].mesh
							lodmod = lods_array[ilod].modifiers[MafLod4]

							if lodmod != undefined then (
								writefloat f (lodmod.lodDist)
							)
							else (
								if ilod == numLods then (
									loddist = 0
								) else (
									loddist = ilod * 100
								)
								writefloat f loddist
							)

							-- VERTICES
							numVerts= getnumverts lodmesh
							WriteShort f numVerts #unsigned



							texture_coords = #()
							for count = 1 to lodmesh.numfaces do
							(
								local face = getFace lodmesh count
								local t_face = getTVFace lodmesh count


								texture_coords[face.x] = getTVert lodmesh t_face.x
								texture_coords[face.y] = getTVert lodmesh t_face.y
								texture_coords[face.z] = getTVert lodmesh t_face.z
							)




							for i=1 to numVerts do
							(
								--WRITE VERTEX
								in coordsys local p3 = GetVert lodmesh i
								WritePoint3 f p3

								--WRITE NORMALS



								if MafiaTools.exportNormals.checked == true then (
									writefloat f norm_array[i].x	-- Normal
									writefloat f norm_array[i].z
									writefloat f norm_array[i].y
								)
								else (
									p3 = GetNormal lodmesh i
									WritePoint3 f p3
								)




								--WRITE UV
								--p3 = gettvert lodmesh i
								--p3 = meshOp.getMapVert lodmesh 1 i
								--print (p3 as string)
								--WriteFloat f p3.x
								--WriteFloat f p3.y
								p3 = texture_coords[i]
								WriteFloat f p3.x
								WriteFloat f (1-p3.y)
							)


							isMatIdUsed = #{}
							numFaces = getNumFaces lodmesh
							for i = 1 to numFaces do
							(
								matId = getFaceMatID lodmesh i
								isMatIdUsed[matId] = true
							)
							mats_array = isMatIdUsed as array

							numFacegroups = mats_array.count
							WriteByte f numFacegroups -- facegroups


							print ("mats_array: " + (mats_array as string))

							----REORDER mats_array
							corrOrder = lodmod.matidOrder
							print ("corrOrder: " + (corrOrder as string))
							fullOrder = #()
							for i = 1 to corrOrder.count do (
								found = false
								j = 1
								while ((j <= mats_array.count) and (found == false)) do (
									if corrOrder[i] == mats_array[j] then (
										append fullOrder corrOrder[i]
										deleteItem mats_array j
										found = true
									)
									j += 1
								)
							)

							for i = 1 to mats_array.count do (
								append fullOrder mats_array[i]
							)



							print ("fullOrder: " + (fullOrder as string))

							-----

							facegroupFaces = #()
							--facegroupMats = #()
							--facegroupMats.count = numFacegroups
							for i = 1 to numFacegroups do
							(
								facegroupFaces[i] = #()
								for j = 1 to numFaces do
								(
									matId = getFaceMatID lodmesh j
									if matId == fullOrder[i] then (
										append facegroupFaces[i] j
										--facegroupMats[i] = id
									)
								)
							)

							for i = 1 to numFacegroups do
							--for i = numFacegroups to 1 by - 1 do
							(
								--faces=getnumfaces m
								faces = facegroupFaces[i].count
								WriteShort f faces #unsigned

								for j=1 to faces do
								(
									p01=GetFace lodmesh (facegroupFaces[i])[j]
									x01=(p01.x-1) as integer
									y01=(p01.y-1) as integer
									z01=(p01.z-1) as integer
									WriteShort f x01
									WriteShort f z01
									WriteShort f y01
								)
								--matid = ((facegroupMats[i]) - 1)
								matid = ((fullOrder[i]) - 1)

								WriteShort f matid #unsigned

							)





						) -- end - else - if splitUV == true





					)
				)
			)

			progress += percent
			--pbar.value = progress
			progressUpdate progress
		)
	)

	WriteShort f 0
	fclose f
)


------------------------
---------MAIN-----------
------------------------

asdfe = getFilenameFile maxFileName
file=GetSaveFileName types:"4DS file (*.4ds)|*.4ds|All files (*.*)|*.*" filename:asdfe
if file!=undefined do
(
	progressStart "4ds exporting"
	nowgo file
	progressEnd()
)