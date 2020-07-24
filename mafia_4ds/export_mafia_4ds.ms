(
	
include "util.ms"
include "types.ms"

local debug = false

struct TNode (
	--type,  --#mesh, #sector, #helper
	baseNode,
	lods = #(),
	portals = #(),
	morphs = #()
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
	
	fn GetIdByNode obj = (           --Get MObject ID from node
		if obj != undefined then (
			local handle = obj.inode.handle		
			mobject_ids[handle]
		)
		else (
			0
		)		
	),

	fn Add mobj = (          --Add MObject to collection
		local handle = mobj.baseNode.inode.handle				
		append mobjects mobj
		mobject_ids[handle] = mobjects.count
	)	
)

struct TFacegroupSet (
	facegroups = #(),   --array of MFacegroup
	facegroup_ids = #(),   --get facegroup id from matid

	fn GetByMatId matid = (
		matid = matid + 1
		local grp_id = facegroup_ids[matid]	

		if grp_id == undefined then (
			local grp = TFacegroup matid:matid
			append facegroups grp
			grp_id = facegroups.count
			facegroup_ids[matid] = grp_id
		)
		facegroups[grp_id]
	)
)


fn CompareNames obj1 obj2 = stricmp obj1.name obj2.name


fn GetNodeType obj = (
	local gp = custAttributes.get obj MafParams_def baseObject:false
	if IsGeometry obj then (
		if matchPattern obj.name pattern:"$portal*" then (
			#portal
		)		
		else if matchPattern obj.name pattern:"$lod*" then (
			#lod
		)
		else if matchPattern obj.name pattern:"sector*" then (					
			#sector
		)		
		else if matchPattern obj.name pattern:"$morph*" then (					
			#morph
		)		
		else if (gp != undefined) and (stricmp gp.objectType "billboard" == 0) then (					
			#billboard
		)
		else if isKindOf obj BoneGeometry then (
			#bone
		)
		else if GetModByClass obj Skin != undefined then (
			#singlemesh
		)
		else (
			#mesh
		)				
	)	
	else if isKindOf obj Dummy then (
		#dummy
	)
	else if isKindOf obj TargetObject then (
		#target
	)		
	else #unsupported
)


local mafia_materials = #()
local mat_map = #()

fn ConvertStandardMaterial mat = (
	local cm = MafMat4()
			
	cm.diffuseMapEnable = mat.diffuseMapEnable
	cm.envMapEnable = mat.reflectionMapEnable
	cm.alphaMapEnable = mat.opacityMapEnable
	cm.twoSided = mat.twoSided
	
	cm.ambient = mat.ambient
	cm.diffuse = mat.diffuse
	cm.emission = mat.selfIllumColor
	
	cm.opacity = mat.opacity
	cm.envMapAmount = mat.reflectionMapAmount
	cm.envMap = mat.reflectionMap
	cm.diffuseMap = mat.diffuseMap
	cm.alphaMap = mat.opacityMap
	
	if cm.alphaMapEnable then (
		cm.addEffect = true
	)
	
	cm
)

fn ConvertPhysicalMaterial mat = (
	local cm = MafMat4()
		
	cm.diffuse = mat.base_color
	cm.emission = mat.emit_color
	
	cm.diffuseMapEnable = mat.base_color_map_on
	cm.diffuseMap = mat.base_color_map
	
	cm.alphaMapEnable = mat.cutout_map_on 
	cm.alphaMap = mat.cutout_map
	if cm.alphaMapEnable then (
		cm.addEffect = true
	)
	
	cm.opacity = (1.0 - mat.transparency) * 100
	
	local glossiness = 0.0
	if mat.roughness_inv then (
		glossiness = mat.roughness		
	)
	else (
		glossiness = 1.0 - mat.roughness	
	)
	
	if glossiness >= 0.05 then (
		cm.envMapAmount = glossiness * 100
		cm.envMap = bitmaptexture filename:"env2.bmp"
	)
	
	cm
)

fn AddToMafiaMaterials mat = (
	local handle = GetHandleByAnim mat
	
	if mat_map[handle] == undefined then (
		append mafia_materials mat
		mat_map[handle] = mafia_materials.count
	)
)

fn WriteMaterials f = (
	for mat in sceneMaterials do (
		if isKindOf mat MultiMaterial then (
			for submat in mat.materialList where submat != undefined do (
				
				if containsItem #(Standard, Physical_Material, MafMat4) (classOf subMat) then (
					AddToMafiaMaterials submat
				) 
			)
		)
		else (
			if containsItem #(Standard, Physical_Material, MafMat4) (classOf mat) then (
				AddToMafiaMaterials mat
			) 
		)
	)

	for mat in mafia_materials do print mat
	for matm in mat_map where matm != undefined do print matm	
	--print mat_map
	
	local numMats = mafia_materials.count
	WriteShort f numMats
	
	for mat in mafia_materials do (

		local flags = 0
		flags += (bit.set 0 1 true)

		if classof mat == Standard then (			
			mat = ConvertStandardMaterial mat
		)
		else if classof mat == Physical_Material then (			
			mat = ConvertPhysicalMaterial mat
		)
		
		if classof mat == MafMat4 then	(
			if mat.envMapEnable and (mat.envMap != undefined) then (
				flags += (bit.set 0 9 mat.envOverlay)
				flags += (bit.set 0 10 mat.envMultiply)
				flags += (bit.set 0 11 mat.envAdditive)
				flags += (bit.set 0 13 mat.YProj)
				flags += (bit.set 0 14 mat.YDetail)
				flags += (bit.set 0 15 mat.ZDetail)
			)
			
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

				if (mat.envMap != undefined) and (classof mat.envMap == Bitmaptexture) then (
					local filename = filenameFromPath mat.envMap.filename
					WriteText f filename
				)
				else WriteByte f 0
			)
		
			--diffuse map
			if (mat.diffuseMapEnable) and (mat.diffuseMap != undefined) and (classof mat.diffuseMap == Bitmaptexture) then (	
				
				local filename = filenameFromPath mat.diffuseMap.filename
				WriteText f filename
				
				if (mat.alphaMapEnable) and (filename.count > 0) then (
					--alpha map
					if (mat.alphaMap != undefined) and (classof mat.alphaMap == Bitmaptexture) then (
						local filename = filenameFromPath mat.alphaMap.filename
						WriteText f filename
					)
					else WriteByte f 0   
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

fn CollectObjects = (
	local mobjSet = TObjectSet()

	for obj in objects do (	
		local mnode = TNode()
		
		local nodeType = GetNodeType obj
		case nodeType of (
			#portal: (
				if obj.parent != undefined then (
					local parent_mobj = mobjSet.GetByNode obj.parent
					append parent_mobj.portals obj
				)
			)
			#lod: (
				if obj.parent != undefined then (
					local parent_mobj = mobjSet.GetByNode obj.parent
					append parent_mobj.lods obj
				) 
			)
			#morph: (
				if obj.parent != undefined then (
					local parent_mobj = mobjSet.GetByNode obj.parent
					append parent_mobj.morphs obj
				)
			)	
			default: (
				mnode.baseNode = obj
				mobjSet.Add mnode
			)		
		)		
	)
	
	for mnode in mobjSet.mobjects do (
		qsort mnode.lods CompareNames
		qsort mnode.portals CompareNames
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

fn ExtractSector mnode = (	
	local sector = TSector()
	sector.mesh = snapshotAsMesh mnode.baseNode
	sector.dmin = mnode.baseNode.min
	sector.dmax = mnode.baseNode.max
	
	for portalNode in mnode.portals do (		
		local portal = TPortal()
		local gp = custAttributes.get portalNode MafParams_def baseObject:false
		
		if gp == undefined then (
			portal.nearRange = 0.0
			portal.farRange = 10.0
		)		
		else (
			portal.nearRange = gp.nearRange
			portal.farRange = gp.farRange
		)
		local vertIds = polyop.getFaceVerts portalNode 1

		for id in vertIds do (
			local vert = polyop.getVert portalNode id
			append portal.verts vert
		)
		append sector.portals portal
	)
	
	sector
)

fn ExtractDummy mnode = (
	local mdummy = TDummy()
	mdummy.dmin = in coordsys local mnode.baseNode.min
	mdummy.dmax = in coordsys local mnode.baseNode.max
	mdummy
)

fn GetMafiaMatId mat matid = (
	local mid = 0
	if isKindOf mat MultiMaterial then (
		mat = mat[matid]		
	)
	
	if mat != undefined then (
		local handle = getHandleByAnim mat
		mid = mat_map[handle]
		if mid == undefined then mid = 0
	)

	mid
)

fn CompareWeights v1 v2 = (
	if v1.boneid > v2.boneid then 1
	else if v1.boneid < v2.boneid then -1
	else (
		if v1.weight < v2.weight then 1
		else if v1.weight > v2.weight then -1
		else 0
	)
)

struct WeightedVertex (
	boneid,
	weight,
	vertid
)

fn ConvertMatrix mat3 = (
	local row1 = #(mat3.row1.x, mat3.row1.z, mat3.row1.y, 0)
	local row2 = #(mat3.row3.x, mat3.row3.z, mat3.row3.y, 0)
	local row3 = #(mat3.row2.x, mat3.row2.z, mat3.row2.y, 0)
	local row4 = #(mat3.row4.x, mat3.row4.z, mat3.row4.y, 1)	
	
	#(row1, row2, row3, row4)
)

fn ExtractWeights mnode = (
	local baseNode = mnode.baseNode
		
	local bskin = GetModByClass baseNode Skin
	
	local weights = #()
	
	local numverts = skinOps.GetNumberVertices bskin
	for i = 1 to numverts do (
				
		local count = skinOps.GetVertexWeightCount bskin i 
		
		local weight = 0.0
		if count > 0 then (
			weight = skinOps.GetVertexWeight bskin i 1
		)
		
		local boneid = skinOps.GetVertexWeightBoneID bskin i 1
		
		wv = WeightedVertex()
		wv.boneid = boneid
		wv.weight = weight
		wv.vertid = i
		
		append weights wv
	)
	
	weights
)

fn ExtractSkin mnode weights = (
	local baseNode = mnode.baseNode
	
	local mskins = #()
	
	local mskin = TSkin()
	mskin.numW0Verts = 0
	local range = 0.2
	mskin.dmin = [-range, -range, -range]
	mskin.dmax = [range, range, range]	
	
	local bskin = GetModByClass baseNode Skin
	
	
	--qsort weights CompareWeights
	
	local grp
	
	local oldid = 0
	local groups = #()
	for weight in weights do (
		if oldid != weight.boneid then (
			local jump = weight.boneid - oldid
			
			for i = 0 to jump-1 do (				
				if grp != undefined then append groups grp
				
				local boneid = oldid + i + 1
				
				--format "boneid:%, weight.boneid:%, i:%, oldid:%, oldid+i:%\n" boneid weight.boneid i oldid (oldid + i)
				
				grp = TSkinVertexGroup()
				grp.numW1Verts = 0
				--grp.boneid = boneid - 1
				local range = 0.2
				grp.dmin = [-range, -range, -range]
				grp.dmax = [range, range, range]		
				
				local boneNode = skinOps.GetBoneNode bskin (boneid)
				
				local gp = custAttributes.get boneNode MafParams_def baseObject:false
				grp.boneid = gp.linkedBoneId
				
				local mm = boneNode.transform
				mm[4] = mm[4] - baseNode.transform.pos    --thanks Duelist
				
				local mmi = inverse mm
				
				grp.matrix = ConvertMatrix mmi
			)	
		)
		
		if weight.weight == 1.0 then grp.numW1Verts += 1
		else (
			append grp.weights weight.weight
		)
		
		oldid = weight.boneid
	)
	append groups grp
	
	
	-- format "numVgroups: %\n" groups.count
	-- for grp in groups do (
	-- 	format "numW1Verts:% numWeights:% " grp.numW1Verts grp.weights.count
	-- 	format "%\n" grp
	-- )
	
	
	
	mskin.vgroups = groups
	
	
	
	append mskins mskin
	
	------struct------
	-- boneid = 1
	-- weight = 0.5
	
	------struct------
	-- boneid = 2
	-- weight = 0.5
	
	------struct------
	-- boneid = 1
	-- weight = 1.0	
	
	mskins
)

fn close_enough_p3 v1 v2 prec  = (
	(close_enough v1.x v2.x prec) and (close_enough v1.y v2.y prec)	and (close_enough v1.z v2.z prec)
)

/*
splitVerts

vertId  idOfDuplicatedVertex
  1  =  #(1087, 512, 121, ...)		
  2
  3
  4

*/

fn SplitVertices mesh faceVertNormals = (
	local numverts = mesh.numverts
	local normals = #()   -- min. count = count of vertices, normals for duplicated verts are appended to the end
	local uvs = #()  	  -- =||=
	normals[numverts] = undefined
	uvs[numverts] = undefined
	
	local splitVerts = #()		
	local extraVerts = #()	
	local fixFaces = #()
	
	for i = 1 to mesh.numfaces do (
		local vertIds = getFace mesh i				
		local rnormals = faceVertNormals[i]
		
		local newVertIds = copy vertIds
		
		local tface = getTVFace mesh i
		
		for v = 1 to 3 do (
			local vertId = vertIds[v] as integer
			local normal = rnormals[v]		
			local uv = getTVert mesh (tface[v] as integer)
			
			if normals[vertId] == undefined and uvs[vertId] == undefined then (
				normals[vertId] = normal
				uvs[vertId] = uv
			)
			else (
				local dupedVerts = #(vertId)
				if splitVerts[vertid] != undefined then dupedVerts += splitVerts[vertId]				
				local foundId = -1
				for dupVertId in dupedVerts while foundId == -1 do (
					
					if close_enough_p3 normals[dupVertId] normal 6 then (					
						if close_enough_p3 uvs[dupVertId] uv 6 then (							
							foundId = dupVertId
						)
					)
				)
								
				if foundId == -1 then (   
					--split
					append extraVerts vertId					
					local newVertId = numverts + extraVerts.count					
					
					if splitVerts[vertid] == undefined then splitVerts[vertid] = #()
					append splitVerts[vertid] newVertId
					
					append normals normal
					append uvs uv
					
					newVertIds[v] = newVertId															
				)				
				else if foundId != vertId then   (
					--just repoint face
					newVertIds[v] = foundId
				)
			)				
		)
		
		if newVertIds != vertIds then (
			append fixFaces #(i, newVertIds)
		)
	)
	
	--format "%\n" fixFaces
	
	setNumVerts mesh (numVerts + extraVerts.count) true
	
	for i = 1 to extraVerts.count do (
		local orgVertId = extraVerts[i]
		local newVertId = numVerts + i   --numOrgVerts
		
		local vert = getVert mesh orgVertId
		setVert mesh newVertId vert
	)
	
	for fixFace in fixFaces do (
		setFace mesh fixFace[1] fixFace[2]
	)	
	
	setNumTVerts mesh uvs.count
	for i = 1 to uvs.count do (
		setTVert mesh i uvs[i]
	)
	
	--probably not needed:
	buildTVFaces mesh
	for i = 1 to mesh.numfaces do (
		setTVFace mesh i (getFace mesh i)
	)	
	--
	
	#(mesh, normals)
)

fn ExtractMesh mnode = (
	local mmesh = TMesh()	

	local instances
	local count = InstanceMgr.GetInstances mnode.baseNode &instances
	local masterInstance = instances[count]	
	
	if masterInstance != mnode.baseNode then (  --search for instance id
		mmesh.instanceId = mobjSet.GetIDByNode masterInstance
	)
	else mmesh.instanceId = 0

	if mmesh.instanceId == 0 then ( --is master instance
		local lodnodes = copy mnode.lods #noMap
		insertItem mnode.baseNode lodnodes 1
		
		local prevDist = 0.0
		
		for lodnode in lodnodes do (
			local mlod = TLod()			
			local lodMesh = copy lodnode.mesh			
			local gp = custAttributes.get lodnode MafParams_def baseObject:false	
			
			if gp != undefined then (
				mlod.distance = gp.lodDist
			)
			else (
				if lodnode == lodnodes[lodnodes.count] then mlod.distance = 0.0
				else mlod.distance = prevDist + 100.0
			)
			
			prevDist = mlod.distance
			
			local split = true
			if gp != undefined then split = not gp.dontOptimize
			
			local normMod
			if MafiaTools.exportNormals.state == 2 then normMod = GetModByClass lodnode Edit_Normals
			
			local faceVertNormals = #()
			
			if normMod == undefined then (
				for i = 1 to lodmesh.numfaces do (										
					local rnormals = meshop.getFaceRNormals lodmesh i
					append faceVertNormals rnormals
				)
			)
			else (
				max modify mode
				modpanel.setcurrentobject normMod node:lodnode

				for i = 1 to lodmesh.numfaces do (
					for v = 1 to 3 do (
						local normId = normMod.getnormalid i v
						local rnormals = normMod.getnormal normId
						append faceVertNormals 
					)
				)
			)
			
			
			local normals = #()
			if split then (	
				local spl = SplitVertices lodmesh faceVertNormals
				lodmesh = spl[1]				
				normals = spl[2]
			)			
			else (
				for i = 1 to lodmesh.numfaces do (
					local vertIds = getFace lodmesh i
					local rnormals = faceVertNormals[i]
					for v = 1 to 3 do (
						local vertId = vertIds[v]
						normals[vertId] = rnormals[v]
					)
				)
			)
			
			mlod.mesh = lodmesh
			mlod.normals = normals
			
			local fcgrpSet = TFacegroupSet()
			
			for i = 1 to lodmesh.numfaces do (
				local matid = getFaceMatID lodmesh i
				local mafMatId = GetMafiaMatId lodnode.mat matid
				
				local facegroup = fcgrpSet.GetByMatId mafMatId
				append facegroup.faceIds i
				
				--append mlod.matIds mafMatId
			)
			
			mlod.facegroups = fcgrpSet.facegroups
						
			append mmesh.lods mlod
		)
	)	
	mmesh
)

fn ExtractBillboard mnode = (
	local mbillboard = TBillboard()
	local gp = custAttributes.get mnode.baseNode MafParams_def baseObject:false
	mbillboard.rotAxis = gp.rotAxis - 1
	mbillboard.rotMode = gp.rotMode - 1	
	mbillboard
)

fn FloatArrayToMatrix floats = (
	local i = 1
	local mtr = #()
	for m = 1 to 4 do (
		mtr[m] = #()
		for n = 1 to 4 do (
			mtr[m][n] = floats[i]
			i += 1
		)
	)
	mtr
	
)

fn ExtractBone mnode = (
	mbone = TBone()
	mbone.boneId = mnode.baseNode.boneId
	
	mbone.matrix = #( 
		#(1,0,0,0), 
		#(0,1,0,0),
		#(0,0,1,0),
		#(0,0,0,1)
	)
	
	mbone
)

fn ExtractTarget mnode mobjSet = (
	local mtarget = TTarget()
	
	local gp = custAttributes.get mnode.baseNode MafParams_def baseObject:false
	
	for linkedNode in gp.targetLinks do (
		append mtarget.linkIds (mobjSet.GetIDByNode linkedNode)
	)
		
	mtarget	
)

fn ExtractObject mnode mobjSet = (
	local mobj = MObject()
		

	local nnode = mnode.baseNode
	local nodeType = GetNodeType nnode	
	
	mobj.cullFlags = 9
	mobj.renderFlags2 = 42
	
	case nodeType of (
		#mesh: (
			mobj.objectType = 1
			mobj.visualType = 0
			mobj.definitions[1] = ExtractMesh mnode				
		)
		#singlemesh: (
			mobj.objectType = 1
			mobj.visualType = 2
			local weights = ExtractWeights mnode
			local mmesh = ExtractMesh mnode	&weights
			local mskin = ExtractSkin mnode	weights
			mobj.definitions[1] = mmesh	
			mobj.definitions[2] = mskin			
		)
		#billboard: (
			mobj.objectType = 1
			mobj.visualType = 4
			mobj.definitions[1] = ExtractMesh mnode
			mobj.definitions[2] = ExtractBillboard mnode			
		)
		#sector: (
			mobj.objectType = 5
			mobj.cullFlags = 125
			mobj.definitions[1] = ExtractSector mnode
		)
		#dummy: (
			mobj.objectType = 6
			mobj.definitions[1] = ExtractDummy mnode
		)
		#bone: (
			mobj.objectType = 10
			mobj.definitions[1] = ExtractBone mnode
		)
		#target: (
			mobj.objectType = 7
			mobj.definitions[1] = ExtractTarget mnode mobjSet
		)
		default: (
			mobj.objectType = 6
			mobj.definitions[1] = ExtractDummy mnode
		)
	)	
	
	local gp = custAttributes.get nnode MafParams_def baseObject:false
	if gp != undefined then (
		mobj.cullFlags = gp.cullFlags
		mobj.renderFlags = gp.renderFlags
		mobj.renderFlags2 = gp.renderFlags2
		mobj.strParams = gp.strParams
	)
	
	mobj.name = mnode.baseNode.name	
	mobj.parentId = mobjSet.GetIDByNode mnode.baseNode.parent	
	
	if mobj.objectType == 5 then (
		mobj.offset = [0,0,0]
		mobj.scl = [1,1,1]
		mobj.rot = [0,0,0,1]
	)
	else (
		if (nnode.parent != undefined) and (GetNodeType nnode.parent == #sector) then (
			in coordsys world
			(
				mobj.offset = mnode.baseNode.pos
				mobj.scl = mnode.baseNode.scale
				mobj.rot = mnode.baseNode.rotation
			)
		)
		else (
			in coordsys parent
			(
				mobj.offset = mnode.baseNode.pos
				mobj.scl = mnode.baseNode.scale
				mobj.rot = mnode.baseNode.rotation
			)
		)
	)
	
	mobj	
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

fn WriteObjects f = (
	local mobjSet = CollectObjects()
	local mnodes = mobjSet.mobjects

	WriteShort f mnodes.count

	for mnode in mnodes do (	
		local mobj = ExtractObject mnode mobjSet
		WriteObject f mobj
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