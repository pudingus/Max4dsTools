-- 4ds exporter script by Mr F

-- mat flags:
-- 1 default
-- 9 reflectionMapEnable ? alpha reflection?
-- 10 smth about reflmap??
-- 11 additive reflection
-- 13 - ? smth about reflmap?? other formula?
-- 16 additional ??
-- 17 - ?
-- 18  - ?
-- 19 diffuseMapEnable ?
-- 20 reflectionMapEnable ?
-- 21 - ?
-- 22 - ?
-- 23 - ?
-- 24 mipmapping
-- 26 animalpha
-- 27 anim
-- 29 twoSided
-- 30 colorkey
-- 31 - ? smth about reflection ?
-- 32 opacityMapEnable
-- 32 addblend

fn compareFN v1 v2 =
(
	r = 0
	if v1.lodNum > v2.lodNum then r = 1
	if v1.lodNum < v2.lodNum then r = -1
	r
)

fn WriteMString f texname =
(
	lastSlash = 1
	for i = 1 to texname.count do
	(
		if texname[i] == "\\" then lastSlash = i+1
	)
	news = ""
	for i = lastSlash to texname.count do
	(
		append news texname[i]
	)
	WriteByte f news.count
	WriteString f news
	fseek f ((ftell f)-1) #seek_set
)

fn writeMaterial f mat =
(
	--print mat.name
	isAnim = false
	animFrames = undefined
	animDelay = undefined
	isAddRefl = false
	isDiffReflAxis = false
	sets = 0
	sets += (bit.set 0 1 true)
	--sets += (bit.set 0 16 true) --separate render state ?
			--sets += (bit.set 0 26 true)
			--sets += (bit.set 0 31 true)
		--mipmapping
	if classof mat == Standard then sets += (bit.set 0 24 true)
	if classof mat == MafMat do
	(
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
		isAddRefl = mat.useAddRefl
		isDiffReflAxis = mat.diffReflAxis
		mat = mat[#Standard]
	)
	--sets += (bit.set 0 30 true) -- color key ?
	if mat.diffuseMapEnable == true then sets += (bit.set 0 19 true)
	if mat.reflectionMapEnable == true then
	(
		sets += (bit.set 0 20 true)
		sets += (bit.set 0 9 true)
		sets += (bit.set 0 11 isAddRefl)
		sets += (bit.set 0 13 isDiffReflAxis)
	)
	if mat.opacityMapEnable == true then sets += (bit.set 0 31 true)
	if mat.twoSided == true then sets +=  (bit.set 0 29 true)
	--sets = (bit.set 0 1 true) + (bit.set 0 16 true) + (bit.set 0 19 true) + (bit.set 0 24 true) + (bit.set 0 26 true) + (bit.set 0 31 true)
	WriteLong f  sets --(262145) -- settings
	--ambient
	WriteFloat f (mat.ambient.r/255.0)
	WriteFloat f (mat.ambient.g/255.0)
	WriteFloat f (mat.ambient.b/255.0)
	--diffuse
	WriteFloat f (mat.diffuse.r/255.0)
	WriteFloat f (mat.diffuse.g/255.0)
	WriteFloat f (mat.diffuse.b/255.0)
	--selfIllum
	if mat.useSelfIllumColor==true do
	(
		WriteFloat f (mat.selfIllumColor.r/255.0)
		WriteFloat f (mat.selfIllumColor.g/255.0)
		WriteFloat f (mat.selfIllumColor.b/255.0)
	)
	if mat.useSelfIllumColor==false do
	(
		WriteFloat f 0
		WriteFloat f 0
		WriteFloat f 0
	)
	--opacity
	WriteFloat f (mat.opacity / 100.0)

	--reflection map
	if mat.reflectionMapEnable == true do
	(
		WriteFloat f (mat.reflectionMapAmount/100.0)
		WriteMString f mat.reflectionMap.filename
	)

	--diffuse map
	if mat.diffuseMapEnable == false then WriteByte f 0
	if mat.diffuseMapEnable == true then WriteMString f mat.diffusemap.filename

	--opacity map
	if mat.opacityMapEnable == true do WriteMString f mat.opacitymap.filename

	if isAnim == true do
	(
		WriteByte f animFrames
		WriteByte f 0
		WriteLong f 0
		WriteLong f animDelay
		WriteLong f 0
		WriteLong f 0
	)
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

fn nowgo pbar file =
(
	f = fopen file "wb"

	WriteLong f 5456948 -- 4DS
	WriteShort f 29		--format version
	WriteLong f 343586816	--timestamp
	WriteLong f 29382754	--timestamp part 2

	scenemats2 = #()
	for mat in scenematerials do
	(
		if (classof mat == standard) or (classof mat == MafMat) then scenemats2 = append scenemats2 mat
		if (classof mat == multimaterial) do
		(
			for i = 1 to mat.numSubs do
			(
				approve = true
				for j = 1 to scenemats2.count do
				(
					if mat[i] == scenemats2[j] then approve = false
				)
				if approve == true then scenemats2 = append scenemats2 mat[i]
			)
		)
	)

--	numMats = 0
--	for mat in scenemats2 do
--	(
--		if (classof mat == standard) or (classof mat == MafMat) then numMats += 1
--	)
	numMats = scenemats2.count

	-- Materials
	WriteShort f (numMats + 1)

	WriteLong f 0 -- flags
	--ambient
	WriteFloat f 0
	WriteFloat f 0
	WriteFloat f 0
	--diffuse
	WriteFloat f 1
	WriteFloat f 1
	WriteFloat f 1
	--emission / selfIllum
	WriteFloat f 0
	WriteFloat f 0
	WriteFloat f 0
	--opacity
	WriteFloat f 1

	--diff
	WriteByte f 0

	scenemats = scenemats2--#()

	for mat in scenemats2 do
	(
--		if (classof mat == standard) or (classof mat == MafMat)  do
--		(
			writeMaterial f mat
			--scenemats = append scenemats mat
--		)
/*		if classof mat == multimaterial do
		(
			for i = 1 to mat.numSubs do
			(
				writeMaterial f mat[i]
				scenemats = append scenemats mat[i]
			)
		)*/
	)

	-- Objects

	-- ######## COUNTING OBJECTS #########

	count=0

	for obj in $* do
	(
		if ( (Superclassof obj == Geometryclass  and classof obj != TargetObject) or classof obj == Dummy) then
		(

			mods = obj.modifiers
			stype = ""
			for mm = 1 to mods.count do
			(
				if classof mods[mm] == MafSubtype then
				(
					stype = mods[mm].subtypeName
				)
			)
			if ((obj.ishidden == false) and (stype != "Portal")) then count=count+1

		)
	)

	--num objects
	WriteShort f count #unsigned

	percent = 100.0 / count
	progress = 0

	objnum = 0
	parentArray = #()

	-- ######## WRITING OBJECTS #########

	for obj in $* do
	(
		mods = obj.modifiers
		stype = ""
		local modf
		for mm = 1 to mods.count do
		(
			if classof mods[mm] == MafSubtype then
			(
				stype = mods[mm].subtypeName
				modf = mods[mm]
			)
		)

		if  (( (Superclassof obj == Geometryclass  and classof obj != TargetObject) or classof obj == Dummy)) and ((obj.ishidden == false) and (stype != "Portal")) then
		(
			objnum += 1
			parentArray = append parentArray obj

			--object type
			if stype == "Sektor" then
			(
				WriteByte f 5
			)

			if classof obj == Dummy then
			(
				WriteByte f 6
			)
			if ((classof obj != Dummy) and (stype != "Sektor")) then
			(
		--		m = convertToMesh (copy obj)--snapshotAsMesh obj
		--		SplitVertsByNormals m
		--		SplitVertsByMapVerts m
				WriteLong f 704643073
			)


			-- general block
			 -- hierarchy
			if obj.parent == undefined then WriteShort f 0
			if obj.parent != undefined do
			(
				for p = 1 to parentArray.count do
				(
					if parentArray[p] == obj.parent then WriteShort f p
				)
			)
			in coordsys parent
			(
				WriteFloat f obj.pos.x
				WriteFloat f obj.pos.z
				WriteFloat f obj.pos.y
				WriteFloat f obj.scale.x
				WriteFloat f obj.scale.z
				WriteFloat f obj.scale.y
				--rot = obj.rotation as eulerangles
				--rot.z = -rot.z
				--q = (rot as quat)
				q = obj.rotation
				WriteFloat f q.w
				WriteFloat f q.x
				WriteFloat f q.z
				WriteFloat f q.y
			)
			
			if modf == undefined then (
				if stype == "Sektor" then
				(
					WriteByte f 125 #unsigned -- culling flag
				)
				else (
					WriteByte f 9 #unsigned -- culling flag
				)
			)
			else (
				cullingFlags = modf.cullFlags
				writebyte f cullingFlags #unsigned
			)

			
			
			WriteByte f obj.name.count #unsigned  --write name length
			WriteString f obj.name       --write name
			fseek f ((ftell f)-1) #seek_set               --maybe to rewrite null termination?
			--WriteByte f 0

			--mods = obj.modifiers
			--stype = ""
			--for mm = 1 to mods.count do
			--(
			--	if classof mods[mm] == MafSubtype then
			--	(
			--		stype = mods[mm].subtypeName
			--	)
			--)
			WriteMString f stype         --write user parameters



			if stype == "Sektor" then (
				WriteLong f 2049 #unsigned
				WriteLong f 0 #unsigned
				WriteLong f (obj.numverts) #unsigned
				Writelong f (obj.numfaces) #unsigned

				for i = 1 to obj.numverts do (
					pos = getvert obj i
					WriteFloat f pos.x
					writefloat f pos.z
					writefloat f pos.y
				)

				for i = 1 to obj.numfaces do (
					vi = getface obj i
					writeshort f ((vi.x - 1) as integer) #unsigned
					writeshort f ((vi.z - 1) as integer) #unsigned
					writeshort f ((vi.y - 1) as integer) #unsigned
				)

				for i = 1 to 6 do writefloat f 0    --bounding box


				numportals = 0
				portals_array = #()

				--kek = (obj.children as array)

				for portal in obj.children  do (
					--print (portal as string)
					mods = portal.modifiers
					pstype = ""
					for mm = 1 to mods.count do
					(
						if classof mods[mm] == MafSubtype then
						(
							pstype = mods[mm].subtypeName
						)
					)
					if pstype == "Portal" then (
						append portals_array portal
						numportals += 1
						print (obj.name+" -- portal: "+portal.name)
					)
				)

				--portals_array = $

				WriteByte f numportals
				for portal in portals_array do (
					writebyte f (portal.numverts) #unsigned
					print ("portal: " + portal.name + "   numverts: " + (portal.numverts as string))
					for j = 1 to 5 do writelong f 0  #unsigned  --unknown
						
					mods = portal.modifiers
					local modp
					for mm = 1 to mods.count do
					(
						if classof mods[mm] == MafSubtype then
						(
							modp = mods[mm]
						)
					)
					
					nearRange = 0
					farRange = 0
					if (modp != undefined) then (
						nearRange = modp.nearRange
						farRange = modp.farRange
					)
					
					print ("nearRange: " + (nearRange as string) + " -- farRange: " + (farRange as string))
					
					writefloat f nearRange   --nearrange
					writefloat f farRange  --farrange

					for j = 1 to portal.numverts do (
						pos = polyop.getvert portal j
						writefloat f pos.x
						writefloat f pos.z
						writefloat f pos.y
						print ("vert --- " + (pos as string))
					)
				)

			)
			else (



				if classof obj == Dummy then
				(
					in coordsys local
					(
						WriteFloat f obj.min.y
						WriteFloat f obj.min.y
						WriteFloat f obj.min.y
						WriteFloat f obj.max.y
						WriteFloat f obj.max.y
						WriteFloat f obj.max.y
					)
				)

				else
				(

					WriteShort f 0        --not duplicate

					lodMods = #()
					for mm = 1 to mods.count do
					(
						if classof mods[mm] == MafLOD then lodMods = append lodMods mods[mm]
					)

					qsort lodMods compareFN

					WriteByte f (lodMods.count+1)  --write num lods

					lodmesh = m
					lodobj = obj

					for ilod = 1 to (lodMods.count+1) do
					(
						if ilod>1 then lodmesh = lodMods[ilod-1].lodMesh
						if ilod>1 then lodobj = lodMods[ilod-1].lodMesh

						lodmesh = snapshotAsMesh lodobj--convertToMesh (copy lodobj)
						SplitVertsByNormals lodmesh
						if meshop.getMapSupport lodmesh 1 do
						SplitVertsByMapVerts lodmesh
						if ilod==1 then m=lodmesh

						--WriteShort f 0
						--WriteShort f 0--17786 -- lod distance
						if (lodMods.count==0) or (ilod==(lodMods.count+1)) then WriteLong f 0
						if (lodMods.count > 0) and (ilod<(lodMods.count+1)) do
						(
							loddist = lodMods[ilod].lodDist
							WriteFloat f (loddist*1000)
						)

						-- VERTICES
						verts=getnumverts lodmesh
						WriteShort f verts #unsigned

						in coordsys world
						(
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
									--WriteFloat f 0
									--WriteFloat f 0
								) else (
									WriteFloat f 0
									WriteFloat f 0
								)
							)
						)

						useMatIDs = true
						if usematids==false do
						(
							WriteByte f 1
							faces=getnumfaces lodmesh
							WriteShort f faces #unsigned
							for j=1 to faces do
							(
								p01=GetFace lodmesh j
								x01=(p01.x-1) as integer
								y01=(p01.y-1) as integer
								z01=(p01.z-1) as integer
								WriteShort f y01
								WriteShort f x01
								WriteShort f z01
							)
							WriteShort f 1
						)

						if usematids==true do
						(
							--faces_array = GetNodeFacesByMatID lodmesh




							---------
							hasFaceMatID = #{}
							faces=getnumfaces lodmesh
							for i=1 to faces do
							(
								id = getFaceMatID lodmesh i
								hasFaceMatID[id] = true
							)
							hasFaceMatID = hasFaceMatID as array

							WriteByte f hasFaceMatID.count -- facegroups

							mIdFaces = #()
							for i = 1 to hasFaceMatID.count do
							(
								mIdFaces[i] = #()
								for j = 1 to faces do
								(
									id = getFaceMatID lodmesh j
									if id == hasFaceMatID[i] then mIdFaces[i] =append mIdFaces[i] j
								)
							)

							for i = 1 to hasFaceMatID.count do
							(
								--faces=getnumfaces m
								faces = mIdFaces[i].count
								WriteShort f faces #unsigned

								for j=1 to faces do
								(
									p01=GetFace lodmesh (mIdFaces[i])[j]
									x01=(p01.x-1) as integer
									y01=(p01.y-1) as integer
									z01=(p01.z-1) as integer
									WriteShort f y01
									WriteShort f x01
									WriteShort f z01
								)
								-- material
								if lodobj.material == undefined then WriteShort f 1
								if lodobj.material != undefined do
								(
									chosen = 1
									for s = 1 to scenemats.count do
									(
										if (classof lodobj.material == standard) or (classof lodobj.material == MafMat) do
										(
											if scenemats[s] == lodobj.material then chosen = s + 1
										)
										if classof lodobj.material == multimaterial do
										(
											if scenemats[s] == (lodobj.material)[i] then chosen = s + 1--WriteShort f (s+1)
										)
									)
									WriteShort f chosen
								)
							)
						)
						delete lodmesh

					) -- end for lods


				) -- end ifdummy check
			)

			progress += percent
			pbar.value = progress
		)
	)

	WriteShort f 0
	fclose f
)

utility MafiaExport "4DS Export v4.1"
(
	button b "Export"
	progressbar pbar
	label bout "Original author Mr F"

	on b pressed do
	(
		file=GetSaveFileName types:"4DS file (*.4ds)|*.4ds|All files (*.*)|*.*"
		if file!=undefined do
		(
			nowgo pbar file
			pbar.value = 100
		)
	)
)

-- rollout i4exp "4DS Export v3"
-- (
-- 	group "4DS Export v3"
-- 	(
-- 		button b "Go"
-- 	--	button d "Split"
-- 		progressbar pbar
-- 		label bout "Original author Mr F"
-- 	)
--
-- 	on b pressed do
-- 	(
-- 		file=GetSaveFileName types:"4DS file (*.4ds)|*.4ds|All files (*.*)|*.*"
-- 	        	if file!=undefined do
-- 		(
-- 			nowgo pbar file
-- 			pbar.value = 100
-- 		)
-- 	)
--
-- 	on d pressed do
-- 	(
-- 		SplitVertsByMapVerts (convertToMesh selection[1])
-- 	)
-- )

-- mrfloater = newRolloutFloater "4DS" 320 125
-- addRollout i4exp mrfloater

--And all the ladies are like "Yes, yes".
--Another system under stress stress.
--Forget about it, lose that dress dress.
--Oh, give me a hug!