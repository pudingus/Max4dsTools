(

local debug = false

fn WriteText f txt = (
	if txt == undefined then (
		WriteByte f 0 #unsigned
	)
	else (
		local count = txt.count
		if count > 255 then (
			count = 255
			messageBox ("String '" + txt + "' is over the maximum of 255 characters!") icon:#warning
		)
		WriteByte f count #unsigned
		for i = 1 to count do
			WriteByte f (bit.charasint txt[i])
	)
)

fn WriteColor f clr = (
	WriteFloat f (clr.r / 255.0)
	WriteFloat f (clr.g / 255.0)
	WriteFloat f (clr.b / 255.0)
)

fn WriteHeader f = (
    WriteLong f 5456948 	-- 4DS
	WriteShort f 29			--format version
	WriteLong f 343586816	--timestamp
	WriteLong f 29382754	--timestamp part 2
)

fn GetModByClass obj mclass = (    --to support versions prior 2013
	local found = false	
	local foundMod
	for modd in obj.modifiers while not found do (
		if classof modd == mclass then (
			found = true
			foundMod = modd
		)
	)
	foundMod
)

local mafia_materials = #()
local mat_map = #()

fn WriteMaterials f =
(
	for mat in sceneMaterials do (
		if isKindOf mat MultiMaterial then (
			for submat in mat.materialList where submat != undefined do (
				local handle = GetHandleByAnim submat

				if mat_map[handle] == undefined then (
					append mafia_materials submat
					mat_map[handle] = mafia_materials.count
				)
			)

		)
		else (
			local handle = GetHandleByAnim mat

			if mat_map[handle] == undefined then (
				append mafia_materials mat
				mat_map[handle] = mafia_materials.count
			)
		)
	)

	--for mat in mafia_materials do print mat
	--for matm in mat_map where matm != undefined do print matm

	

	
	
	local numMats = mafia_materials.count
	WriteShort f numMats
	
	for mat in mafia_materials do (

		local flags = 0
		flags += (bit.set 0 1 true)

		if classof mat == Standard then (
			flags += (bit.set 0 19 mat.diffuseMapEnable)
			flags += (bit.set 0 20 mat.reflectionMapEnable)
			flags += (bit.set 0 31 mat.opacityMapEnable)
			if mat.opacityMapEnable then flags += (bit.set 0 16 true) --add effect
			flags += (bit.set 0 24 true) --mipmapping
			flags += (bit.set 0 29 mat.twoSided)
			if mat.reflectionMapEnable then flags += (bit.set 0 9 true) --overlay

			WriteLong f flags

			WriteColor f mat.ambient
			WriteColor f mat.diffuse
			WriteColor f mat.selfIllumColor

			WriteFloat f (mat.opacity / 100.0)

			--env map
			if mat.reflectionMapEnable then (
				WriteFloat f (mat.reflectionMapAmount / 100.0)

				if mat.reflectionMap != undefined then (
					local filename = filenameFromPath mat.reflectionMap.filename
					WriteText f filename
				)
				else WriteByte f 0
			)

			--diffuse map
			if (mat.diffuseMapEnable) and (diffuseMap != undefined) then (
				local filename = filenameFromPath mat.diffuseMap.filename
				WriteText f filename

				--alpha map
				if mat.opacityMapEnable then (
					local filename = filenameFromPath mat.opacityMap.filename
					WriteText f filename
				)
			)
			else WriteByte f 0

		)
		else if classof mat == MafMat4 then	(	
			flags += (bit.set 0 9 mat.envOverlay)
			flags += (bit.set 0 10 mat.envMultiply)
			flags += (bit.set 0 11 mat.envAdditive)

			flags += (bit.set 0 13 mat.YProj)
			flags += (bit.set 0 14 mat.YDetail)
			flags += (bit.set 0 15 mat.ZDetail)
			flags += (bit.set 0 16 mat.addEffect)

			flags += (bit.set 0 19 mat.diffuseMapEnable)
			flags += (bit.set 0 20 mat.envMapEnable)
			
			flags += (bit.set 0 24 mat.mipMapping)   --

			flags += (bit.set 0 26 mat.animatedAlpha)
			flags += (bit.set 0 27 mat.animatedDiffuse)
			flags += (bit.set 0 28 mat.colored)  --
			flags += (bit.set 0 29 mat.twoSided)			
			flags += (bit.set 0 30 mat.colorKey)  --
			flags += (bit.set 0 31 mat.alphaMapEnable)
			flags += (bit.set 0 32 mat.additiveMixing)   --

			WriteLong f flags
		
			WriteColor f mat.ambient
			WriteColor f mat.diffuse
			WriteColor f mat.emission
			
			WriteFloat f (mat.opacity / 100.0)
		
			--env map
			if mat.envMapEnable then (
				WriteFloat f (mat.envMapAmount / 100.0)

				if mat.envMap != undefined then (
					local filename = filenameFromPath mat.envMap.filename
					WriteText f filename
				)
				else WriteByte f 0
			)
		
			--diffuse map
			if (mat.diffuseMapEnable) and (diffuseMap != undefined) then (			
				local filename = filenameFromPath mat.diffuseMap.filename
				WriteText f filename

				--alpha map
				if mat.alphaMapEnable then (
					local filename = filenameFromPath mat.alphaMap.filename
					WriteText f filename
				)			
			)
			else WriteByte f 0
		
			if mat.animatedDiffuse then (
				WriteByte f mat.animFrames
				WriteByte f 0
				WriteLong f 0
				WriteLong f mat.animPeriod
				WriteLong f 0
				WriteLong f 0
			)
		)
	
		
	)
		
)

fn IsGeometry obj =
(
	Superclassof obj == GeometryClass and ClassOf obj != TargetObject
)

fn CompareNames obj1 obj2 = stricmp obj1.name obj2.name

struct MObject (
	type,
	objectType,
	visualType,
	baseNode,
	lods = #(),
	portals = #(),
	parentID = 0,
	instanceID = 0,

	fn OnCreate = (
		if type == #mesh then (
			objectType = 1
			visualType = 0
		)
		else if type == #sector then (
			objectType = 5
		)
		else if type == #dummy then (
			objectType = 6
		)
		else if type == #billboard then (
			objectType = 1
			visualType = 4
		)

		true
	),

	initialized = OnCreate()
)

struct TObjectSet (
	mobjects = #(), 		--list of objects as they are about to be exported
	mobject_ids = #(),		--key = node handle, value = id in mobjects

	fn GetIdFromHandle handle = (    --Get Mafia object id from node handle
		mobject_ids[handle]
	),

	fn GetByNode obj = (           --Get MObject from node
		local handle = obj.inode.handle
		local mid = GetIdFromHandle handle
		mobjects[mid]
	),

	fn Add mobj = (          --Add MObject to collection
		local handle = mobj.baseNode.inode.handle				
		append mobjects mobj
		mobject_ids[handle] = mobjects.count
	)	
)


fn CollectObjects = (
	local mobjSet = TObjectSet()

	for obj in objects do (
		local mobj

		if IsGeometry obj then (  --can be sector, portal, regular mesh, lod...
			if matchPattern obj.name pattern:"$portal*" then (
				if obj.parent != undefined then (
					local parent_mobj = mobjSet.GetByNode obj.parent
					append parent_mobj.portals obj
				)
			)
			else if matchPattern obj.name pattern:"$lod*" then (
				if obj.parent != undefined then (
					local parent_mobj = mobjSet.GetByNode obj.parent
					append parent_mobj.lods obj
				) 
			)
			else (			
				if matchPattern obj.name pattern:"sector*" then (					
					mobj = MObject type:#sector
				)				
				else (					
					local gp = custAttributes.get obj MafParams_def baseObject:false
					if (gp != undefined) and (stricmp gp.objectType "billboard" == 0) then (
						mobj = MObject type:#billboard
					)
					else (
						mobj = MObject type:#mesh
					)
				)
			)

		) 
		else if isKindOf obj Dummy then (
			mobj = MObject type:#dummy
		)


		if mobj != undefined then (	
			local instances
			local count = InstanceMgr.GetInstances obj &instances
			local masterInstance = instances[count]	
			
			if masterInstance != obj then (  --search for instance id
				mobj.instanceID = mobjSet.GetIDFromHandle masterInstance.inode.handle
			)
		
			mobj.baseNode = obj
			if obj.parent != undefined then (
				mobj.parentID = mobjSet.GetIDFromHandle obj.parent.inode.handle
			)		
			mobjSet.Add mobj
		)
	)

	for mobj in mobjSet.mobjects do (
		qsort mobj.lods CompareNames
		qsort mobj.portals CompareNames
	)
	
	-- if debug then (
	-- 	local id = 0
	-- 	for mobj in mobjSet.mobjects do (
	-- 		format "\n%: % ot:% vt:%" id mobj.baseNode.name mobj.objectType mobj.visualType
	-- 		for lodd in mobj.lods do (
	-- 			format "\n  %" lodd.name 
	-- 		)
	-- 		for prtl in mobj.portals do (
	-- 			format "\n  %" prtl.name 
	-- 		)
	-- 		id = id + 1
	-- 	)
	-- )	

	mobjSet
	--mobjects
)


fn WritePoint3 f p3 = (
	WriteFloat f p3.x
	WriteFloat f p3.z
	WriteFloat f p3.y
)

fn WriteQuat f q = (
	WriteFloat f q.w
	WriteFloat f q.x
	WriteFloat f q.z
	WriteFloat f q.y
)

fn WriteFace f face = (
	a = (face[1] - 1) as integer  --vertices are indexed from 0 in 4ds, from 1 in max
	b = (face[3] - 1) as integer
	c = (face[2] - 1) as integer
	Writeshort f a #unsigned
	Writeshort f b #unsigned
	Writeshort f c #unsigned
)

fn WriteUV f uv = (
	WriteFloat f uv.x
	WriteFloat f (1 - uv.y)
)

fn WriteSector f mobj = (
	WriteLong f 2049    --unknown
	WriteLong f 0		--unknown

	--local smesh = copy mobj.baseNode.mesh
	local smesh = snapshotAsMesh mobj.baseNode

	local numVerts = smesh.numVerts
	local numFaces = smesh.numFaces

	WriteLong f numVerts
	WriteLong f numFaces

	for i = 1 to numVerts do (
		local vert = getVert smesh i
		WritePoint3 f vert
	)

	for i = 1 to numFaces do (
		local face = getFace smesh i
		WriteFace f face
	)

	WritePoint3 f mobj.baseNode.min
	WritePoint3 f mobj.baseNode.max

	WriteByte f mobj.portals.count

	for portal in mobj.portals do (
		local vertIds = polyop.getFaceVerts portal 1
		local numVerts = vertIds.count

		WriteByte f numVerts
		WriteLong f 4					--unknown
		for i = 1 to 4 do WriteLong f 0	--unknown

		local nearRange = 0.0
		local farRange = 10.0
		local gp = custAttributes.get portal MafParams_def baseObject:false
		
		if gp != undefined then (
			nearRange = gp.nearRange
			farRange = gp.farRange
		)		

		WriteFloat f nearRange
		WriteFloat f farRange

		for id in vertIds do (
			local vert = polyop.getVert portal id
			WritePoint3 f vert
		)
	)
)

fn WriteDummy f mobj = (
	in coordsys local (
		WritePoint3 f mobj.baseNode.min
		WritePoint3 f mobj.baseNode.max
	)
)

struct MVert (
	key, --string
	pos,	--Point3
	normal,	--Point3
	uv		--Point3 (Point2)
)

struct MFacegroup (
	faces = #(),    -- array of 3-element array
	matid	  -- short int
)

struct MLod (
	verts = #(),  --array of MVert
	facegroups = #(),   --array of MFacegroup
	facegroup_ids = #(),
	loddist,

	fn GetFacegroupFromMatID matid = (
		matid = matid + 1
		local grp_id = facegroup_ids[matid]	

		if grp_id == undefined then (
			local grp = MFacegroup matid:matid
			append facegroups grp
			facegroup_ids[matid] = facegroups.count
			grp_id = facegroups.count
		)
		facegroups[grp_id]
	)
)


fn GetMafiaMatId mat matid = (
	local subMat = mat
	if isKindOf mat MultiMaterial then (
		subMat = mat[matid]		
	)
	
	local mid
	if subMat == undefined then (
		mid = 0
	)
	else (
		local handle = getHandleByAnim subMat
		mid = mat_map[handle]
	)	

	mid
)


--returns array of MLod
fn CollectLodsCompat mobj = (	
	local lodnodes = copy mobj.lods #noMap
	insertItem mobj.baseNode lodnodes 1

	local m_lods = #()
	local prevDist = 0.0

	for lodnode in lodnodes do (
		local lodmesh = copy lodnode.mesh
		local m_lod = MLod()
		local gp = custAttributes.get lodnode MafParams_def baseObject:false
		
		if gp != undefined then (
			m_lod.loddist = gp.lodDist
		)
		else (
			if lodnode == lodnodes[lodnodes.count] then m_lod.loddist = 0.0
			else m_lod.loddist = prevDist + 100.0
		)
		
		prevDist = m_lod.loddist

		local normMod
		if MafiaTools.exportNormals.state == 2 then normMod = GetModByClass lodnode Edit_Normals
		-----

		local normals = #()

		if normMod != undefined then (
			max modify mode
			modpanel.setcurrentobject normMod node:lodnode

			local EN_getnormalid = normMod.getnormalid
			local EN_getvertexid = normMod.getvertexid
			local EN_getnormal = normMod.getnormal

			for j = 1 to normMod.getnumfaces() do (
				for k in 1 to 3 do (
					local n = EN_getnormalid j k
					local v = EN_getvertexid j k
					normals[v] = EN_getnormal n
				)
			)
		)


		for i = 1 to lodmesh.numVerts do (
			local vert = (in coordsys local getVert lodmesh i) + lodnode.objectOffsetPos
			local tvert = getTVert lodmesh i
			local normal
			
			if normMod != undefined then (
				normal = normals[i]
			)
			else (
				normal = getNormal lodmesh i
			)

			local m_vert = MVert pos:vert normal:normal uv:tvert
			append m_lod.verts m_vert
		)		

		for i = 1 to lodmesh.numfaces do (
			local face = getFace lodmesh i
			local matid = getFaceMatID lodmesh i
			local m_matid = GetMafiaMatId (lodnode.mat) matid
			local m_facegroup = m_lod.GetFacegroupFromMatID m_matid
			append m_facegroup.faces face
		)

		append m_lods m_lod
	)

	m_lods
)



fn CompareVerts mvert1 mvert2 = stricmp mvert1.key mvert2.key

fn CompareVertsB mkey index mverts: = (
	currentKey = mverts[index].key
	stricmp mkey currentKey
)


fn CollectVerts lodmesh lodnode = (
	local EN_getnormalid 
	local EN_getnormal
	if normmod != undefined then (
		max modify mode
		modpanel.setcurrentobject normmod node:lodnode
		
		EN_getnormalid = normmod.getnormalid
		EN_getnormal =  normmod.getnormal
	)	

	local verts_big_unsorted = #()

	for i = 1 to lodmesh.numfaces do (
		local face = getFace lodmesh i
		local tface = meshop.getMapFace lodmesh 1 i   
		local rnormals = meshop.getFaceRNormals lodmesh i

		for v = 1 to 3 do (						
			local pos = (in coordsys local getVert lodmesh (face[v] as integer)) + lodnode.objectOffsetPos
			local uv = getTVert lodmesh (tface[v] as integer)
			local normal
			if normmod != undefined then (
				local n = EN_getnormalid i v node:lodnode
				normal = EN_getnormal n node:lodnode
			)
			else normal = rnormals[v]				

			local strvert = stringstream ""
			format "%%%%%%%%" pos.x pos.y pos.z normal.x normal.y normal.z uv.x uv.y to:strvert
			strvert = strvert as string	

			local m_vert = MVert pos:pos normal:normal uv:uv key:strvert	

			append verts_big_unsorted m_vert
		)
	)

	verts_big_unsorted
)

fn RemoveDuplicates verts_big_unsorted = (
	local verts_big_sorted = copy verts_big_unsorted #noMap

	qsort verts_big_sorted CompareVerts

	local usedIds = #{}
	local big_ids = for i = 1 to verts_big_sorted.count collect i
	for m_vert in verts_big_sorted do (
		local index = bsearch m_vert.key big_ids CompareVertsB mverts:verts_big_sorted
		usedIds[index] = true
	)
	usedIds = usedIds as array

	local verts_unique = #()

	for id in usedIds do (
		local m_vert = verts_big_sorted[id]
		append verts_unique m_vert
	)

	verts_unique
)




fn CollectLods mobj = (
	local lodnodes = copy mobj.lods #noMap
	insertItem mobj.baseNode lodnodes 1

	local m_lods = #()
	local prevDist = 0.0

	for lodnode in lodnodes do (
		local lodmesh = copy lodnode.mesh
		local m_lod = MLod()
		local gp = custAttributes.get lodnode MafParams_def baseObject:false
		
		if gp != undefined then (
			m_lod.loddist = gp.lodDist
		)
		else (
			if lodnode == lodnodes[lodnodes.count] then m_lod.loddist = 0.0
			else m_lod.loddist = prevDist + 100.0
		)
		
		prevDist = m_lod.loddist	

		local normMod
		if MafiaTools.exportNormals.state == 2 then normMod = GetModByClass lodnode Edit_Normals

		-----

		

		----***FIRST PASS		

		local verts_big_unsorted = CollectVerts lodmesh lodnode
		
		---***REMOVE DUPLICATES		
		
		m_lod.verts = RemoveDuplicates verts_big_unsorted

		---***SECOND PASS

		local unique_ids = for i = 1 to m_lod.verts.count collect i
		local kkek = 1
		
		for i = 1 to lodmesh.numfaces do (
			
			local matid = getFaceMatID lodmesh i
			local m_matid = GetMafiaMatId (lodnode.mat) matid
			local m_facegroup = m_lod.GetFacegroupFromMatID m_matid
			local nface = #()
	
			for v = 1 to 3 do (
				local strvert = verts_big_unsorted[kkek].key
				local vert_id = bsearch strvert unique_ids CompareVertsB mverts:m_lod.verts
				nface[v] = vert_id
				kkek += 1
			)
	
			append m_facegroup.faces nface
		)		
		
		--format "mverts: %, faces: %, facegroups: %\n" m_lod.verts.count lodmesh.numfaces m_lod.facegroups.count

		append m_lods m_lod		
	)
	m_lods	
)



fn WriteStandardMesh f mobj = (
	
	if mobj.instanceID == 0 then ( --is master instance
		local m_lods
		local gp = custAttributes.get mobj.baseNode MafParams_def baseObject:false
		
		if (gp != undefined) and (gp.dontOptimize) then (
			m_lods = CollectLodsCompat mobj
			--m_lods = CollectLods mobj
		)
		else (
			m_lods = CollectLods mobj
		)

		WriteShort f 0 --not duplicate
		WriteByte f m_lods.count

		for m_lod in m_lods do (
			
			WriteFloat f m_lod.loddist
			local count = m_lod.verts.count
			
			if count > 65535 then (
				messageBox ("Too many vertices in " + mobj.baseNode.name + ".  " + (count as string) + " / 65535.") icon:#critical
			)

			WriteShort f m_lod.verts.count

			for m_vert in m_lod.verts do (
				WritePoint3 f m_vert.pos
				WritePoint3 f m_vert.normal
				WriteUV f m_vert.uv
			)

			WriteByte f m_lod.facegroups.count

			for m_facegroup in m_lod.facegroups do (
				WriteShort f m_facegroup.faces.count

				for face in m_facegroup.faces do (
					WriteFace f face
				)
				WriteShort f (m_facegroup.matid - 1)
			)
		)	
	)
	else (
	 	WriteShort f mobj.instanceID				
	)	
)

fn WriteBillboard f mobj = (
	WriteStandardMesh f mobj	

	local gp = custAttributes.get mobj.baseNode MafParams_def baseObject:false

	WriteByte f (gp.rotAxis - 1)
	WriteLong f (gp.rotMode - 1)
)


fn WriteObjects f = (
	local mobjSet = CollectObjects()
	local mobjects = mobjSet.mobjects

	WriteShort f mobjects.count

	for mobj in mobjects do (		
		local gp = custAttributes.get mobj.baseNode MafParams_def baseObject:false


		local renderFlags = 0
		local renderFlags2 = 42
		local cullFlags = 0
		local userParams		
		if gp != undefined then (
			renderFlags = gp.renderFlags
			renderFlags2 = gp.renderFlags2
			cullFlags = gp.cullFlags
			userParams = gp.userParams
		)
		else if mobj.objectType == 5 then cullFlags = 125
		else if mobj.objectType == 1 then cullFlags = 9


		WriteByte f mobj.objectType #unsigned

		if mobj.objectType == 1 then (
			WriteByte f mobj.visualType #unsigned			
			WriteByte f renderFlags #unsigned	
			WriteByte f renderFlags2 #unsigned	
		)
		WriteShort f mobj.parentID #unsigned

		if mobj.objectType == 5 then (
			WritePoint3 f [0,0,0]
			WritePoint3 f [1,1,1]
			WriteQuat f [0,0,0,1]
		)
		else (
			if (mobj.parentID != 0) and (mobjects[mobj.parentID].objectType == 5) then (
				in coordsys world
				(
					WritePoint3 f mobj.baseNode.pos
					WritePoint3 f mobj.baseNode.scale
					WriteQuat f mobj.baseNode.rotation
				)
			)
			else (
				in coordsys parent
				(
					WritePoint3 f mobj.baseNode.pos
					WritePoint3 f mobj.baseNode.scale
					WriteQuat f mobj.baseNode.rotation
				)
			)
			
		)	

		-- WritePoint3 f mobj.baseNode.objectTransform.translationPart
		-- WritePoint3 f mobj.baseNode.objectTransform.scalePart
	 	-- WriteQuat f mobj.baseNode.objectTransform.rotationPart


		WriteByte f cullFlags
		WriteText f mobj.baseNode.name
		WriteText f userParams
		------------------

		if mobj.objectType == 1 then (
			if mobj.visualType == 0 then (
				WriteStandardMesh f mobj
			)
			else if mobj.visualType == 4 then (
				WriteBillboard f mobj
			)
		)
		else if mobj.objectType == 5 then WriteSector f mobj
		else if mobj.objectType == 6 then WriteDummy f mobj
		
	)
)

------------------------
---------MAIN-----------
------------------------
fn Main = (

	--local scenename = getFilenameFile maxFileName
	local scenename = MafiaTools.editName.text
	local file = getSaveFileName types:"4DS file (*.4ds)|*.4ds|All files (*.*)|*.*" filename:scenename historyCategory:"4dsExport"
	if file != undefined do
	(
		if MafiaTools.editName.text == "" then (
			MafiaTools.editName.text = getFilenameFile file
		)

		format "exporting: %\n" file

		local start = timeStamp()	
		
		gc light:true

		local used_start = (heapsize - heapfree) / 1024.0

		f = fopen file "wb"    
		WriteHeader f
		WriteMaterials f
		WriteObjects f
		WriteByte f 0  --use 5ds animation
		fclose f
	
		local end = timeStamp()	
		if end < start then end += 86400000  --timing over midnight	
		local dur =  (end - start) / 1000.0

		local used_end = (heapsize - heapfree) / 1024.0
		format "memory used ~ % KiB\n" (used_end - used_start)

		gc light:true
	
		format "Exporting took % seconds\n" dur	
		messageBox ("Exporting took " + (dur as string) + " seconds")
	)
)
Main()

)