struct T4ds (
	header,   --THeader
	materials = #(),  --array of TMaterial
	objects = #(),   --array of TObject
	allow5ds = false
)

struct THeader (
	fourcc,
	version,
	timestamp
)

struct TMaterial (
	flags,   --u32
	ambient,  --color (float[3])
	diffuse,  --color (=||=)
	emission,  --color
	opacity,  --float
	envMapAmount,  --float
	envMapName,	--pstring
	diffMapName,	--pstring
	alphaMapName,	--pstring	
	animFrames,	--u32
	animPeriod	--u32
)

struct MObject (
	objectType,
	visualType,
	renderFlags = 0,
	renderFlags2 = 0,
	parentId,
	offset,
	scl,
	rot,
	cullFlags,
	name,
	strParams,
	definitions = #(),
	--transform,
	
	fn GetMatrix = (
		local tMatrix = matrix3 [1, 0, 0] [0, 1, 0] [0, 0, 1] [offset.x, offset.y, offset.z]
		local sclMatrix = matrix3 [scl.x, 0, 0] [0, scl.y, 0] [0, 0, scl.z] [0, 0, 0]
		local rotMatrix = ((inverse rot) as matrix3)
		(sclMatrix * rotMatrix * tMatrix)		
	)
)

struct TMesh (
	instanceId,
	lods = #()
)

struct TFacegroup (
	faceIds = #(),
	matId
)

struct TLod (
	distance,
	mesh,
	normals = #(),	--array of point3, count equals to count of vertices in mesh
	matIds = #(),   --array of int, count = count of faces in mesh
	facegroups = #(),
	vertOrder
)

struct TSkin (
	numW0Verts,
	dmin,
	dmax,
	vgroups = #()	--array of TSkinVertexGroup
)

struct TSkinVertexGroup (
	matrix = #(),  --4x4 matrix
	numW1Verts,
	boneId,
	dmin,
	dmax,
	weights = #()	--array of float
)

struct TMorph (
	sections = #(),
	numTargets
)

struct TMorphSection (
	vertices = #(),   --array of TMorphVertex
	vertexLinks = #()
)

struct TMorphVertex (
	targets = #()	--array of TMorphTarget
)

struct TMorphTarget (
	pos,   	--point3
	normal	--point3
)

struct TBillboard (
	rotAxis,
	rotMode
)

struct TGlow (
	position,  --screen offset
	materialId	
)

struct TMirror (
	dmin,
	dmax,
	unknown = #(),
	matrix = #(),
	backColor,
	drawDistance,
	mesh
)

struct TDummy (
	dmin,
	dmax
)

struct TSector (
	mesh,
	dmin,
	dmax,
	portals = #() --array of TPortal
)

struct TPortal (
	nearRange,
	farRange,
	verts = #() --array of point3
)

struct TTarget (
	unk1,
	unk2,
	linkIds = #()
)

struct TBone (
	matrix = #(), --4x4 matrix
	boneId
)

ReadHeader
ReadMaterial
ReadObject
ReadMesh
ReadSkin
ReadMorph
ReadBillboard
ReadGlow
ReadMirror
ReadDummy
ReadSector
ReadTarget
ReadBone

fn ReadText f = (
	local len = ReadByte f #unsigned

	local result
	if len > 0 then (
		local fmt = "%"
		local ss = StringStream ""
		for i = 1 to len do (
			format fmt (bit.intAsChar(ReadByte f #unsigned)) to:ss
		)
		result = ss as string
	)	
	result
)

fn ReadPoint3 f = (
	x = ReadFloat f
	y = ReadFloat f
	z = ReadFloat f
	[x, z, y]
)

fn ReadColor f = (
	r = (ReadFloat f) * 255
	g = (ReadFloat f) * 255
	b = (ReadFloat f) * 255
	clr = color r g b
	clr
)

fn ReadQuat f = (
	rw = ReadFloat f
	rx = ReadFloat f
	ry = ReadFloat f
	rz = ReadFloat f
	qt = quat rx rz ry rw
	qt
)

fn ReadFace f = (
	a = ReadShort f #unsigned
	b = ReadShort f #unsigned
	c = ReadShort f #unsigned
	[a+1, c+1, b+1]       --face vertex indexes are 1-based in 3ds Max
)

fn ReadUV f = (
	x = ReadFloat f
	y = ReadFloat f
	[x, 1-y, 0]
)

fn ReadMatrix f = (
	local mtr = #()
	for m = 1 to 4 do (	
		mtr[m] = #()				
		for n = 1 to 4 do mtr[m][n] = ReadFloat f
	)	
	
	local row1 = [mtr[1][1], mtr[1][3], mtr[1][2]]
	local row2 = [mtr[3][1], mtr[3][3], mtr[3][2]]
	local row3 = [mtr[2][1], mtr[2][3], mtr[2][2]]
	local row4 = [mtr[4][1], mtr[4][3], mtr[4][2]]
	
	matrix3 row1 row2 row3 row4
)

fn Read4ds f = (	
	local header = ReadHeader f
	
	if header != undefined and (header.version == 29 or header.version == 27) then (
		local m4ds = T4ds()
		m4ds.header = header		
		local numMats = ReadShort f #unsigned
		for i = 1 to numMats do (
			append m4ds.materials (ReadMaterial f)
		)
		
		local numObjects = ReadShort f #unsigned
		for i = 1 to numObjects do (
			append m4ds.objects (ReadObject f)
		)
	) 
	
	m4ds
)

fn ReadHeader f = (	
	local mheader
	local fourcc = ReadLong f #unsigned
	if fourcc == 5456948 then (  --is 4ds		
		mheader = THeader()
		mheader.fourcc = fourcc
		mheader.version = ReadShort f #unsigned	
		mheader.timestamp = ReadLongLong f	
	)
	
	mheader
)

fn ReadMaterial f = (
	local mmat = TMaterial()
	mmat.flags = ReadLong f #unsigned
	mmat.ambient = ReadColor f
	mmat.diffuse = ReadColor f
	mmat.emission = ReadColor f
	mmat.opacity = ReadFloat f
	if bit.get mmat.flags 20 then (  --env map enabled
		mmat.envMapAmount = ReadFloat f
		mmat.envMapName = ReadText f		
	)
	mmat.diffMapName = ReadText f
	if (mmat.diffMapName != undefined) and (bit.get mmat.flags 31) then (
		mmat.alphaMapName = ReadText f
	)
	
	if bit.get mmat.flags 27 then (
		mmat.animFrames = ReadLong f #unsigned
		ReadShort f #unsigned
		mmat.animPeriod = ReadLong f #unsigned
		ReadLong f #unsigned
		ReadLong f #unsigned
	)
	mmat
)

fn ReadObject f = (
	local mobj = MObject()
	
	mobj.objectType = ReadByte f #unsigned

	if mobj.objectType == 1 then (  --visual object
		mobj.visualType = ReadByte f #unsigned
		mobj.renderFlags = ReadByte f #unsigned
		mobj.renderFlags2 = ReadByte f #unsigned
	)		

	mobj.parentId = ReadShort f #unsigned
	mobj.offset = ReadPoint3 f
	mobj.scl = ReadPoint3 f	
	mobj.rot = ReadQuat f
	mobj.cullFlags = ReadByte f #unsigned
	mobj.name = ReadText f 
	mobj.strParams = ReadText f		
	
	case mobj.objectType of (
		1: case mobj.visualType of (
			0: mobj.definitions[1] = ReadMesh f  --standardmesh
			2: (  --singlemesh
				mobj.definitions[1] = ReadMesh f 
				mobj.definitions[2] = ReadSkin f mobj.definitions[1].lods.count
			)
			3: (  --singlemorph
				mobj.definitions[1] = ReadMesh f
				mobj.definitions[2] = ReadSkin f mobj.definitions[1].lods.count
				mobj.definitions[3] = ReadMorph f
			)
			4: ( 
				mobj.definitions[1] = ReadMesh f
				mobj.definitions[2] = ReadBillboard f 
			)
			5: ( --morph
				mobj.definitions[1] = ReadMesh f
				mobj.definitions[2] = ReadMorph f
			)
			6: mobj.definitions[1] = ReadGlow f
			8: mobj.definitions[1] = ReadMirror f
		)
		5: mobj.definitions[1] = ReadSector f
		6: mobj.definitions[1] = ReadDummy f
		7: mobj.definitions[1] = ReadTarget f
		10: mobj.definitions[1] = ReadBone f
	)
	
	mobj
)


fn ReadMesh f = (
	local mmesh = TMesh()	
	mmesh.instanceId = ReadShort f #unsigned	
	
	if mmesh.instanceId == 0 then (
		local numlods = ReadByte f #unsigned
				
		if numlods > 0 then (
			for lodId = 0 to numlods - 1 do (
				local mlod = TLod()				
				mlod.distance = ReadFloat f								
				local numVerts = ReadShort f #unsigned
				local tr = TriMesh()
				setNumVerts tr numverts
				setNumTVerts tr numverts

				for i = 1 to numVerts do (
					local vert = ReadPoint3 f
					local normal = ReadPoint3 f					
					local uv = ReadUV f
					
					append mlod.normals normal
					setVert tr i vert
					setTVert tr i uv
				)

				local numFacegroups = ReadByte f #unsigned

				for i = 1 to numFacegroups do (
					local numFaces = ReadShort f #unsigned				
					local offset = getNumFaces tr
					local num = offset + numFaces
					setNumFaces tr num true			-- keep topology	

					for j = 1 to numFaces do (
						local face = ReadFace f
						setFace tr (offset+j) face
					)					
					local matId = ReadShort f #unsigned
					
					for j = 1 to numFaces do (
						append mlod.matIds matId
					)
					
				)
				
				buildTVFaces tr
				for i = 1 to tr.numfaces do (
					setTVFace tr i (getFace tr i)
					for v = 1 to 3 do setEdgeVis tr i v true
				)	
				
				mlod.mesh = tr				
				append mmesh.lods mlod
			)			
		)
	)

	mmesh
)

fn ReadSkin f numlods = (	
	
	local mskins = #()

	for l = 1 to numLods do (
		local mskin = TSkin()
		
		local numGroups = ReadByte f #unsigned
		mskin.numW0Verts = ReadLong f #unsigned
	
		mskin.dmin = ReadPoint3 f
		mskin.dmax = ReadPoint3 f
	
		for i = 0 to numGroups-1 do (
			local vgroup = TSkinVertexGroup()			
			vgroup.matrix = ReadMatrix f			
			
			vgroup.numW1Verts = ReadLong f #unsigned
			local numWeights = ReadLong f #unsigned
			vgroup.boneId = ReadLong f #unsigned
				
			vgroup.dmin = ReadPoint3 f
			vgroup.dmax = ReadPoint3 f
	
			for w = 1 to numWeights do (
				append vgroup.weights (ReadFloat f)
			)
			append mskin.vgroups vgroup
		)
		append mskins mskin
	)	
	
	mskins
)

fn ReadMorph f = (
	local mmorph = TMorph()
	local numTargets = ReadByte f #unsigned
	mmorph.numTargets = numTargets

	if numTargets > 0 then (
		local numLayers = ReadByte f #unsigned
		ReadByte f #unsigned   --unknown	
		for i = 1 to numLayers do	(
			local ms = TMorphSection()
			local numVerts = ReadShort f #unsigned
	
			for v = 1 to numVerts do (
				local mv = TMorphVertex()
				
				for t = 1 to numTargets do (
					local mt = TMorphTarget()
					mt.pos = ReadPoint3 f
					mt.normal = ReadPoint3 f
					append mv.targets mt
				)
				append ms.vertices mv								
			)
	
			if (numTargets * numVerts) > 0 then	ReadByte f #unsigned  --unknown
	
			for v = 1 to numVerts do	(
				local vertexLink = ReadShort f #unsigned 
				append ms.vertexLinks vertexLink
			)
			
			append mmorph.sections ms
		)
	
		local dmin = ReadPoint3 f
		local dmax = ReadPoint3 f
	
		for i = 1 to 4 do ReadFloat f   --unknown
	)	
	mmorph
)

fn ReadBillboard f = (
	local mbillboard = TBillboard()
	mbillboard.rotAxis = ReadLong f #unsigned
	mbillboard.rotMode = ReadByte f #unsigned
	
	mbillboard
)

fn ReadGlow f = (	
	local glows = #()
	local numGlows = ReadByte f #unsigned
	
	for i = 1 to numGlows do (
		local glow = TGlow()
		glow.position = ReadFloat f
		glow.materialId = ReadShort f #unsigned
		
		append glows glow
	)
	
	glows
)

fn ReadMirror f = (
	local mMirror = TMirror()	

	mMirror.dmin = ReadPoint3 f
	mMirror.dmax = ReadPoint3 f

	for i = 1 to 4 do local unknown = ReadFloat f
	for i = 1 to 16 do local reflectionMatrix = ReadFloat f
	
	mMirror.backColor = ReadColor f
	mMirror.drawDistance = ReadFloat f

	local numVerts = ReadLong f #unsigned
	local numFaces = ReadLong f #unsigned

	local tr = TriMesh()
	setNumVerts tr numVerts
	setNumFaces tr numFaces

	for i = 1 to numVerts do (
		local vert = ReadPoint3 f
		setVert tr i vert
	)

	for i = 1 to numFaces do (
		local face = ReadFace f
		setFace tr i face
	)
	
	mMirror.mesh = tr
	
	mMirror
)

fn ReadDummy f = (
	local mDummy = TDummy()	
	mDummy.dmin = ReadPoint3 f
	mDummy.dmax = ReadPoint3 f		
	mDummy
)


fn ReadSector f = (
	local msector = TSector()	

	ReadLong f #unsigned --always 2049
	ReadLong f #unsigned --always 0

	local numVerts = ReadLong f #unsigned
	local numFaces = ReadLong f #unsigned

	local tr = TriMesh()
	setNumVerts tr numVerts
	setNumFaces tr numFaces

	for i = 1 to numVerts do (
		local vert = ReadPoint3 f
		setVert tr i vert
	)

	for i = 1 to numFaces do (
		local face = ReadFace f
		setFace tr i face
		setFaceSmoothGroup tr i 0
	)
	
	msector.mesh = tr	
	msector.dmin = ReadPoint3 f
	msector.dmax = ReadPoint3 f

	local numPortals = ReadByte f #unsigned

	for i = 1 to numPortals do (		
		local mportal = TPortal()
		local numVerts = ReadByte f #unsigned
		for j = 1 to 5 do ReadLong f #unsigned
		mportal.nearRange = ReadFloat f
		mportal.farRange = ReadFloat f
				
		for v = 1 to numVerts do (
			local vert = ReadPoint3 f
			append mportal.verts vert
		)		
		append msector.portals mportal	
	)

	
	msector
)

-- returns TTarget
fn ReadTarget f = (
	local mTarget = TTarget()	

	mTarget.unk1 = ReadByte f #unsigned
	mTarget.unk2 = ReadByte f #unsigned
	local numLinks = ReadByte f #unsigned
	
	for i = 1 to numLinks do (
		append mTarget.linkIds (ReadShort f #unsigned)
	)
	
	mTarget
)


fn ReadBone f = (
	local mbone = TBone()	
	mbone.matrix = ReadMatrix f		
	mbone.boneId = ReadLong f #unsigned
	mbone
)

--------------------------------------------------------------
Write4ds
WriteHeader
WriteMaterial
WriteObject
WriteMesh
WriteSkin
WriteBillboard
WriteSector
WriteDummy
WriteTarget
WriteBone


fn WriteText f txt = (
	local count = 0
	if txt != undefined then count = txt.count	
	
	if count > 255 then (
		count = 255
		messageBox ("String '" + txt + "' is over the maximum of 255 characters!") icon:#warning
	)
	WriteByte f count #unsigned
	for i = 1 to count do (
		WriteByte f (bit.charasint txt[i])
	)
		
	count	
)

fn WriteColor f clr = (
	WriteFloat f (clr.r / 255.0)
	WriteFloat f (clr.g / 255.0)
	WriteFloat f (clr.b / 255.0)
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
	WriteShort f a #unsigned
	WriteShort f b #unsigned
	WriteShort f c #unsigned
)

fn WriteUV f uv = (
	WriteFloat f uv.x
	WriteFloat f (1 - uv.y)
)

fn WriteMatrix f mat3 = (
	local rows = #()
	append rows #(mat3.row1.x, mat3.row1.z, mat3.row1.y, 0)  
	append rows #(mat3.row3.x, mat3.row3.z, mat3.row3.y, 0) -- thanks Duelist
	append rows #(mat3.row2.x, mat3.row2.z, mat3.row2.y, 0)
	append rows #(mat3.row4.x, mat3.row4.z, mat3.row4.y, 1)	
	
	for row in rows do (
		for n = 1 to 4 do WriteFloat f row[n]
	)	
)

fn Write4ds f m4ds = (
	WriteHeader f
	
	WriteShort f m4ds.materials.count
	for mmat in m4ds.materials do (
		WriteMaterial f mmat		
	)
	
	WriteShort f m4ds.objects.count
	for mobj in m4ds.objects do (
		WriteObject f mobj
	)
	
	WriteByte f false
)

fn WriteHeader f = (
    WriteLong f 5456948 	-- 4DS
	WriteShort f 29			--format version
	WriteLong f 343586816	--timestamp
	WriteLong f 29382754	--timestamp part 2
)

fn WriteMaterial f mmat = (
	WriteLong f mmat.flags
	WriteColor f mmat.ambient
	WriteColor f mmat.diffuse
	WriteColor f mmat.emission
	WriteFloat f mmat.opacity
	
	if bit.get mmat.flags 20 then ( 	-- env map
		WriteFloat f mmat.envMapAmount
		WriteText f mmat.envMapName
	)
	local count = WriteText f mmat.diffMapName
	
	if count > 0 and bit.get mmat.flags 31 then (   -- alpha map
		WriteText f mmat.alphaMapName
	)
	
	if bit.get mmat.flags 27 then (		-- animated
		WriteLong f mmat.animFrames
		WriteShort f 0
		WriteLong f mmat.animPeriod
		WriteLong f 0
		WriteLong f 0
	)
	
)

fn WriteObject f mobj = (
	WriteByte f mobj.objectType
	
	if mobj.objectType == 1 then (
		WriteByte f mobj.visualType
		WriteByte f mobj.renderFlags
		WriteByte f mobj.renderFlags2
	)
	
	WriteShort f mobj.parentId	
	WritePoint3 f mobj.offset
	WritePoint3 f mobj.scl
	WriteQuat f mobj.rot
	WriteByte f mobj.cullFlags
	WriteText f mobj.name
	WriteText f mobj.strParams
	
	case mobj.objectType of (
		1: case mobj.visualType of (
			0: WriteMesh f mobj.definitions[1]
			2: (
				WriteMesh f mobj.definitions[1]
				WriteSkin f mobj.definitions[2]
			) 
			4: (
				WriteMesh f mobj.definitions[1]
				WriteBillboard f mobj.definitions[2]
			) 
		)
		5: WriteSector f mobj.definitions[1]
		6: WriteDummy f mobj.definitions[1]
		7: WriteTarget f mobj.definitions[1]
		10: WriteBone f mobj.definitions[1]
	)	
)

fn WriteMesh f mmesh = (
	WriteShort f mmesh.instanceId
	
	if mmesh.instanceId == 0 then (
		WriteByte f mmesh.lods.count
		for lod in mmesh.lods do (
			WriteFloat f lod.distance
			WriteShort f lod.mesh.numverts
			
			if lod.vertOrder == undefined then (
				for i = 1 to lod.mesh.numverts do (					
					WritePoint3 f (getVert lod.mesh i)
					local normal = lod.normals[i]
					if normal == undefined then normal = [0,0,0]
					WritePoint3 f normal
					WriteUV f (getTVert lod.mesh i)
				)
				
				WriteByte f lod.facegroups.count
				for facegroup in lod.facegroups do (
					WriteShort f facegroup.faceIds.count
					for faceId in facegroup.faceIds do (						
						WriteFace f (getFace lod.mesh faceId)					
					)
					WriteShort f (facegroup.matId - 1)
				)
			)
			else (			
				--PrintArray lod.vertOrder
					
				--PrintArray lod.normals
				for i = 1 to lod.mesh.numverts do (
					local corrVertId = lod.vertOrder[i]
					
					WritePoint3 f (getVert lod.mesh corrVertId)	
					local normal = lod.normals[corrVertId]
					if normal == undefined then normal = [0,0,0]
					WritePoint3 f normal
					WriteUV f (getTVert lod.mesh corrVertId)
				)
				
				local rev = #()
				for i = 1 to lod.vertOrder.count do (
					local vertId = lod.vertOrder[i]
					rev[vertId] = i
				)
				
				WriteByte f lod.facegroups.count
				for facegroup in lod.facegroups do (
					WriteShort f facegroup.faceIds.count
					for faceId in facegroup.faceIds do (
						local vertIds = getFace lod.mesh faceId
						
						for v = 1 to 3 do (
							local vertId = vertIds[v]
							vertIds[v] = rev[vertId]
						)
						WriteFace f vertIds					
					)
					WriteShort f (facegroup.matId - 1)
				)
			)			
			
		)
	)
)


fn WriteSkin f mskins = (
	for mskin in mskins do (
		WriteByte f mskin.vgroups.count
		WriteLong f mskin.numW0Verts
		WritePoint3 f mskin.dmin
		WritePoint3 f mskin.dmax
		
		for grp in mskin.vgroups do (
			WriteMatrix f grp.matrix
			
			WriteLong f grp.numW1Verts
			WriteLong f grp.weights.count
			WriteLong f grp.boneId
			WritePoint3 f grp.dmin
			WritePoint3 f grp.dmax
			
			for weight in grp.weights do WriteFloat f weight
		)
	)
)

fn WriteBillboard f mbillboard = (
	WriteByte f mbillboard.rotAxis
	WriteLong f mbillboard.rotMode
)

fn WriteSector f sector = (
	WriteLong f 2049    --unknown
	WriteLong f 0		--unknown
	
	local smesh = sector.mesh
	
	WriteLong f smesh.numVerts
	WriteLong f smesh.numFaces
	
	for i = 1 to smesh.numVerts do (
		local vert = getVert smesh i
		WritePoint3 f vert
	)
	
	for i = 1 to smesh.numFaces do (
		local face = getFace smesh i
		WriteFace f face
	)
	
	WritePoint3 f sector.dmin
	WritePoint3 f sector.dmax	
	WriteByte f sector.portals.count
	
	for portal in sector.portals do (
		WriteByte f portal.verts.count
		WriteLong f 4 	--unknown
		for i = 1 to 4 do WriteLong f 0	--unknown
		
		WriteFloat f portal.nearRange
		WriteFloat f portal.farRange
		
		for vert in portal.verts do (
			WritePoint3 f vert
		)
	)
)

fn WriteDummy f mdummy = (
	WritePoint3 f mdummy.dmin
	WritePoint3 f mdummy.dmax
)

fn WriteTarget f mtarget = (
	WriteShort f 0
	WriteByte f mtarget.linkIds.count
	
	for linkId in mtarget.linkIds do (
		WriteShort f linkId
	)
)

fn WriteBone f mbone = (	
	WriteMatrix f mbone.matrix
	
	WriteLong f mbone.boneId
)

fn mtypeof mobj = (
	case mobj.objectType of (
		1: case mobj.visualType of (
			0: #mesh
			2: #singlemesh
			3: #singlemorph
			4: #billboard
			5: #morphedMesh
			6: #glow
			8: #mirror
		)
		5: #sector
		6: #dummy
		7: #target
		10: #bone
	)
)