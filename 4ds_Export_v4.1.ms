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

		if (mat.useColorKey or mat.useAddBlend or mat.delegate.opacityMapEnable) then (
			sets += (bit.set 0 16 1)
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
		writetext f mat.reflectionMap.filename
	)

	--diffuse map
	if mat.diffuseMapEnable == false then WriteByte f 0
	if mat.diffuseMapEnable == true then writetext f mat.diffusemap.filename

	--opacity map
	if mat.opacityMapEnable == true do writetext f mat.opacitymap.filename

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
		if (classof mat == multimaterial) then
		(
			for i = 2 to mat.numSubs do
			(
				append scenemats2 mat[i]
				print (mat[i] as string)
			)
		)
		else (
			MessageBox "fuck"
		)
	)

	numMats = scenemats2.count
	print (numMats as string)

	-- Materials
	WriteShort f numMats

	scenemats = scenemats2--#()

	for mat in scenemats2 do
	(
		writeMaterial f mat
		print (mat.name as string)
	)

	-- Objects

	-- ######## COUNTING OBJECTS #########

	count=0

	for obj in $* do
	(
		if ( (Superclassof obj == Geometryclass  and classof obj != TargetObject) or classof obj == Dummy) then
		(
			ss = substring obj.name 1 4
			mods = obj.modifiers
			if ((mods[MafPortal] == undefined) and (ss != "$lod")) then count=count+1

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
		ss = substring obj.name 1 4
		mods = obj.modifiers
		objmod = mods[MafObject]
		if  (( (Superclassof obj == Geometryclass and classof obj != TargetObject) or classof obj == Dummy)) and ((mods[MafPortal] == undefined) and (ss != "$lod")) then
		(
			print (" *******  " + ((obj.name) as string))
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
			userParams = objmod.userParams
			writetext f userParams        --write user parameters



			if stype == "Sector" then (
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

				--for i = 1 to 6 do writefloat f 0    --bounding box
				writefloat f obj.min.x
				writefloat f obj.min.z
				writefloat f obj.min.y
				writefloat f obj.max.x
				writefloat f obj.max.z
				writefloat f obj.max.y


				numportals = 0
				portals_array = #()
				--pmods_array = #()

				--kek = (obj.children as array)

				for child in obj.children  do (
					--print (child as string)
					--mods = child.modifiers
					/*for mm = 1 to mods.count do
					(
						if classof mods[mm] == MafSubtype then
						(
							pmod = mods[mm].subtypeName
						)
					)*/
					if child.modifiers[MafPortal] != undefined then (
						append portals_array child
						--append pmods_array cmod
						numportals += 1
						print (obj.name+" -- portal: "+child.name)
					)
				)

				--portals_array = $

				WriteByte f numportals
				for portal in portals_array do (
					writebyte f (portal.numverts) #unsigned
					print ("portal: " + portal.name + "   numverts: " + (portal.numverts as string))

					writelong f 4 #unsigned  						--always 4
					for j = 1 to 4 do writelong f 0  #unsigned  	--unknown

					/*mods = portal.modifiers
					local modp
					for mm = 1 to mods.count do
					(
						if classof mods[mm] == MafSubtype then
						(
							modp = mods[mm]
						)
					)*/
					modp = portal.modifiers[MafPortal]

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


					lods_array = #()
					append lods_array obj
					for i = 1 to 9 do (
						for child in obj.children do (
							ss = substring child.name 1 5   -- $lod1
							if ss == ("$lod" + (i as string)) then (
								append lods_array child
							)
						)

					)

					numLods = lods_array.count
					writebyte f numLods
					print ("numlods: " + (numlods as string))














/*
					lodMods = #()
					for mm = 1 to mods.count do
					(
						if classof mods[mm] == MafLOD then insertItem mods[mm] lodMods 1 --append lodMods mods[mm]
					)


					numLods = lodMods.count
					WriteByte f numLods

					print ("numlods: " + (numlods as string))*/

					lodmesh = obj.mesh

					for ilod = 1 to numLods do
					(
						print ("ilod: " + (ilod as string))
						--lodmod = lodMods[ilod]
						--lodmod = lods_array[ilod]
						--print ("lodnum: " + (lodmod.lodNum as string))
						if ilod > 1 then lodmesh = lods_array[ilod].mesh


						--if (ilod == 1 and numLods > 1) then (
					--		writefloat f 700  --lod distance
						--)
						--else writefloat f 0


						writefloat f (lods_array[ilod].modifiers[MafLod].lodDist)

						-- VERTICES
						numVerts= getnumverts lodmesh
						WriteShort f numVerts #unsigned


						for i=1 to numVerts do
						(

							in coordsys local p3 = GetVert lodmesh i
							WriteFloat f p3.x	--WRITE VERTEX
							WriteFloat f p3.z
							WriteFloat f p3.y

							p3 = GetNormal lodmesh i
							WriteFloat f p3.x    --WRITE NORMALS
							WriteFloat f p3.z
							WriteFloat f p3.y

							p3 = gettvert lodmesh i
							WriteFloat f p3.x    --WRITE UV
							WriteFloat f (1-p3.y)
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
					)
				)
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