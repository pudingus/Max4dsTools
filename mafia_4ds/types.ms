struct MObject
(
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

struct TLod (
	distance,
	mesh,
	normals = #()	
)


struct TSkin (	
	lods = #() --array of TSkinLod
)

struct TSkinLod (
	numW0Verts,
	dmin,
	dmax,
	groups = #()	--array of TSkinVertexGroup
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
	glows = #() --array of TGlowData
)

struct TGlowData (
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