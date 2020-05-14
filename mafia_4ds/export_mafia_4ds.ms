(

fn WriteText f txt = (
	if txt == undefined then (
		--MessageBox "writetext undefined"
		--print "writetext undefined"
		WriteByte f 0 #unsigned
	)
	else (
		WriteByte f txt.count #unsigned
		for i = 1 to txt.count do
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

local godmat 
fn WriteMaterials f =
(
    local found = false
    local i = 1
	
	for mat in scenematerials while not found do (
		if stricmp mat.name "$MAFIA_MATERIALS" == 0 then (
			found = true	
			godmat = mat					
		)
	)

	if not found then (
		local numMats = 0
		WriteShort f numMats
	)
	else (
		local numMats = godmat.numSubs - 1
		WriteShort f numMats
		
		for m = 2 to godmat.numSubs do (
			local mat = godmat[m]

			local flags = 0
			flags += (bit.set 0 1 true)
			if classof mat == Standard then flags += (bit.set 0 24 true)
			else if classof mat == MafMat4 then
			(	
				flags += (bit.set 0 19 mat.delegate.diffuseMapEnable)
				flags += (bit.set 0 28 mat.useColoring)
				flags += (bit.set 0 24 mat.useMips)
				flags += (bit.set 0 29 mat.delegate.twoSided)
				flags += (bit.set 0 27 mat.isAnimatedM)
				flags += (bit.set 0 20 mat.delegate.reflectionMapEnable)
				flags += (bit.set 0 9 mat.envOverlay)
				flags += (bit.set 0 10 mat.envMultiply)
				flags += (bit.set 0 11 mat.envAdditive)
				flags += (bit.set 0 13 mat.YProj)
				flags += (bit.set 0 14 mat.YDetail)
				flags += (bit.set 0 15 mat.ZDetail)
				flags += (bit.set 0 16 mat.addEffect)
				flags += (bit.set 0 31 mat.delegate.opacityMapEnable)
				flags += (bit.set 0 30 mat.useColorKey)
				flags += (bit.set 0 32 mat.useAddBlend)
			)
		
			WriteLong f flags
			
			--ambient
			WriteColor f mat.delegate.ambient
			
			--diffuse
			WriteColor f mat.delegate.diffuse
			
			--emission
			if mat.delegate.useSelfIllumColor then (
				WriteColor f mat.delegate.selfIllumColor
			)
			else (
				WriteFloat f 0; WriteFloat f 0; WriteFloat f 0
			)
			
			--opacity
			WriteFloat f (mat.delegate.opacity / 100.0)
		
			--env map
			if mat.delegate.reflectionMapEnable then (
				WriteFloat f (mat.delegate.reflectionMapAmount / 100.0)
				local filename = filenameFromPath mat.delegate.reflectionMap.filename
				WriteText f filename
			)
		
			--diffuse map
			if mat.delegate.diffuseMapEnable then (
				local filename = filenameFromPath mat.delegate.diffusemap.filename
				WriteText f filename
			)
			else (
				WriteByte f 0
			)
		
			--opacity map
			if mat.delegate.opacityMapEnable then (
				local filename = filenameFromPath mat.delegate.opacitymap.filename
				WriteText f filename
			)
		
			if mat.isAnimatedM then (
				WriteByte f animFrames
				WriteByte f 0
				WriteLong f 0
				WriteLong f animDelay
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

struct MObject (
	objectType,
	visualType,
	nnode,	
	lods = #(),
	portals = #(),
	isSet = false,
	parentID = 0,
	
	fn StandardMesh = (
		if not isSet then (
			objectType = 1
			visualType = 0
			isSet = true
		)		
	),
	fn Sector = (
		if not isSet then (
			objectType = 5
			isSet = true
		)
	),	
	fn Dummy = (
		if not isSet then (
			objectType = 6
			isSet = true
		)
	)
)

local mobjects
local mobject_ids

fn GetIdFromHandle handle = (
	mobject_ids[handle]
)

fn GetMObjectFromObj obj = (
	local handle = obj.inode.handle
	local mid = GetIdFromHandle handle
	mobjects[mid]
)

fn AddMObject mobj = (
	local handle = mobj.nnode.inode.handle				
	append mobjects mobj
	mobject_ids[handle] = mobjects.count
)

fn CollectObjects = (

	mobjects = #()
	mobject_ids = Dictionary #integer	

	for obj in objects do (		
		mobj = MObject()
		mobj.nnode = obj

		if IsGeometry obj then (  --can be sector, portal, regular mesh, lod...

			if matchPattern obj.name pattern:"$portal*" then (
				if obj.parent != undefined then (

					parent_mobj = GetMObjectFromObj obj.parent
					append parent_mobj.portals obj
				)
			)
			else if matchPattern obj.name pattern:"$lod*" then (
				if obj.parent != undefined then (

					parent_mobj = GetMObjectFromObj obj.parent
					append parent_mobj.lods obj
				) 
			)
			else (							
				if matchPattern obj.name pattern:"sector*" then (
					mobj.Sector()
				)
				else (
					mobj.StandardMesh()
				)
			)

		) 
		else if isKindOf obj Dummy then (
			mobj.Dummy()
		)


		if mobj.isSet then (	
			if obj.parent != undefined then (
				mobj.parentID = GetIDFromHandle obj.parent.inode.handle
			)		
			AddMObject mobj
		)
	)
	mobjects
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

fn WriteSector f mobj = (
	WriteLong f 2049    --unknown
	WriteLong f 0		--unknown

	WriteLong f (mobj.nnode.numVerts)
	WriteLong f (mobj.nnode.numFaces)

	for i = 1 to mobj.nnode.numVerts do (
		pos = getVert mobj.nnode i
		WritePoint3 f pos
	)

	for i = 1 to mobj.nnode.numFaces do (
		indexes = getFace mobj.nnode i
		WriteFace f indexes
	)

	WritePoint3 f mobj.nnode.min
	WritePoint3 f mobj.nnode.max

	WriteByte f mobj.portals.count

	for portal in mobj.portals do (
		WriteByte f (portal.numVerts)
		WriteLong f 4 	--unknown
		for i = 1 to 4 do WriteLong f 0   --unknown
		local modp = portal.modifiers[MafPortal4]
		if (modp == undefined) then (
			WriteFloat f 0.0
			WriteFloat f 10.0
		)
		else (
			WriteFloat f modp.nearRange
			WriteFloat f modp.farRange
		)	

		for i = 1 to portal.numVerts do (
			pos = polyop.getvert portal i
			WritePoint3 f pos
		)
	)
)

fn WriteDummy f mobj = (
	in coordsys local (
		WritePoint3 f mobj.nnode.min
		WritePoint3 f mobj.nnode.max
	)
)

struct MVert (
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
	vert_ids = Dictionary #string,
	facegroups = #(),   --array of MFacegroup
	facegroup_ids = Dictionary #integer,
	loddist,

	fn GetFacegroupFromMatID matid = (
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

fn CollectLodsCompat mobj = (
	local nnode = mobj.nnode	

	local lodnodes = copy mobj.lods #noMap
	insertItem mobj.nnode lodnodes 1

	local m_lods = #()

	local prevDist = 0.0

	for lodnode in lodnodes do (
		local lodmesh
		if isKindOf lodnode Editable_mesh then lodmesh = lodnode
		else lodmesh = copy lodnode.mesh

		local m_lod = MLod()

		local modl = lodnode.modifiers[MafLod4]
		if modl != undefined then (
			m_lod.loddist = modl.lodDist
		)
		else (
			if lodnode == lodnodes[lodnodes.count] then m_lod.loddist = 0.0
			else m_lod.loddist = prevDist + 100.0
		)
		prevDist = m_lod.loddist

		local normMod
		if MafiaTools.exportNormals.checked then normMod = lodnode.modifiers[Edit_Normals]
		local normals = #()

		if normMod != undefined then
		(
			max modify mode
			modpanel.setcurrentobject normMod node:lodnode

			local EN_getnormalid = normMod.getnormalid
			local EN_getvertexid = normMod.getvertexid
			local EN_getnormal = normMod.getnormal

			for j = 1 to normMod.getnumfaces() do
			(
				for k in 1 to 3 do
				(
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

		local useMatId = false
		if (godmat != undefined) and (lodnode.mat == godmat) then (
			useMatId = true
		)

		for i = 1 to lodmesh.numfaces do (
			local face = getFace lodmesh i
			local matid = 1 
			if useMatId then matid = getFaceMatID lodmesh i
			local m_facegroup = m_lod.GetFacegroupFromMatID matid

			append m_facegroup.faces face
		)

		append m_lods m_lod
	)

	m_lods
)

fn CollectLods mobj = (
	--local nnode = $
	local nnode = mobj.nnode
	--if classof nnode != Editable_mesh then nnode = snapshotAsMesh $	

	local lodnodes = copy mobj.lods #noMap
	insertItem mobj.nnode lodnodes 1

	local m_lods = #()

	local prevDist = 0.0

	for lodnode in lodnodes do (
		local lodmesh
		if isKindOf lodnode Editable_mesh then lodmesh = lodnode
		else lodmesh = copy lodnode.mesh

		local m_lod = MLod()

		local modl = lodnode.modifiers[MafLod4]
		if modl != undefined then (
			m_lod.loddist = modl.lodDist
		)
		else (
			if lodnode == lodnodes[lodnodes.count] then m_lod.loddist = 0.0
			else m_lod.loddist = prevDist + 100.0
		)
		prevDist = m_lod.loddist

		local normMod
		if MafiaTools.exportNormals.checked then normMod = lodnode.modifiers[Edit_Normals]
		local EN_getnormalid 
		local EN_getnormal
		if normmod != undefined then (
			max modify mode
			modpanel.setcurrentobject normmod node:lodnode
			
			EN_getnormalid = normmod.getnormalid
			EN_getnormal =  normmod.getnormal
		)	

		local useMatId = false
		if (godmat != undefined) and (lodnode.mat == godmat) then (
			useMatId = true
		)
	
		for i = 1 to lodmesh.numfaces do (
			local face = getFace lodmesh i
			local tface = meshop.getMapFace lodmesh 1 i   
	
			local matid = 1 
			if useMatId then matid = getFaceMatID lodmesh i
			local m_facegroup = m_lod.GetFacegroupFromMatID matid
			local rnormals = meshop.getFaceRNormals lodmesh i
			local nface = #()
	
			for v = 1 to 3 do (
				local vert = (in coordsys local getVert lodmesh (face[v] as integer)) + lodnode.objectOffsetPos
				local tvert = meshop.getMapVert lodmesh 1 (tface[v] as integer)
				local normal
				if normmod != undefined then (
					local n = EN_getnormalid i v node:lodnode
					normal = EN_getnormal n node:lodnode
				)
				else (
					normal = rnormals[v]
				)	
	
				strvert = stringstream ""
				format "%%%%%%%%" vert.x vert.y vert.z normal.x normal.y normal.z tvert.x tvert.y to:strvert
				strvert = strvert as string	
				
				local id = m_lod.vert_ids[strvert]
				if id == undefined then (
					local m_vert = MVert pos:vert normal:normal uv:tvert
					append m_lod.verts m_vert
					id = m_lod.verts.count
					m_lod.vert_ids[strvert] = id
				)
				nface[v] = id			
			)
	
			append m_facegroup.faces nface
		)
		append m_lods m_lod
		
		--format "mverts: %, faces: %, facegroups: %\n" m_lod.verts.count lodmesh.numfaces m_lod.facegroups.count
	)
	m_lods	
)


fn WriteStandardMesh f mobj = (

	local m_lods
	local modl = mobj.nnode.modifiers[MafLod4]
	if (modl != undefined) and (modl.dontOptimize) then (
		m_lods = CollectLodsCompat mobj
	)
	else (
		m_lods = CollectLods mobj
	)

	WriteShort f 0 --not duplicate
	WriteByte f m_lods.count
	for m_lod in m_lods do (
		
		WriteFloat f m_lod.loddist

		WriteShort f m_lod.verts.count

		for m_vert in m_lod.verts do (
			WritePoint3 f m_vert.pos
			WritePoint3 f m_vert.normal

			WriteFloat f m_vert.uv.x
			WriteFloat f (1 - m_vert.uv.y)
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


fn WriteObjects f = (
	local mobjects = CollectObjects()

	WriteShort f mobjects.count

	for mobj in mobjects do (		
		local modo = mobj.nnode.modifiers[MafObject4]

		local renderFlags = 0
		local cullFlags = 0
		local userParams
		if modo != undefined then (
			renderFlags = modo.renderFlags
			cullFlags = modo.cullFlags
			userParams = modo.userParams
		)
		else if mobj.objectType == 5 then cullFlags = 125
		else if mobj.objectType == 1 then cullFlags = 9


		WriteByte f mobj.objectType #unsigned

		if mobj.objectType == 1 then (
			WriteByte f mobj.visualType #unsigned			
			WriteShort f renderFlags
		)
		WriteShort f mobj.parentID #unsigned

		in coordsys parent
		(
			WritePoint3 f mobj.nnode.pos
			WritePoint3 f mobj.nnode.scale
			WriteQuat f mobj.nnode.rotation
		)

		-- WritePoint3 f mobj.nnode.objectTransform.translationPart
		-- WritePoint3 f mobj.nnode.objectTransform.scalePart
	 	-- WriteQuat f mobj.nnode.objectTransform.rotationPart


		WriteByte f cullFlags
		WriteText f mobj.nnode.name
		WriteText f userParams
		------------------

		if mobj.objectType == 5 then WriteSector f mobj
		else if mobj.objectType == 6 then WriteDummy f mobj
		else if mobj.objectType == 1 and mobj.visualType == 0 then 			
			WriteStandardMesh f mobj	
		



	)
)

-- for mobj in mobjects do (
-- 	format "\n% ot:% vt:%" mobj.nnode.name mobj.objectType mobj.visualType
-- 	for lodd in mobj.lods do (
-- 		format "\n  %" lodd.name 
-- 	)
-- 	for prtl in mobj.portals do (
-- 		format "\n  %" prtl.name 
-- 	)
-- )

------------------------
---------MAIN-----------
------------------------

scenename = getFilenameFile maxFileName
file = getSaveFileName types:"4DS file (*.4ds)|*.4ds|All files (*.*)|*.*" filename:scenename
if file != undefined do
(
	start = timeStamp()	
	f = fopen file "wb"    
	WriteHeader f
	WriteMaterials f
	WriteObjects f
	WriteByte f 0  --use 5ds animation
	fclose f

	end = timeStamp()	
	if end < start then end += 86400000  --timing over midnight

	dur =  (end - start) / 1000.0

	format "Exporting took % seconds\n" dur

	messageBox ("Exporting took " + (dur as string) + " seconds")
)


)