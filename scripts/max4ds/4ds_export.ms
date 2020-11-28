rollout MafiaTools_4dsExport "" (   --module

    --imports------------
    local parser = ::MafiaTools_4dsParser
    local util = ::MafiaTools_Util
    ---------------------    
    
    --forward function declarations
    local GetNodeType
    -------------------------------

    local USE_EDIT_NORMALS
    local USE_CACHED_NORMALS    
  
    local MAT_SET
    
    local BONE_IDS
    
    local WARN_MORPH
    local WARN_PORTAL

    struct TNode (
        baseNode,
        type,
        lods = #(),
        portals = #(),
        viewbox,   --rendered volume for mirrors
        rootBone,
        bones
    )

    struct TNodeSet (
        mnodes = #(),       --list of objects as they are about to be exported
        mnode_ids = #(),        --key = node handle, value = id in mnodes

        fn GetIdFromHandle handle = (    --Get Mafia object id from node handle
            mnode_ids[handle]
        ),

        fn GetByNode obj = (           --Get TNode from node, returns undefined if not found
            local mnode
            if obj != undefined then (
                local handle = obj.inode.handle
                local mid = GetIdFromHandle handle
                if mid != undefined then mnode = mnodes[mid]
            )
            mnode
        ),

        fn GetIdByNode obj = (           --Get TNode ID from node, returns 0 if not found
            if obj != undefined then (
                local handle = obj.inode.handle
                local id = mnode_ids[handle]
                if id == undefined then 0 else id
            )
            else (
                0
            )
        ),

        fn Add obj mnode = (          --Add TNode to collection
            local handle = obj.inode.handle
            append mnodes mnode
            mnode_ids[handle] = mnodes.count
        ),

        fn AddPointer obj id = (   --Add pointer (node handle) to mnode id
            local handle = obj.inode.handle

            mnode_ids[handle] = id
        )
    )

    struct TFacegroupSet (
        facegroups = #(),   --array of MFacegroup
        facegroup_ids = #(),   --get facegroup id from matid

        fn GetByMatId matid = (
            matid = matid + 1
            local grp_id = facegroup_ids[matid]

            if grp_id == undefined then (
                local grp = parser.TFacegroup matid:matid
                append facegroups grp
                grp_id = facegroups.count
                facegroup_ids[matid] = grp_id
            )
            facegroups[grp_id]
        )
    )

    struct TMatSet (
        mafia_materials = #(),
        mat_map = #(),

        fn AddToMafiaMaterials mat = (
            local handle = GetHandleByAnim mat

            if mat_map[handle] == undefined then (
                append mafia_materials mat
                mat_map[handle] = mafia_materials.count
            )
        ),

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
    )

    struct WeightedVertex (
        boneid,
        weight,
        vertid
    )

    struct VertBone (
        boneid,
        weight
    )
    
        
    fn MinMax dmin dmax vert = (
        if vert.x < dmin.x do dmin.x = vert.x
        if vert.y < dmin.y do dmin.y = vert.y
        if vert.z < dmin.z do dmin.z = vert.z
        
        if vert.x > dmax.x do dmax.x = vert.x
        if vert.y > dmax.y do dmax.y = vert.y
        if vert.z > dmax.z do dmax.z = vert.z
    )

    fn close_enough_p3 v1 v2 prec  = (
        (close_enough v1.x v2.x prec) and (close_enough v1.y v2.y prec) and (close_enough v1.z v2.z prec)
    )

    fn CompareNodesByName obj1 obj2 = stricmp obj1.name obj2.name

    fn ConvertStandardMaterial mat = (
        local cm = Mat4ds()

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
        local cm = Mat4ds()

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

        -- local glossiness = 0.0
        -- if mat.roughness_inv then (
        --  glossiness = mat.roughness
        -- )
        -- else (
        --  glossiness = 1.0 - mat.roughness
        -- )

        -- if glossiness >= 0.05 then (
        --  cm.envMapAmount = glossiness * 100
        --  cm.envMap = bitmaptexture filename:"env2.bmp"
        -- )

        cm
    )

    fn CollectMaterials = (
        MAT_SET = TMatSet()

        for mat in sceneMaterials do (
            if isKindOf mat MultiMaterial then (
                for submat in mat.materialList where submat != undefined do (

                    if util.containsItem #(Standard, Physical_Material, Mat4ds) (classOf subMat) then (
                        MAT_SET.AddToMafiaMaterials submat
                    )
                )
            )
            else (
                if util.containsItem #(Standard, Physical_Material, Mat4ds) (classOf mat) then (
                    MAT_SET.AddToMafiaMaterials mat
                )
            )
        )
        MAT_SET.mafia_materials
    )

    fn ExtractMaterials mafia_materials = (
        local mmaterials = #()

        for mat in mafia_materials do (

            if classof mat == Standard then (
                mat = ConvertStandardMaterial mat
            )
            else if classof mat == Physical_Material then (
                mat = ConvertPhysicalMaterial mat
            )

            if classof mat == Mat4ds then  (
                local mmat = parser.TMaterial()

                local flags = 0
                flags += (bit.set 0 1 true)

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
                flags += (bit.set 0 25 mat.imageAlpha)

                mmat.flags = flags

                mmat.ambient = mat.ambient
                mmat.diffuse = mat.diffuse
                mmat.emission = mat.emission
                
                mmat.specular = mat.specular
                mmat.glossiness = mat.glossiness

                mmat.opacity = mat.opacity / 100.0

                mmat.envMapAmount = mat.envMapAmount / 100.0

                if (mat.envMap != undefined) and (classof mat.envMap == Bitmaptexture) then (
                    mmat.envMapName = filenameFromPath mat.envMap.filename
                )

                if (mat.diffuseMap != undefined) and (classof mat.diffuseMap == Bitmaptexture) then (
                    mmat.diffMapName = filenameFromPath mat.diffuseMap.filename
                )

                if (mat.alphaMap != undefined) and (classof mat.alphaMap == Bitmaptexture) then (
                    mmat.alphaMapName = filenameFromPath mat.alphaMap.filename
                )

                mmat.animFrames = mat.animFrames
                mmat.animPeriod = mat.animPeriod


                append mmaterials mmat
            )
        )
        mmaterials
    )

    fn CollectNodes = (
        local util = ::MafiaTools_util
        local nodeTypes = #()
        local rootBones = #()
        -- local str = "$volume"
        -- local strPattern = str + "*"
        
        BONE_IDS = #()
        
        for obj in objects do (
            local type = nodeTypes[obj.inode.handle]
            if type == undefined then (
                
                -- if matchPattern obj.name pattern:strPattern do (
                --     if obj.parent != undefined and isKindOf obj.parent GeometryClass do (
                --         obj.name = replace obj.name 1 str.count "$viewbox"
                --     )
                -- )
            
                type = GetNodeType obj

                if type == #singlemesh or type == #singlemorph then (
                    if (local skinMod = util.GetModByClass obj Skin) != undefined then (
                        local bns = util.GetBoneNodes skinMod

                        for boneNode in bns do (
                            local handle = boneNode.inode.handle
                            nodeTypes[handle] = #bone
                        )
                        if obj.parent == undefined then (
                            throw "Skinned mesh needs a parent bone. Use the 'Convert old skeleton' tool or add a root bone."
                        )
                        nodeTypes[obj.parent.inode.handle] = #rootBone
                        rootBones[obj.inode.handle] = obj.parent                        
                    )
                )
                
                if type == #singlemorph or type == #morph then (
                    if (local mrph = util.GetModByClass obj Morpher) != undefined then (
                        local nodes = util.GetDependingNodes mrph
                        
                        for node in nodes do (
                            local handle = node.inode.handle
                            nodeTypes[handle] = #morph_target
                        )
                    )
                )

                nodeTypes[obj.inode.handle] = type
            )
        )

        local mnodeSet = TNodeSet()

        for obj in objects do (
            local mnode = TNode()

            local nodeType = nodeTypes[obj.inode.handle]
            --format "nodeType: %\n" nodeType
            case nodeType of (
                #portal: (
                    if obj.parent != undefined then (
                        local parentMnode = mnodeSet.GetByNode obj.parent
                        append parentMnode.portals obj
                        
                        if classof obj != Editable_Poly and classof obj != PolyMeshObject then (
                            select obj
                            throw "Portals must be Editable Poly! " obj.name
                        )
                    )
                )
                #lod: (
                    if obj.parent != undefined then (
                        local parentMnode = mnodeSet.GetByNode obj.parent
                        append parentMnode.lods obj
                    )
                )
                #singlemesh: (
                    local id = mnodeSet.GetIdByNode rootBones[obj.inode.handle]
                    
                    local mnode = mnodeSet.mnodes[id]
                    
                    mnode.baseNode = obj
                    mnode.type = #singlemesh
                    mnodeSet.AddPointer obj id
                    
                    local sortedBones = #()
                        
                    local rootbone = rootBones[obj.inode.handle]                    
                    
                    local boneId = 1
                    for kobj in rootbone do (
                        local handle = kobj.inode.handle
                        local type = nodeTypes[handle]
                        if type == #bone or type == #rootbone then (
                            append sortedBones kobj
                            
                            BONE_IDS[handle] = boneId
                            boneId += 1
                        )
                    )
                    mnode.bones = sortedBones
                )
                #singlemorph: (
                    local id = mnodeSet.GetIdByNode rootBones[obj.inode.handle]
                    
                    local mnode = mnodeSet.mnodes[id]

                    mnode.baseNode = obj
                    mnode.type = #singlemorph
                    mnodeSet.AddPointer obj id
                    
                    local sortedBones = #()
                    
                    local rootbone = rootBones[obj.inode.handle]                    
                    
                    local boneId = 1
                    for kobj in rootbone do (
                        local handle = kobj.inode.handle
                        local type = nodeTypes[handle]
                        if type == #bone or type == #rootbone then (
                            append sortedBones kobj
                            
                            BONE_IDS[handle] = boneId
                            boneId += 1
                        )
                    )
                    mnode.bones = sortedBones
                )
                #rootbone: (
                    local mnode = mnodeSet.GetByNode obj
                    if mnode == undefined then (
                        mnode = TNode()
                        mnode.rootBone = obj
                        mnodeSet.Add obj mnode
                    )
                )
                #viewbox: (
                    if obj.parent != undefined then (
                        local parentMnode = mnodeSet.GetByNode obj.parent
                        parentMnode.viewbox = obj
                    )
                )
                #morph_target: ()
                default: (
                    local mnode = TNode()
                    mnode.baseNode = obj
                    mnode.type = nodeType
                    mnodeSet.Add obj mnode
                )
            )

            --format "obj:%  type:% \n" obj.name nodeType
        )

        for mnode in mnodeSet.mnodes do (
            qsort mnode.lods CompareNodesByName
            qsort mnode.portals CompareNodesByName
        )

        mnodeSet
    )

    fn ExtractSector mnode unitscale version = (
        local sector = parser.TSector()
        sector.flags1 = 2049
        sector.flags2 = 0
        if version == #mafia then (
            sector.mesh = snapshotAsMesh mnode.baseNode
            sector.dmin = mnode.baseNode.min * unitscale
            sector.dmax = mnode.baseNode.max * unitscale
            
            util.TransformVerts sector.mesh unitscale
        )
        else (
            sector.mesh = copy mnode.baseNode.mesh
            sector.dmin = in coordsys local mnode.baseNode.min * unitscale
            sector.dmax = in coordsys local mnode.baseNode.max * unitscale
            
            local baseNode = mnode.baseNode
            
            local scl = scaleMatrix [unitscale,unitscale,unitscale]
            local otrans = baseNode.objectTransform * inverse baseNode.transform * scl
    
            --apply object offset to mesh
            util.TransformVerts sector.mesh otrans
        )

        local sgp = custAttributes.get mnode.baseNode MafParams_def baseObject:false
        if sgp != undefined then (
            sector.flags1 = sgp.sectorFlags1
            sector.flags2 = sgp.sectorFlags2
        )
      
        

        for portalNode in mnode.portals do (
            local portal = parser.TPortal()

            portal.flags = 4
            portal.nearRange = 0
            portal.farRange = 0
            portal.normal = [0,0,0]
            portal.dotp = 0
            portal.unknown = 0
            
            local gp = custAttributes.get portalNode MafParams_def baseObject:false
            if gp != undefined then (
                portal.flags = gp.portalFlags
                portal.nearRange = gp.portalNearRange
                portal.farRange = gp.portalFarRange
                portal.unknown = gp.portalUnknown
            )
            
            local numFaces = polyop.getNumFaces portalNode
            
            local tr = TriMesh()
            
            if numFaces > 0 then (
                local vertIds = polyop.getFaceVerts portalNode 1            
                tr.numVerts = vertIds.count
    
                local newVertId = 1
                for id in vertIds do (
                    if version == #mafia then local vert = polyop.getVert portalNode id
                    else local vert = in coordsys local polyop.getVert portalNode id
                    setVert tr newVertId (vert * unitscale)
                    newVertId += 1
                )
                
                local normal = polyop.getFaceNormal portalNode 1
                portal.normal = -normal
                portal.dotp = dot (getVert tr 1) normal
            )
            
            if numFaces > 1 then (
                format "% (%) has more than 1 face! numFaces: %\n" portalNode.name mnode.baseNode.name numFaces
                WARN_PORTAL = true
            )

            portal.mesh = tr
            append sector.portals portal
        )

        sector
    )

    fn ExtractDummy mnode unitscale = (
        local mdummy = parser.TDummy()
        mdummy.dmin = in coordsys local mnode.baseNode.min * unitscale
        mdummy.dmax = in coordsys local mnode.baseNode.max * unitscale
        mdummy
    )
    
    
    -----SKIN-------------------------------------------
    ----------------------------------------------------

    fn CompareWeights v1 v2 = (
        if v1.boneid != 1 and v2.boneid == 1 then -1
        else if v2.boneid != 1 and v1.boneid == 1 then 1
        else (            
            if v1.boneid < v2.boneid then -1
            else if v2.boneid < v1.boneid then 1
            else (                
                if v1.weight == 1.0 and v2.weight < 1.0 then -1
                else if v2.weight == 1.0 and v1.weight < 1.0 then 1
                else 0
            )
        )
    )

    fn CompareVertBones v1 v2 = (
        if v1.weight > v2.weight then -1
        else if v2.weight > v1.weight then 1
        else 0
    )
    
    fn GetGlobalBoneIds skinBones bonenodes = (
        for skinBone in skinBones collect (
            findItem bonenodes skinBone
        )
    )
    
    --------------------------------------------------------------------------
    -- Creates an array of weights, where for each vert only one weight is picked.
    -- (The second weight is not specified - the remainder gets assigned to the parent bone automatically.)
    -- First it finds the two highest weights, then:
    --     if the highest weight is < 0.98 and the second weight is descendant, the second is picked
    --     else the highest is picked
    --------------------------------------------------------------------------
    -- returns 'undefined' if it has no skin modifier or if the weight table is empty
    fn ExtractWeights lodnode bonenodes = (
        local bskin = util.GetModByClass lodnode Skin 
        local weights
        
        if bskin != undefined then (
            local maxver = (maxVersion())[1]
            if maxver < 22000 then (
                max modify mode
                modPanel.setCurrentObject bskin
            )

            local xskin = skin_makeCache bskin

            local skinBones = util.GetBoneNodes bskin
            
            local numverts = skinOps.GetNumberVertices bskin
            
            weights = for vertId = 1 to numverts collect (
                local numWeights = skinOps.GetVertexWeightCount bskin vertId

                local weight = 0.0
                local boneid
                if numWeights == 1 then (
                    weight = skinOps.GetVertexWeight bskin vertId 1
                    boneid = skin_getVertexWeightBoneId xskin vertId 1
                )
                else if numWeights > 1 then (
                    --sort weights by the highest weight
                    local vertBones = for n = 1 to numWeights collect (
                        local w = skinOps.GetVertexWeight bskin vertId n
                        local id = skin_getVertexWeightBoneId xskin vertId n
                        VertBone boneid:id weight:w
                    )
                    qsort vertBones CompareVertBones

                    local weight1 = vertBones[1].weight
                    local weight2 = vertBones[2].weight
                    local boneid1 = vertBones[1].boneid
                    local boneid2 = vertBones[2].boneid

                    local sum = weight1 + weight2
                    weight = weight1 / sum
                    boneid = boneid1
                    
                    if weight < 0.98 then (
                        local boneNode1 = skinBones[boneid1]
                        local boneNode2 = skinBones[boneid2]
                        if util.isDescendantOf boneNode2 boneNode1 then (
                            weight = weight2 / sum
                            boneid = boneid2
                        )
                    )
                )
                
                -- for skin local boneid returns global boneid -> globalBoneIds[localId]
                local globalBoneIds = GetGlobalBoneIds skinBones bonenodes
                
                local globalBoneId
                if boneid == undefined then (
                    globalBoneId = 1
                )
                else (
                    globalBoneId = globalBoneIds[boneid]
                )               

                wv = WeightedVertex()
                wv.boneid = globalBoneId
                wv.weight = weight
                wv.vertid = vertId

                wv
            )
        )
        if weights != undefined and weights.count == 0 then weights = undefined
        
        weights
    )
    
    fn SplitWeights weights extraVerts = (
        -- split weights
        local newVertId = weights.count + 1
        for vertId in extraVerts do (
            local wv = WeightedVertex()
            wv.boneid = weights[vertId].boneid
            wv.weight = weights[vertId].weight
            wv.vertId = newVertId

            append weights wv

            newVertId += 1
        )
    )  
    
    -- Sorts 'weights' by weight, weights is mutated.
    -- returns vertOrder, where value is the new vertex id
    fn SortWeights weights = (
        qsort weights CompareWeights
        local vertOrder = #()
        vertOrder[weights.count] = undefined

        for i = 1 to weights.count do (
            vertOrder[weights[i].vertid] = i
        )
        vertOrder
    )
    
    fn SortMesh tr vertOrder = (
        local newtr = TriMesh()
        newtr.numverts = tr.numverts
        newtr.numtverts = tr.numtverts
        newtr.numfaces = tr.numfaces

        for oldId = 1 to tr.numverts do (
            local newId = vertOrder[oldId]
            setVert newtr newId (getVert tr oldId)
            setTVert newtr newId (getTVert tr oldId)
            setNormal newtr newId (getNormal tr oldId)
        )

        for faceId = 1 to tr.numfaces do (
            local face = getFace tr faceId
            for v = 1 to 3 do (
                face[v] = vertOrder[face[v]]
            )
            setFace newtr faceId face
            
            setFaceMatID newtr faceId (getFaceMatID tr faceId)
        )
        newtr
    )
    
    fn ExtractSkinLod splmesh boneNodes unitscale = (
        local weights = splmesh.weights
        local lodmesh = splmesh.mesh
        
        if weights == undefined then weights = #()
    
        local size = 10.0 ^ 16    --this value is used in original 4ds files
        local mskin = parser.TSkinCommon()
        
        local groups = #()
        
        local rootbone = boneNodes[1]
        
        for i = 1 to boneNodes.count do (
            local grp = parser.TJointInfo()
            
            grp.dmin = [size, size, size]
            grp.dmax = [-size, -size, -size]

            if i != 1 then (  --skip matrix for root bone
                local boneTF = boneNodes[i].transform
                local t = transMatrix (boneTF.translationpart * unitscale)
                local s = scaleMatrix boneTF.scalepart
                local r = boneTF.rotationpart as matrix3
                local boneTFs = s * r * t
    
    
                local rootTF = rootbone.transform
                local t = transMatrix (rootTF.translationpart * unitscale)
                local s = scaleMatrix rootTF.scalepart
                local r = rootTF.rotationpart as matrix3
                local rootTFs = s * r * t
    
                local mm = boneTFs * (inverse rootTFs)
    
                grp.matrix = inverse mm
            )
            else grp.matrix = matrix3 1

            append groups grp
        )
        
        local vertId = 1

        for weight in weights do (
            local grp = groups[weight.boneId]
            local vert = (getVert lodmesh vertid) * grp.matrix
            MinMax grp.dmin grp.dmax vert

            vertId += 1
        )
        
        
        --for global bone id, returns its parent global bone id, undefined if no parent
        local parentIds = for boneNode in boneNodes collect (
            local parentId
            if boneNode.parent != undefined then (
                parentId = findItem boneNodes boneNode.parent
            )
            if parentId == 0 then parentId = undefined
            parentId
        )
        mskin.parentIds = parentIds
        mskin.jointInfo = groups
        mskin.weights = weights
        
        mskin
    )    
    
    -----------MORPH------------------------------------
    ----------------------------------------------------
    
    struct TRegionInfo (
        usedChannels = #{},
        usedVerts = #{},
        channels = #()
    )

    --trims trailing unused regions (keeps the leading)
    fn TrimUnused regions = (
        local finished = false
        for i = regions.count to 1 by -1 while not finished do (
            if regions[i].usedChannels.numberset == 0 then (
                deleteItem regions i
            )
            else finished = true
        )
    )

    fn FindBiggestChannelId regions = (
        local biggest = 0
        for regionInfo in regions do (
            local largestIndex = regionInfo.usedChannels.count
            if largestIndex > biggest then biggest = largestIndex
        )

        biggest
    )
    
    fn SplitChanMesh chanMesh extraVerts = (
        local numverts = chanMesh.numverts
        setNumVerts chanMesh (numverts + extraVerts.count) true

        local newVertId = numverts + 1

        for vertId in extraVerts do (
            setVert chanMesh newVertId (getVert chanMesh vertId)
            newVertId += 1
        )
    )

    fn SplitMorphVertices regions extraVerts = (
        for regionInfo in regions do (
            for chanId in regionInfo.usedChannels do (
                local chanMesh = regionInfo.channels[chanId]
                
                SplitChanMesh chanMesh extraVerts
            )
        )
    )
    
    fn ExtractRegions mrph baseNumverts otrans unitscale = (
      
        local regions = #()
        
        local numChannels = 
            if WM3_NumberOfChannels == undefined then 100
            else WM3_NumberOfChannels mrph
            
        local channelsPerRegion = 10
        local maxRegions = ( numChannels / channelsPerRegion ) as integer

        --collect morph meshes
        for regionId = 1 to maxRegions do (
            local regionInfo = TRegionInfo()
            for j = 1 to channelsPerRegion do (
                local chanId = ((regionId - 1) * channelsPerRegion) + j
                local hasData = WM3_MC_HasData mrph chanId
                local isValid = WM3_MC_IsValid mrph chanId
                local isActive = WM3_MC_IsActive mrph chanId

                local chanMesh
                if hasData and isValid and isActive then (
                    regionInfo.usedChannels[j] = true

                    local numpts = amin #((WM3_MC_NumPts mrph chanId), baseNumverts)
                    chanMesh = TriMesh()
                    chanMesh.numverts = numpts
                    for vertId = 1 to numpts do (
                        local pt = WM3_MC_GetMorphPoint mrph chanId (vertId-1)
                        setVert chanMesh vertId (pt * otrans)
                    )
                )
                regionInfo.channels[j] = chanMesh
            )
            append regions regionInfo
        )

        --trim unused regions
        TrimUnused regions
        
        regions
    )

    fn ExtractMorphLod splmesh = ( 
        local regions = splmesh.regions
        local lodmesh = splmesh.mesh
        local vertOrder = splmesh.vertOrder
        
        if vertOrder == undefined then (
            vertOrder = for i = 1 to lodmesh.numverts collect i
        )
        
        local mmorph = parser.TMorph()
        
        if regions.count == 0 then (
            mmorph.numTargets = 1
        )
        else (
            local numTargets = FindBiggestChannelId regions
            mmorph.numTargets = numTargets

            --find changed verts
            for regionInfo in regions do (
                for chanId in regionInfo.usedChannels do (
                    local chanMesh = regionInfo.channels[chanId]

                    for vertId = 1 to chanMesh.numverts do (
                        local baseVert = getVert lodmesh vertOrder[vertId]
                        local chanVert = getVert chanMesh vertId

                        if not close_enough_p3 baseVert chanVert 50 do (
                            regionInfo.usedVerts[vertId] = true
                            
                            if chanId == 1 do (
                                WARN_MORPH = true
                            )
                        )
                    )
                )
            )

            local vmin
            local vmax
            
            local morphlod = parser.TMorphLod()

            for i = 1 to regions.count do (
                local regionInfo = regions[i]
                local mregion = parser.TMorphRegion()

                for vertId in regionInfo.usedVerts do (

                    local corrId = vertOrder[vertId]

                    local mvert = parser.TMorphVertex index:corrId
                    for j = 1 to numTargets do (
                        local chanMesh = regionInfo.channels[j]

                        local pt
                        if chanMesh != undefined then (
                            pt = getVert chanMesh vertId
                        )
                        else (
                            pt = getVert lodmesh corrId
                        )

                        local normal = getNormal lodmesh corrId

                        if vmin == undefined and vmax == undefined then (
                            -- so that vmin and vmax don't share the same reference between each other
                            vmin = copy pt
                            vmax = copy pt
                        )
                        else (                        
                            MinMax vmin vmax pt
                        )

                        local mpoint = parser.TMorphedPoint pos:pt normal:normal
                        append mvert.points mpoint
                    )
                    append mregion.vertices mvert
                )
                append morphlod.regions mregion
            )    
            
            append mmorph.lods morphlod
            
            mmorph.numRegions = regions.count

            -- thanks Duelist
            mmorph.dmin = vmin
            mmorph.dmax = vmax
            mmorph.center = (vmin + vmax) / 2
            mmorph.radius = (distance vmin vmax) / 2
        )

        mmorph
    )
    
    
    ------MESH------------------------------------------
    ----------------------------------------------------

    fn SplitVertices mesh faceVertNormals weights regions = (
        local numverts = mesh.numverts
        local normals = #()   -- min. count = count of vertices, normals for duplicated verts are appended to the end
        local uvs = #()     -- =||=

        normals[numverts] = undefined
        uvs[numverts] = undefined

        local uvSupported = meshop.getMapSupport mesh 1

        /*
        splitVerts

        vertId  idOfDuplicatedVertex
        1  =  #(1087, 512, 121, ...)
        2
        3
        4

        */
        local splitVerts = #()
        local extraVerts = #()
        local fixFaces = #()

        -- Loop through all faces and trough each corner.
        -- From each corner we'll get a vertex id (same vertex may be used in multiple corners),
        -- Corners in different faces with the same vert id, might have different normal and uv values.
        -- If the values are different we need to split (duplicate) the vertex -
        -- - create a new vertex with the same position but with different 'data' (uv and normal)
        for i = 1 to mesh.numfaces do (
            local vertIds = getFace mesh i
            local rnormals = faceVertNormals[i]   --get normals for current face (1 per corner, => 3 in total)
            if rnormals == undefined then rnormals = #([0,0,1], [0,0,1], [0,0,1])
            

            local newVertIds = copy vertIds

            local tface
            if uvSupported then (
                tface = getTVFace mesh i
            )

            for v = 1 to 3 do (
                local vertId = vertIds[v] as integer
                local normal = rnormals[v]
                local uv = [0,0,0]
                if tface != undefined then (
                    uv = getTVert mesh (tface[v] as integer)
                )

                --if data for existing vert is empty, assign it
                if normals[vertId] == undefined and uvs[vertId] == undefined then (
                    normals[vertId] = normal
                    uvs[vertId] = uv
                )
                else (  --data is not empty, we need to check if
                    local dupedVerts = #(vertId)
                    if splitVerts[vertid] != undefined then dupedVerts += splitVerts[vertId]

                    -- id of vertex where the same data was found,
                    -- -1 if the data differs, new vert has to be created
                    local foundId = -1

                    for dupVertId in dupedVerts while foundId == -1 do (
                        if close_enough_p3 normals[dupVertId] normal 6 then (
                            if close_enough_p3 uvs[dupVertId] uv 6 then (
                                --this vertex data is the same, no need to duplicate the vert!
                                foundId = dupVertId
                            )
                        )
                    )

                    -- data differs, I need new vertex!
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
                    else if foundId != vertId then (  --if data is the same,
                        --just repoint face
                        newVertIds[v] = foundId
                    )
                )
            )

            if newVertIds != vertIds then (
                append fixFaces #(i, newVertIds)
            )
        )


        --------APPLY CHANGES TO THE MESH------------

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


        -----apply per vertex uvs to mesh map channel
        --format "uvs count % \n" uvs.count
        setNumTVerts mesh uvs.count
        for i = 1 to uvs.count do (
            local uv = uvs[i]
            if uv == undefined then uv = [0,0,0]

            setTVert mesh i uv
        )
        ------------------------------------


        for i = 1 to normals.count do (
            local normal = normals[i]
            if normal == undefined then normal = [0,0,1]

            setNormal mesh i normal
        )
        
        --------SPLIT WEIGHTS
        if weights != undefined then (
            SplitWeights weights extraVerts
        )
        
        --------SPLIT MORPH REGIONS
        if regions != undefined then (
            SplitMorphVertices regions extraVerts
        )
    )

    fn GetMainInstance obj = (
        local instances
        local count = InstanceMgr.GetInstances obj &instances

        instances[count]
    )

    fn ExtractCachedNormals cmod = (
        local faceVertNormals = #()

        for nface in cmod.normalFaces do (
            local rnormals = #()
            for v = 1 to 3 do (
                local normalId = nface[v]
                rnormals[v] = cmod.normals[normalId]
            )
            append faceVertNormals rnormals
        )

        faceVertNormals
    )

    fn ExtractEditNormals normMod obj lodmesh = (
        local faceVertNormals = #()
        max modify mode
        modpanel.setcurrentobject normMod node:obj

        for i = 1 to lodmesh.numfaces do (
            local rnormals = #()
            for v = 1 to 3 do (
                local normId = normMod.getnormalid i v
                rnormals[v] = normMod.getnormal normId
            )
            append faceVertNormals rnormals
        )

        faceVertNormals
    )

    fn ExtractSGroupNormals lodmesh = (
        local faceVertNormals = #()
        for i = 1 to lodmesh.numfaces do (
            local rnormals = meshop.getFaceRNormals lodmesh i
            append faceVertNormals rnormals
        )

        faceVertNormals
    )

    --extracts per face vertex normals from mesh into array
    fn ExtractNormals lodnode lodmesh = (
        local faceVertNormals = #()

        local normMod
        if USE_EDIT_NORMALS then normMod = util.GetModByClass lodnode Edit_Normals

        if normMod != undefined then (
            faceVertNormals = ExtractEditNormals normMod lodnode lodmesh
        )
        else (
            local cmod
            if USE_CACHED_NORMALS then cmod = util.GetModByClass lodnode CachedNormals

            if cmod != undefined then (
                faceVertNormals = ExtractCachedNormals cmod
            )
            else (
                faceVertNormals = ExtractSGroupNormals lodmesh
            )
        )

        faceVertNormals
    )
    
    struct TSplitMesh (
        mesh,   --trimesh
        weights,  --array of WeightedVertex
        regions,
        vertOrder
    )
    
    fn ExtractSplitMesh lodnode rootbone unitscale bonenodes version = (
        local morphMod = util.GetModByClass lodnode Morpher
        --local values
        if morphMod != undefined then (
            local numChannels = 
                if WM3_NumberOfChannels == undefined then 100
                else WM3_NumberOfChannels morphMod
                
            local values = for chanId = 1 to numChannels collect (
                val = WM3_MC_GetValue morphMod chanId
                WM3_MC_SetValue morphMod chanId 0.0
                val
            )
        )
        
        local lodmesh = copy lodnode.mesh
        
        if values != undefined then (
            for chanId = 1 to values.count do (
                WM3_MC_SetValue morphMod chanId values[chanId]
            )
        )
        
        
        ---get unit scale and object offset transform
        local scl = scaleMatrix [unitscale,unitscale,unitscale]
        local otrans = lodnode.objectTransform * inverse lodnode.transform * scl

        if rootbone != undefined then (
            local offsetTrans = lodnode.objectTransform * inverse lodnode.transform
            otrans = offsetTrans * (lodnode.transform * inverse rootbone.transform) * scl
        )
        
        -----------------------------

        local faceVertNormals = ExtractNormals lodnode lodmesh        
         
        local weights = ExtractWeights lodnode bonenodes
        
        
             
        local regions = 
            if morphMod != undefined then
                ExtractRegions morphMod lodmesh.numverts otrans unitscale
        
        if lodmesh.numverts > 0 then SplitVertices lodmesh faceVertNormals weights regions


        --apply transformation
        for vertId = 1 to lodmesh.numverts do (
            local vert = getVert lodmesh vertId
            setVert lodmesh vertId (vert * otrans)

            --rotate normals
            local normal = getNormal lodmesh vertId
            setNormal lodmesh vertId (normal * otrans.rotationpart)
        )
        
        -------------------------------------------------------
        -------------------------------------------------------
        ---if has skin
        
        local vertOrder
        if weights != undefined and version == #mafia then (
            vertOrder = SortWeights weights
            lodmesh = SortMesh lodmesh vertOrder
        )
        
        TSplitMesh mesh:lodmesh weights:weights regions:regions vertOrder:vertOrder
    )

    fn ExtractLod lodnode lodmesh = (
        local mlod = parser.TLod()
        mlod.mesh = lodmesh

        local fcgrpSet = TFacegroupSet()

        for i = 1 to lodmesh.numfaces do (
            local matid = getFaceMatID lodmesh i
            local mafMatId = MAT_SET.GetMafiaMatId lodnode.mat matid

            local facegroup = fcgrpSet.GetByMatId mafMatId
            append facegroup.faceIds i
        )

        mlod.facegroups = fcgrpSet.facegroups

        mlod
    )
      
    
    ----------------------------------------------------
    ----------------------------------------------------

    fn ExtractBillboard mnode = (
        local mbillboard = parser.TBillboard()
        local gp = custAttributes.get mnode.baseNode MafParams_def baseObject:false
        mbillboard.rotAxis = gp.rotAxis
        mbillboard.rotMode = gp.rotMode
        mbillboard
    )

    fn ExtractBone mnode = (
        mbone = parser.TBone()
        local handle = mnode.baseNode.inode.handle
        mbone.boneId = 
            if BONE_IDS[handle] == undefined then 1
            else BONE_IDS[handle] - 1      --minus one to remove the root bone
            
        mbone.matrix = matrix3 1

        mbone
    )

    fn ExtractTarget mnode mnodeSet = (
        local mtarget = parser.TTarget()
        mtarget.flags = mnode.basenode.flags

        for linkedNode in mnode.basenode.nodes do (
            append mtarget.linkIds (mnodeSet.GetIDByNode linkedNode)
        )

        mtarget
    )

    fn ExtractGlow mnode = (
        local mglows = #()
        local basenode = mnode.basenode
        local count = basenode.matids.count
        for i = 1 to count do (
            local matId = basenode.matids[i]
            local pos = basenode.positions[i]

            local mafMatId = MAT_SET.GetMafiaMatId basenode.mat matId

            if mafMatId != 0 then (
                local mglow = parser.TGlow matId:mafMatId position:pos
                append mglows mglow
            )

        )
        mglows
    )

    fn ExtractMirror mnode unitscale = (
        local baseNode = mnode.basenode
        local mirr = parser.TMirror()
        local gp = custAttributes.get baseNode MafParams_def baseObject:false

        local tr = copy baseNode.mesh
        mirr.mesh = tr

        local scl = scaleMatrix [unitscale,unitscale,unitscale]
        local otrans = baseNode.objectTransform * inverse baseNode.transform * scl

        --apply object offset to mesh
        util.TransformVerts tr otrans

        local size = 10.0 ^ 16   --this value is used in original skin vertex groups, so I'm using it here too
        mirr.dmin = [size, size, size]
        mirr.dmax = [-size, -size, -size]
        for i = 1 to tr.numverts do (
            local vert = getVert tr i
            MinMax mirr.dmin mirr.dmax vert
        )

        local viewbox = mnode.viewbox
        if viewbox == undefined then (
            mirr.matrix = matrix3 1
        )
        else (
            local dmin = in coordsys local viewbox.min
            local dmax = in coordsys local viewbox.max
            local boxsize = util.ToBoxsize dmin dmax
            local mult = (boxsize * unitscale) / 2
            
            local mtr = viewbox.transform * inverse basenode.transform
            local s = scaleMatrix (mtr.scalepart * mult)
            local r = mtr.rotationpart as matrix3
            local t = transMatrix (mtr.translationpart * unitscale)
            mirr.matrix = s * r * t
        )

        mirr.center = (mirr.dmin + mirr.dmax) / 2
        mirr.radius = (distance mirr.dmin mirr.dmax) / 2
        mirr.backColor = gp.mirrorColor
        mirr.drawDistance = gp.mirrorDist

        mirr
    )
    
    fn ExtractCommon mnode mnodeSet mobj unitscale version hasSkin:false hasMorph:false = (
        local mmesh = parser.TMesh()
        
        local skinlods = #()
        local morphlods = #()
                
        local rootbone = mnode.rootbone        
        local lodnodes = #(mnode.baseNode) + mnode.lods        
        
        local mainInstance = GetMainInstance mnode.baseNode        
        local instanceId = mnodeSet.GetIDByNode mainInstance   --0 if not found
        local currentId = mnodeSet.GetIDByNode mnode.baseNode

        if mainInstance == mnode.baseNode or instanceId == 0 or instanceId >= currentId or hasSkin or hasMorph then ( --not instanced 
            mmesh.instanceId = 0
            local prevDist = 0.0       
            for lodnode in lodnodes do (        
                local splmesh = ExtractSplitMesh lodnode rootbone unitscale mnode.bones version
                local mlod = ExtractLod lodnode splmesh.mesh
                local skinlod = if rootbone != undefined then ExtractSkinLod splmesh mnode.bones unitscale
                local morphlod = if splmesh.regions != undefined then ExtractMorphLod splmesh

                
                local gp = custAttributes.get lodnode MafParams_def baseObject:false
                if gp != undefined then (
                    mlod.distance = gp.lodDist
                )
                else (
                    if lodnode == lodnodes[lodnodes.count] then mlod.distance = 0.0
                    else mlod.distance = prevDist + 100.0
                )
                prevDist = mlod.distance
                
                
                
                append mmesh.lods mlod
                append skinlods skinlod
                append morphlods morphlod
            )        
        )
        else (
            mmesh.instanceId = instanceId
        )
        mobj.mesh = mmesh
        
        if hasSkin then (
            mobj.skin = skinlods
            
            mobj.name = mnode.rootBone.name
            mobj.parentId = mnodeSet.GetIDByNode mnode.rootBone.parent
    
            in coordsys parent (
                mobj.offset = mnode.rootBone.pos * unitscale
                mobj.scl = mnode.rootBone.scale
                mobj.rot = mnode.rootBone.rotation
            )
        )
        
        if hasMorph then (
            mobj.morph = morphlods[1]
        )
    )
    
    fn ExtractOccluder mnode unitscale = (
        local tr = copy mnode.basenode.mesh
        
        local scl = scaleMatrix [unitscale,unitscale,unitscale]
        local otrans = mnode.basenode.objectTransform * inverse mnode.basenode.transform * scl

        util.TransformVerts tr otrans        
        
        parser.TOccluder mesh:tr
    )
    
    fn ExtractObjects mnodeSet unitscale version = (
        local mobjects = #()

        for mnode in mnodeSet.mnodes do (
            local mobj = parser.TObject()

            local baseNode = mnode.baseNode

            mobj.cullFlags = 9
            mobj.renderFlags2 = 42

            local gp = custAttributes.get baseNode MafParams_def baseObject:false
            if gp != undefined then (
                mobj.cullFlags = gp.cullFlags
                mobj.renderFlags = gp.renderFlags
                mobj.renderFlags2 = gp.renderFlags2
                mobj.strParams = gp.strParams
            )

            mobj.name = mnode.baseNode.name
            mobj.parentId = mnodeSet.GetIDByNode mnode.baseNode.parent
            
            if version == #mafia then (

                if (baseNode.parent != undefined) and (GetNodeType baseNode.parent == #sector) then (
                    in coordsys world
                    (
                        mobj.offset = mnode.baseNode.pos * unitscale
                        mobj.scl = mnode.baseNode.scale
                        mobj.rot = mnode.baseNode.rotation
                    )
                )
                else (
                    in coordsys parent
                    (
                        mobj.offset = mnode.baseNode.pos * unitscale
                        mobj.scl = mnode.baseNode.scale
                        mobj.rot = mnode.baseNode.rotation
                    )
                )
            
            )
            else (
                in coordsys parent
                (
                    mobj.offset = mnode.baseNode.pos * unitscale
                    mobj.scl = mnode.baseNode.scale
                    mobj.rot = mnode.baseNode.rotation
                )
            )

            case mnode.type of (
                #mesh: (
                    mobj.objectType = 1
                    mobj.visualType = 0
                    
                    ExtractCommon mnode mnodeSet mobj unitscale version hasSkin:false hasMorph:false
                )
                #singlemesh: (
                    mobj.objectType = 1
                    mobj.visualType = 2
                    
                    ExtractCommon mnode mnodeSet mobj unitscale version hasSkin:true hasMorph:false
                )
                #singlemorph: (
                    mobj.objectType = 1
                    mobj.visualType = 3
                    
                    ExtractCommon mnode mnodeSet mobj unitscale version hasSkin:true hasMorph:true
                )
                #morph: (
                    mobj.objectType = 1
                    mobj.visualType = 5
                    
                    ExtractCommon mnode mnodeSet mobj unitscale version hasSkin:false hasMorph:true
                )
                #billboard: (
                    mobj.objectType = 1
                    mobj.visualType = 4
                    ExtractCommon mnode mnodeSet mobj unitscale version hasSkin:false hasMorph:false
                    mobj.billboard = ExtractBillboard mnode
                )
                #sector: (
                    mobj.objectType = 5
                    if gp == undefined then mobj.cullFlags = 125
                    mobj.sector = ExtractSector mnode unitscale version

                    if version == #mafia then (
                        mobj.offset = [0,0,0]
                        mobj.scl = [1,1,1]
                        mobj.rot = [0,0,0,1]
                    )
                )
                #dummy: (
                    mobj.objectType = 6
                    mobj.dummy = ExtractDummy mnode unitscale
                )
                #bone: (
                    mobj.objectType = 10
                    mobj.bone = ExtractBone mnode
                )
                #target: (
                    mobj.objectType = 7
                    mobj.target = ExtractTarget mnode mnodeSet
                )
                #glow: (
                    mobj.objectType = 1
                    mobj.visualType = 6
                    mobj.glow = ExtractGlow mnode
                )
                #mirror: (
                    mobj.objectType = 1
                    mobj.visualType = 8
                    mobj.mirror = ExtractMirror mnode unitscale
                )
                #occluder: (
                    mobj.objectType = 12
                    mobj.occluder = ExtractOccluder mnode unitscale
                )
                default: (
                    mobj.objectType = 6
                    mobj.dummy = ExtractDummy mnode unitscale
                )
            )


            append mobjects mobj
        )
        mobjects
    )
    
    fn MorpherHasData mrph = (
        local numChannels = 
            if WM3_NumberOfChannels == undefined then 100
            else WM3_NumberOfChannels mrph
        
        local found = false
        
        for chanId = 1 to numChannels while not found do (
            local hasData = WM3_MC_HasData mrph chanId
            local isValid = WM3_MC_IsValid mrph chanId
            local isActive = WM3_MC_IsActive mrph chanId
            
            if hasData and isValid and isActive do found = true
        )
        
        found
    )

    fn GetNodeType obj = (
        local gp = custAttributes.get obj MafParams_def baseObject:false
        if (isKindOf obj BoneGeometry) or (obj.boneEnable) then (
            #bone
        )
        else if isKindOf obj Target4ds then (
            #target
        )
        else if isKindOf obj Glow4ds then (
            #glow
        )
        else if matchPattern obj.name pattern:"$volume*" or matchPattern obj.name pattern:"$viewbox*" then (
            #viewbox
        )
        else if isKindOf obj Dummy then (
            #dummy
        )
        else if util.IsGeometry obj then (
            if matchPattern obj.name pattern:"$portal*" then (
                #portal
            )
            else if matchPattern obj.name pattern:"$lod*" then (
                #lod
            )
            else if matchPattern obj.name pattern:"sector*" then (
                #sector
            )            
            else if (gp != undefined) and (stricmp gp.objectType "billboard" == 0) then (
                #billboard
            )
            else if (gp != undefined) and (stricmp gp.objectType "mirror" == 0) then (
                #mirror
            )
            else if (gp != undefined) and (stricmp gp.objectType "occluder" == 0) then (
                #occluder
            )
            else if util.HasMod obj Skin then (
                if (local mrph = util.GetModByClass obj Morpher; mrph != undefined and MorpherHasData mrph) then (
                    #singlemorph
                )
                else #singlemesh
            )
            else if (local mrph = util.GetModByClass obj Morpher; mrph != undefined and MorpherHasData mrph) then (
                #morph
            )
            else (
                #mesh
            )
        )
        else #unsupported
    )

    fn Export4ds file cachedNorm editNorm unitscale allow5ds version = (

        USE_CACHED_NORMALS = cachedNorm
        USE_EDIT_NORMALS = editNorm

        local dur = 0.0

        local f = fopen file "wb"
        if f == undefined then (
            messageBox "Error. Could not write to file."
        )
        else (
            format "exporting: %\n" file

            local st = timestamp()

            gc light:true
            
            --save selection
            local savedSel = getCurrentSelection()
            local savedPanel = getCommandPanelTaskMode()
            
            if savedPanel == #modify then (
                local savedSubSel = subObjectLevel
                local savedMod = modPanel.getCurrentObject()
                
                if savedMod != undefined and classof savedMod == Skin then (
                    local savedBoneId = skinOps.GetSelectedBone savedMod
                )
            )
            -----------------------
            
            clearSelection()
            
            WARN_MORPH = false
            WARN_PORTAL = false
            
            local used_start = (heapsize - heapfree) / 1024.0

            local m4ds = parser.T4ds()
            local mmmm = CollectMaterials()

            m4ds.materials = ExtractMaterials mmmm
            local mnodeSet = CollectNodes()
            m4ds.objects = ExtractObjects mnodeSet unitscale version
            m4ds.allow5ds = allow5ds

            try (
                parser.Write4ds f m4ds version
            )
            catch (
                messageBox (getCurrentException()) icon:#critical
                format "*** % ***\n" (getCurrentException())
                if getCurrentExceptionStackTrace != undefined then (
                    format "%\n" (getCurrentExceptionStackTrace())
                )
                if getCurrentExceptionCallStack != undefined then (
                    format "%\n" (getCurrentExceptionCallStack())
                )
            )
            try (fclose f) catch ()
            
            
            --restore selection

            local dontSelect = false
            setCommandPanelTaskMode savedPanel
            if savedPanel == #modify then (
                if savedMod != undefined then (
                    modPanel.setCurrentObject savedMod
                    if savedSubSel != undefined then (
                        subObjectLevel = savedSubSel
                    )
                    if savedBoneId != undefined then (
                        skinOps.SelectBone savedMod savedBoneId
                    )
                    dontSelect = true
                )
            )            
            if dontSelect == false then (
                if savedSel.count == 0 then (
                    clearSelection()
                )
                else (
                    select savedSel
                )
            )
            --------------------
            

            dur = elapsed_since(st) / 1000.0

            local used_end = (heapsize - heapfree) / 1024.0
            format "memory used ~ % KiB\n" (used_end - used_start)

            gc light:true

            format "Exporting took % seconds\n" dur
            
            if WARN_MORPH then (
                messageBox "Morph channels 1, 11, 21 and so on should be empty." icon:#information
            )
            
            if WARN_PORTAL then (
                messageBox "Some portals have more than 1 face. Extra faces were ignored.\nMore info in the MAXScript Listener (F11)" icon:#warning
            )
        )

        dur
    )
)