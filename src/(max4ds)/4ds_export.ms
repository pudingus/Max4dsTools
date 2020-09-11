rollout MafiaTools_4dsExport "" (   --module

    --imports------------
    local parser = ::MafiaTools_4dsParser
    local util = ::MafiaTools_Util
    ---------------------

    local useEditNormals
    local useCachedNormals


    
    local boneNodes = #()
    local boneHandleIds = #()
    local parentBoneIds = #()
    local nodeTypes = #()
    local rootBone = #()
    local matset

    struct TNode (
        baseNode,
        type,
        lods = #(),
        portals = #(),
        rootBone
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
                mnode_ids[handle]
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
        matset = TMatSet() 
        
        for mat in sceneMaterials do (
            if isKindOf mat MultiMaterial then (
                for submat in mat.materialList where submat != undefined do (

                    if util.containsItem #(Standard, Physical_Material, Mat4ds) (classOf subMat) then (
                        matset.AddToMafiaMaterials submat
                    )
                )
            )
            else (
                if util.containsItem #(Standard, Physical_Material, Mat4ds) (classOf mat) then (
                    matset.AddToMafiaMaterials mat
                )
            )
        )
        matset.mafia_materials
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

                mmat.flags = flags

                mmat.ambient = mat.ambient
                mmat.diffuse = mat.diffuse
                mmat.emission = mat.emission

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
        for obj in objects do (
            local type = nodeTypes[obj.inode.handle]
            if type == undefined then (
                type = util.GetNodeType obj

                if type == #singlemesh then (
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
                        rootBone[obj.inode.handle] = obj.parent
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
                    )
                )
                #lod: (
                    if obj.parent != undefined then (
                        local parentMnode = mnodeSet.GetByNode obj.parent
                        append parentMnode.lods obj
                    )
                )
                #singlemesh: (
                    local id = mnodeSet.GetIdByNode rootBone[obj.inode.handle]
                    print (id as string)

                    mnodeSet.mnodes[id].baseNode = obj
                    mnodeSet.AddPointer obj id
                )
                #rootbone: (
                    local mnode = mnodeSet.GetByNode obj
                    if mnode == undefined then (
                        mnode = TNode()
                        mnode.rootBone = obj
                        mnode.type = #singlemesh
                        mnodeSet.Add obj mnode
                    )
                )
                default: (
                    local mnode = TNode()
                    mnode.baseNode = obj
                    mnode.type = nodeType
                    mnodeSet.Add obj mnode
                )
            )

            --format "obj:%  type:% \n" obj.name nodeType

            if nodeType == #bone or nodeType == #rootBone then (
                append boneNodes obj
                local handle = obj.inode.handle
                boneHandleIds[handle] = boneNodes.count

                local parentId
                if obj.parent != undefined then (
                    local parentHandle = obj.parent.inode.handle
                    parentId = boneHandleIds[parentHandle]
                )
                if parentId == undefined then parentId = 0

                append parentBoneIds parentId
            )
        )

        for mnode in mnodeSet.mnodes do (
            qsort mnode.lods CompareNodesByName
            qsort mnode.portals CompareNodesByName
        )

        mnodeSet
    )

    fn ExtractSector mnode unitscl = (
        local sector = parser.TSector()
        sector.mesh = snapshotAsMesh mnode.baseNode
        sector.dmin = mnode.baseNode.min * unitscl
        sector.dmax = mnode.baseNode.max * unitscl

        for i = 1 to sector.mesh.numverts do (
            local vert = getVert sector.mesh i
            setVert sector.mesh i (vert * unitscl)
        )

        for portalNode in mnode.portals do (
            local portal = parser.TPortal()
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
                append portal.verts (vert * unitscl)
            )
            append sector.portals portal
        )

        sector
    )

    fn ExtractDummy mnode unitscl = (
        local mdummy = parser.TDummy()
        mdummy.dmin = in coordsys local mnode.baseNode.min * unitscl
        mdummy.dmax = in coordsys local mnode.baseNode.max * unitscl
        mdummy
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



    fn CompareVertBones v1 v2 = (
        if v1.weight > v2.weight then -1
        else if v2.weight > v1.weight then 1
        else 0
    )

    fn ExtractWeights mnode = (

        local lodnodes = copy mnode.lods #noMap
        insertItem mnode.baseNode lodnodes 1

        local lodWeights = #() 

        for lodnode in lodnodes do (
            local bskin = util.GetModByClass lodnode Skin

            max modify mode
            modPanel.setCurrentObject bskin            

            local xskin = skin_makeCache bskin
            
            local skinBoneIds = #()            
            local skinBones = util.GetBoneNodes bskin            
            for i = 1 to skinBones.count do (
                local globBoneId = findItem boneNodes skinBones[i]
                skinBoneIds[i] = globBoneId
            )

            local weights = #()
            local numverts = skinOps.GetNumberVertices bskin
            for i = 1 to numverts do (

                local count = skinOps.GetVertexWeightCount bskin i

                local weight = 0.0
                local boneid = 9999
                if count > 0 then (
                    if count == 1 then (
                        weight = skinOps.GetVertexWeight bskin i 1
                        local id = skin_getVertexWeightBoneId xskin i 1
                        boneid = skinBoneIds[id] - 1
                    )
                    else (
                        local vertBones = #()

                        for n = 1 to count do (
                            local w = skinOps.GetVertexWeight bskin i n
                            local id = skin_getVertexWeightBoneId xskin i n
                            local globId = skinBoneIds[id]
                            local vb = VertBone boneid:globId weight:w
                            append vertBones vb
                        )
                        qsort vertBones CompareVertBones

                        local weight1 = vertBones[1].weight
                        local weight2 = vertBones[2].weight
                        local boneid1 = vertBones[1].boneid
                        local boneid2 = vertBones[2].boneid

                        local sum = weight1 + weight2
                        weight = weight1 / sum
                        boneid = boneid1 - 1

                        local boneNode1 = boneNodes[boneid1]
                        local boneNode2 = boneNodes[boneid2]
                        if util.isDescendantOf boneNode2 boneNode1 then (
                            weight = weight2 / sum
                            boneid = boneid2 - 1
                        )
                    )
                )

                if boneid == 0 then boneid = 9999

                wv = WeightedVertex()
                wv.boneid = boneid
                wv.weight = weight
                wv.vertid = i

                append weights wv
            )

            append lodWeights weights
        )

        lodWeights
    )

    fn ExtractSkin mnode lodWeights unitscl = (
        local lodnodes = copy mnode.lods #noMap
        insertItem mnode.baseNode lodnodes 1

        local mskins = #()

        for l = 1 to lodnodes.count do (
            local lodnode = lodnodes[l]
            local weights = lodWeights[l]

            local mskin = parser.TSkin()
            mskin.numW0Verts = 0
            local range = 0.2
            mskin.dmin = [-range, -range, -range]
            mskin.dmax = [range, range, range]

            local groups = #()

            for i = 2 to boneNodes.count do (
                local boneNode = boneNodes[i]
                local grp = parser.TSkinVertexGroup()
                grp.numW1Verts = 0

                local range = 0.2
                grp.dmin = [-range, -range, -range]
                grp.dmax = [range, range, range]
                grp.boneid = 0

                local boneTF = boneNode.transform
                local t = transMatrix (boneTF.translationpart * unitscl)
                local s = scaleMatrix boneTF.scalepart
                local r = boneTF.rotationpart as matrix3
                local boneTFs = s * r * t


                local rootTF = mnode.rootbone.transform
                local t = transMatrix (rootTF.translationpart * unitscl)
                local s = scaleMatrix rootTF.scalepart
                local r = rootTF.rotationpart as matrix3
                local rootTFs = s * r * t

                local mm = boneTFs * (inverse rootTFs)

                --local mm = boneNode.transform * (inverse mnode.rootbone.transform)
                grp.matrix = inverse mm

                append groups grp
            )

            for weight in weights do (
                if weight.boneid == 9999 then (   --this is at the end
                    mskin.numW0Verts += 1
                )
                else (
                    local id = weight.boneid
                    local grp = groups[id]

                    if weight.weight == 1.0 then grp.numW1Verts += 1
                    else (
                        append grp.weights weight.weight
                    )
                )
            )

            for i = 1 to groups.count do (
                local grp = groups[i]

                if (grp.numW1Verts > 0) or (grp.weights.count > 0) then (
                    grp.boneid = parentBoneIds[i+1]-1
                )
            )

            mskin.vgroups = groups

            append mskins mskin
        )
        mskins
    )

    fn close_enough_p3 v1 v2 prec  = (
        (close_enough v1.x v2.x prec) and (close_enough v1.y v2.y prec) and (close_enough v1.z v2.z prec)
    )

    /*
    splitVerts

    vertId  idOfDuplicatedVertex
    1  =  #(1087, 512, 121, ...)
    2
    3
    4

    */

    fn SplitVertices mesh faceVertNormals weights = (
        local numverts = mesh.numverts
        local normals = #()   -- min. count = count of vertices, normals for duplicated verts are appended to the end
        local uvs = #()     -- =||=

        normals[numverts] = undefined
        uvs[numverts] = undefined

        local mapSupport = meshop.getMapSupport mesh 1

        local splitVerts = #()
        local extraVerts = #()
        local fixFaces = #()

        for i = 1 to mesh.numfaces do (
            local vertIds = getFace mesh i
            local rnormals = faceVertNormals[i]

            local newVertIds = copy vertIds

            local tface
            if mapSupport then (
                tface = getTVFace mesh i
            )

            for v = 1 to 3 do (
                local vertId = vertIds[v] as integer
                local normal = rnormals[v]
                local uv = [0,0,0]
                if tface != undefined then (
                    uv = getTVert mesh (tface[v] as integer)
                )

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

                        if weights != undefined then (
                            local wv = WeightedVertex()
                            wv.boneid = weights[vertId].boneid
                            wv.weight = weights[vertId].weight
                            wv.vertId = newVertId

                            append weights wv
                        )

                        if splitVerts[vertid] == undefined then splitVerts[vertid] = #()
                        append splitVerts[vertid] newVertId

                        append normals normal
                        append uvs uv

                        newVertIds[v] = newVertId
                    )
                    else if foundId != vertId then (
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

        #(mesh, normals, weights, uvs)
    )

    fn ExtractMesh mnode mnodeSet &lodWeights unitscl = (
        local mmesh = parser.TMesh()

        local instances
        local count = InstanceMgr.GetInstances mnode.baseNode &instances
        local masterInstance = instances[count]

        if masterInstance != mnode.baseNode then (  --search for instance id
            mmesh.instanceId = mnodeSet.GetIDByNode masterInstance
        )
        else mmesh.instanceId = 0

        if mmesh.instanceId == 0 then ( --is master instance
            local lodnodes = copy mnode.lods #noMap
            insertItem mnode.baseNode lodnodes 1

            local prevDist = 0.0

            for l = 1 to lodnodes.count do (
                local lodnode = lodnodes[l]
                local weights
                if lodweights != undefined then weights = lodWeights[l]

                local mlod = parser.TLod()

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

                local normMod

                if useEditNormals then normMod = util.GetModByClass lodnode Edit_Normals

                local faceVertNormals = #()

                if normMod != undefined then (
                    max modify mode
                    modpanel.setcurrentobject normMod node:lodnode

                    for i = 1 to lodmesh.numfaces do (
                        local rnormals = #()
                        for v = 1 to 3 do (
                            local normId = normMod.getnormalid i v
                            rnormals[v] = normMod.getnormal normId
                        )
                        append faceVertNormals rnormals
                    )
                )
                else (
                    local cmod
                    if useCachedNormals then cmod = util.GetModByClass lodnode CachedNormals

                    if cmod != undefined then (
                        for i = 1 to lodmesh.numfaces do (
                            local nface = cmod.normalFaces[i]
                            local rnormals = #()
                            for v = 1 to 3 do (
                                local normalId = nface[v]
                                rnormals[v] = cmod.normals[normalId]
                            )
                            append faceVertNormals rnormals
                        )
                    )
                    else (
                        for i = 1 to lodmesh.numfaces do (
                            local rnormals = meshop.getFaceRNormals lodmesh i
                            append faceVertNormals rnormals
                        )
                    )
                )





                local normals = #()
                local uvs = #()
                if split then (
                    local spl = SplitVertices lodmesh faceVertNormals weights
                    lodmesh = spl[1]
                    normals = spl[2]
                    weights = spl[3]
                    uvs = spl[4]
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

                    uvs[lodmesh.numverts] = undefined
                    if meshop.getMapSupport lodmesh 1 then (
                        for i = 1 to lodmesh.numfaces do (
                            local tface = getTVFace lodmesh i
                            local face = getFace lodmesh i

                            for v = 1 to 3 do (
                                uvs[face[v]] = gettvert lodmesh tface[v]
                            )
                        )
                    )
                )

                -----apply per vertex uvs to mesh map channel
                --format "uvs count % \n" uvs.count
                setNumTVerts lodmesh uvs.count
                for i = 1 to uvs.count do (
                    local uv = uvs[i]
                    if uv == undefined then uv = [0,0,0]

                    setTVert lodmesh i uv
                )
                ------------------------------------

                ---sort weighted vertices
                if weights != undefined then (
                    qsort weights CompareWeights

                    local vertOrder = #()
                    for wv in weights do (
                        append vertOrder wv.vertId
                    )

                    mlod.vertOrder = vertOrder
                )
                -------------------


                ---apply unit scale and object offset transform
                local scl = scaleMatrix [unitscl,unitscl,unitscl]
                local otrans = lodnode.objectTransform * inverse lodnode.transform * scl

                if mnode.rootBone != undefined then (
                    local offsetTrans = lodnode.objectTransform * inverse lodnode.transform
                    otrans = offsetTrans * (lodnode.transform * inverse mnode.rootbone.transform) * scl
                )
                for vertId = 1 to lodmesh.numverts do (
                    local vert = getVert lodmesh vertId
                    setVert lodmesh vertId (vert * otrans)

                    --rotate normals
                    normals[vertId] = normalize (normals[vertId] * otrans.rotationpart)
                )


                ----------------------


                mlod.mesh = lodmesh
                mlod.normals = normals

                local fcgrpSet = TFacegroupSet()

                for i = 1 to lodmesh.numfaces do (
                    local matid = getFaceMatID lodmesh i
                    local mafMatId = matset.GetMafiaMatId lodnode.mat matid

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
        local mbillboard = parser.TBillboard()
        local gp = custAttributes.get mnode.baseNode MafParams_def baseObject:false
        mbillboard.rotAxis = gp.rotAxis - 1
        mbillboard.rotMode = gp.rotMode - 1
        mbillboard
    )

    fn ExtractBone mnode = (
        mbone = parser.TBone()
        --mbone.boneId = mnode.baseNode.boneId
        local handle = mnode.baseNode.inode.handle
        mbone.boneId = boneHandleIds[handle] - 2

        mbone.matrix = matrix3 1

        mbone
    )

    fn ExtractTarget mnode mnodeSet = (
        local mtarget = parser.TTarget()

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

            local mafMatId = matset.GetMafiaMatId basenode.mat matId

            if mafMatId != 0 then (
                local mglow = parser.TGlow matId:mafMatId position:pos
                append mglows mglow
            )

        )
        mglows
    )

    fn ExtractObjects mnodeSet unitscl = (
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

            if (baseNode.parent != undefined) and (util.GetNodeType baseNode.parent == #sector) then (
                in coordsys world
                (
                    mobj.offset = mnode.baseNode.pos * unitscl
                    mobj.scl = mnode.baseNode.scale
                    mobj.rot = mnode.baseNode.rotation
                )
            )
            else (
                in coordsys parent
                (
                    mobj.offset = mnode.baseNode.pos * unitscl
                    mobj.scl = mnode.baseNode.scale
                    mobj.rot = mnode.baseNode.rotation
                )
            )

            case mnode.type of (
                #mesh: (
                    mobj.objectType = 1
                    mobj.visualType = 0
                    mobj.definitions[1] = ExtractMesh mnode mnodeSet undefined unitscl
                )
                #singlemesh: (
                    mobj.objectType = 1
                    mobj.visualType = 2
                    local lodWeights = ExtractWeights mnode
                    local mmesh = ExtractMesh mnode mnodeSet &lodWeights unitscl
                    local mskins = ExtractSkin mnode lodWeights unitscl

                    mobj.definitions[1] = mmesh
                    mobj.definitions[2] = mskins

                    mobj.name = mnode.rootBone.name

                    mobj.parentId = mnodeSet.GetIDByNode mnode.rootBone.parent

                    in coordsys parent
                    (
                        mobj.offset = mnode.rootBone.pos * unitscl
                        mobj.scl = mnode.rootBone.scale
                        mobj.rot = mnode.rootBone.rotation
                    )
                )
                #billboard: (
                    mobj.objectType = 1
                    mobj.visualType = 4
                    mobj.definitions[1] = ExtractMesh mnode mnodeSet undefined unitscl
                    mobj.definitions[2] = ExtractBillboard mnode
                )
                #sector: (
                    mobj.objectType = 5
                    mobj.cullFlags = 125
                    mobj.definitions[1] = ExtractSector mnode unitscl

                    mobj.offset = [0,0,0]
                    mobj.scl = [1,1,1]
                    mobj.rot = [0,0,0,1]
                )
                #dummy: (
                    mobj.objectType = 6
                    mobj.definitions[1] = ExtractDummy mnode unitscl
                )
                #bone: (
                    mobj.objectType = 10
                    mobj.definitions[1] = ExtractBone mnode
                )
                #target: (
                    mobj.objectType = 7
                    mobj.definitions[1] = ExtractTarget mnode mnodeSet
                )
                #glow: (
                    mobj.objectType = 1
                    mobj.visualType = 6
                    mobj.definitions[1] = ExtractGlow mnode
                )
                default: (
                    mobj.objectType = 6
                    mobj.definitions[1] = ExtractDummy mnode unitscl
                )
            )


            append mobjects mobj
        )
        mobjects
    )

    fn Export4ds file cachedNorm editNorm unitscl  = (
        
        useCachedNormals = cachedNorm
        useEditNormals = editNorm
        
        local dur = 0.0
        
        local f = fopen file "wb"
        if f == undefined then (
            messageBox "Error. Could not write to file."   
        )
        else (
            boneNodes = #()
            boneHandleIds = #()
            parentBoneIds = #()
            nodeTypes = #()
            rootBone = #()
            
            format "exporting: %\n" file
    
            local st = timestamp()
    
            gc light:true
    
            local used_start = (heapsize - heapfree) / 1024.0
    
            local m4ds = parser.T4ds()
            local mmmm = CollectMaterials()
            
            m4ds.materials = ExtractMaterials mmmm
            local mnodeSet = CollectNodes()
            m4ds.objects = ExtractObjects mnodeSet unitscl
    
            
            parser.Write4ds f m4ds
            fclose f
    
            dur = elapsed_since(st) / 1000.0
    
            local used_end = (heapsize - heapfree) / 1024.0
            format "memory used ~ % KiB\n" (used_end - used_start)
    
            gc light:true
    
            format "Exporting took % seconds\n" dur
            --messageBox ("Exporting took " + (dur as string) + " seconds")
        )      


        dur
    )
)