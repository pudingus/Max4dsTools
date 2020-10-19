
rollout MafiaTools_4dsImport "" (   --module

    --imports--
    local Layers = ::MafiaTools_Layers    
    -----------

    fn GetMafParams nnode = (
        custAttributes.add nnode MafParams_def baseObject:false
        custAttributes.get nnode MafParams_def baseObject:false
    )


    --returns array of nodes
    fn CreateMesh mmesh name unitscale materials = (
        local nodes = #()

        if mmesh.lods.count == 0 then (
            nodes[1] = Editable_mesh()
        )
        else (
            local lodId = 0
            for mlod in mmesh.lods do (
                local msh = mlod.mesh

                for i = 1 to msh.numverts do (
                    local vert = getVert msh i
                    setVert msh i (vert * unitscale)
                )

                local lodNode = mesh mesh:msh
                lodNode.wirecolor = color 0 0 0


                local usedMats = #{}

                for fcgrp in mlod.facegroups do (
                    if fcgrp.matId != 0 then (
                        usedMats[fcgrp.matId] = true
                    )
                )

                usedMats = usedMats as array

                local indices = #()

                if usedMats.count == 1 then (
                    local matId = usedMats[1]
                    if matId != 0 then (
                        indices[matId] = 1
                        lodnode.material = materials[matId]
                    )
                )
                else (
                    local multimat = multimaterial numsubs:(usedMats.count + 1)
                    multimat.name = name
                    multimat[multimat.numsubs] = undefined

                    local i = 1
                    for matId in usedMats do (
                        multimat[i] = materials[matId]
                        i += 1
                    )

                    local i = 1
                    for matId in usedMats do (
                        indices[matId] = i
                        i += 1
                    )


                    lodnode.material = multimat
                )

                for fcgrp in mlod.facegroups do (
                    local matId
                    if fcgrp.matid == 0 then (
                        matId = multimat.numsubs
                    )
                    else (
                        matId = indices[fcgrp.matId]
                    )

                    for faceId in fcgrp.faceIds do (
                        setFaceMatID lodnode faceId matId
                    )
                )


                if lodId > 0 then (
                    lodNode.name = "$lod" + (lodId as string) + "__" + name
                    lodNode.parent = nodes[1]
                    hide lodNode
                )

                if mmesh.lods.count > 1 then Layers.AddTo lodNode ("Lod"+(lodId as string))

                local gp = GetMafParams lodNode

                gp.objectType = "Lod"
                gp.lodDist = mlod.distance

                append nodes lodNode

                local cmod = CachedNormals()
                cmod.normals = mlod.normals

                for i = 1 to lodnode.numfaces do (
                    append cmod.normalFaces (getFace lodnode i)
                )

                addModifier lodnode cmod

                lodId += 1
            )
        )
        nodes
    )


    fn CreateMorph mmorph mmesh nnode unitscale = (
        local baseMesh = mmesh.lods[1].mesh
        local meshes = #()

        for layer in mmorph.layers do (
            local sectionMeshes = #()

            for i = 1 to mmorph.numTargets do (
                sectionMeshes[i] = copy baseMesh
            )

            for vert in layer.vertices do (
                local vertId = vert.index

                for j = 1 to vert.points.count do (
                    local point = vert.points[j]
                    local pos = point.pos * unitscale
                    setVert sectionMeshes[j] vertId pos
                )
            )
            append meshes sectionMeshes
        )

        local tmod = Morpher()
        addModifier nnode tmod
        local maxver = (maxversion())[1]
        --if maxver < 22000 then (
            max modify mode
            select nnode
        --)

        local letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

        local sectionId = 1
        local marker = 1

        for sectMesh in meshes do (
            local layerLetter = letters[sectionId]
            WM3_CreateMarker tmod marker ("layer " + layerLetter)

            local targetId = 1

            for targetMesh in sectMesh do (
                local tnode = mesh mesh:targetMesh
                local finalId = (marker + targetId - 1)

                WM3_MC_BuildFromNode tmod finalId tnode
                WM3_MC_SetName tmod finalId (layerLetter + " " + (targetId as string))

                delete tnode

                targetId += 1
            )
            marker = (sectionId * 10 + 1)
            sectionId += 1
        )

        WM3_SetCurrentMarker tmod 1
    )

    fn CreateBillboard mbillboard nnode = (
        local gp = GetMafParams nnode

        gp.rotAxis = mbillboard.rotAxis
        gp.rotMode = mbillboard.rotMode
    )

    fn CreateGlow mglows mobj unitscale materials = (
        local nnode = Glow4ds()
        nnode.wirecolor = color 248 128 0
        nnode.boxmode = true
        nnode.renderable = false

        nnode.viewportSize = 0.1 * unitscale

        local usedMats = #{}

        for mglow in mglows do (
            usedMats[mglow.matId] = true
        )

        local multimat = multimaterial numsubs:(usedMats.numberSet + 1)
        multimat.name = mobj.name
        multimat[multimat.numsubs] = undefined
        local index = 1
        local indices = #()

        for matId in usedMats do (
            multimat[index] = materials[matId]
            indices[matId] = index
            index += 1
        )

        nnode.material = multimat

        for mglow in mglows do (
            append nnode.positions mglow.position
            append nnode.matIds indices[mglow.matId]
        )

        nnode
    )

    fn CreateMirror mirr mobj unitscale = (
        local msh = mirr.mesh

        for i = 1 to msh.numverts do (
            local vert = getVert msh i
            setVert msh i (vert * unitscale)
        )

        local nnode = mesh mesh:msh
        nnode.wirecolor = white
        Layers.AddTo nnode "Mirrors"
        
        local gp = GetMafParams nnode
        gp.mirrorUnk1 = mirr.unknown[1]
        gp.mirrorUnk2 = mirr.unknown[2]
        gp.mirrorUnk3 = mirr.unknown[3]
        gp.mirrorUnk4 = mirr.unknown[4]
        gp.mirrorColor = mirr.backColor
        gp.mirrorDist = mirr.drawDistance
        
        local volume = dummy boxsize:[2, 2, 2]
        volume.name = "$volume"
        volume.transform = mirr.matrix
        volume.parent = nnode
        
        local util = ::MafiaTools_Util
        util.PrintMatrix mirr.matrix

        nnode
    )

    fn CreateDummy mdummy mobj unitscale = (
        local dmin = mdummy.dmin * unitscale
        local dmax = mdummy.dmax * unitscale
        local nnode = dummy()
        nnode.boxsize = [(abs (dmin.x-dmax.x)), (abs (dmin.y-dmax.y)), (abs (dmin.z-dmax.z))]

        hide nnode

        nnode
    )

    --returns array of nodes
    fn CreateSector msector mobj unitscale = (
        local nodes = #()

        local msh = msector.mesh

        for i = 1 to msh.numverts do (
            local vert = getVert msh i
            setVert msh i (vert * unitscale)
        )

        nodes[1] = mesh mesh:msh
        nodes[1].wirecolor = (color 255 199 0)

        local portalId = 0
        for mportal in msector.portals do (
            local numverts = mportal.verts.count
            local portalNode = mesh numverts:numVerts
            portalNode.name = "$portal" + (formattedPrint portalId format:".2u") + "__" + mobj.name

            for v = 1 to numVerts do (
                local vert = mportal.verts[v]
                setVert portalNode v (vert * unitscale)
            )
            local face = for v = 1 to numVerts collect v
            portalNode = convertToPoly portalNode
            polyop.createPolygon portalNode face

            portalNode.wirecolor = (color 255 0 199)
            portalNode.parent = nodes[1]

            local gp = GetMafParams portalNode

            gp.objectType = "Portal"
            gp.nearRange = mportal.nearRange
            gp.farRange = mportal.farRange

            Layers.AddTo portalNode "Portals"

            append nodes portalNode

            portalId += 1
        )
        nodes
    )

    -- returns Node
    fn CreateTarget mtarget mobj unitscale = (
        local nnode = Target4ds()
        nnode.wirecolor = color 28 122 210
        nnode.viewportSize = 0.1 * unitscale
        hide nnode

        nnode
    )

    fn CreateBone = (
        local nnode = bonesys.createBone [0,0,0] [0,0,0] [0,0,0]
        nnode.width = 0.0
        nnode.height = 0.0
        nnode.setBoneEnable false sliderTime
        nnode.showlinks = true
        nnode.sidefins = false
        nnode.frontfin = false
        nnode.backfin = false

        Layers.AddTo nnode "Bones"

        nnode
    )

    fn CreateMaterials mmats filename = (
        local materials = #()
        
        for m = 1 to mmats.count do (
            local mmat = mmats[m]
            local mat = Mat4ds()
            mat.name = "4dsMat"+(m as string)

            local flags = mmat.flags

            --Diffuse Map
            mat.diffuseMapEnable = (bit.get flags 19)

            mat.colored = (bit.get flags 28)
            mat.mipMapping = (bit.get flags 24)
            mat.twoSided = (bit.get flags 29)
            mat.animatedDiffuse = (bit.get flags 27)
            mat.animatedAlpha = (bit.get flags 26)

            --Environment Map
            mat.envMapEnable = (bit.get flags 20)

            mat.envOverlay = (bit.get flags 9)
            mat.envMultiply = (bit.get flags 10)
            mat.envAdditive = (bit.get flags 11)
            mat.YProj = (bit.get flags 13)
            mat.YDetail = (bit.get flags 14)
            mat.ZDetail = (bit.get flags 15)

            --Additional Effect
            mat.addEffect = (bit.get flags 16)
            mat.alphaMapEnable = (bit.get flags 31)
            mat.colorKey = (bit.get flags 30)
            mat.additiveMixing = (bit.get flags 32)

            mat.ambient = mmat.ambient
            mat.diffuse = mmat.diffuse
            mat.emission = mmat.emission
            mat.opacity = mmat.opacity*100


            if mat.envMapEnable then (
                mat.envMapAmount = mmat.envMapAmount*100
                if mmat.envMapName != undefined then (
                    mat.envMap = bitmaptex filename:mmat.envMapName name:mmat.envMapName
                )
            )

            if mmat.diffMapName != undefined then (
                mat.diffuseMap = bitmaptex filename:mmat.diffMapName name:mmat.diffMapName
                showTextureMap mat on

                if mat.alphaMapEnable and (mmat.alphaMapName != undefined) then (
                    mat.alphaMap = bitmaptex filename:mmat.alphaMapName name:mmat.alphaMapName
                )
            )

            if mat.animatedDiffuse then (
                mat.animFrames = mmat.animFrames
                mat.animPeriod = mmat.animPeriod
            )

            append materials mat
        )
        
        materials
    )

    struct TWorldBuffer (
        skinBuffer = #(),   --array of TObjPair
        targetBuffer = #(),  --array of TObjPair
        boneNodes = #(),   --array of nodes sorted in boneid order
        normalNodes = #(),    --array of nodes for modifier normals
        mafiaNodes = #()
    )

    struct TObjPair (
        mdefs,   --mafia object definitions
        nodes
    )


    fn CreateSkins skinBuffer boneNodes  = (
        local maxver = (maxversion())[1]
        for pair in skinBuffer do (
            local mskins = pair.mdefs
            local nodes = pair.nodes

            for q = 1 to nodes.count do (
                local nnode = nodes[q]
                local mskin = mskins[q]

                local oskin = Skin()
                oskin.showNoEnvelopes = true
                addModifier nnode oskin
                if maxver < 22000 then (
                    max modify mode
                    select nnode
                )
 

                for boneId = 1 to boneNodes.count do (
                    skinOps.AddBone oskin boneNodes[boneId] 0
                )

                --clear weights
                for vertId = 1 to nnode.numverts do (
                    for boneId = 1 to boneNodes.count do (
                        skinOps.ReplaceVertexWeights oskin vertId boneId 0.0
                    )
                )
                ---------
                                
                local xskin = skin_makeCache oskin             

                local vertId = 1

                for i = 1 to mskin.vgroups.count do (
                    local grp = mskin.vgroups[i]
                    local boneid1 = i+1
                    local boneid2 = grp.boneId+1

                    for j = 1 to grp.numW1Verts do (
                        local weight = 1.0
                        skin_setVertexWeight xskin vertId boneid1 weight

                        vertId += 1
                    )

                    for weight in grp.weights do (
                        skin_setVertexWeight xskin vertId boneid1 weight
                        skin_setVertexWeight xskin vertId boneid2 (1.0 - weight)

                        vertId += 1
                    )
                )

                (
                    local weight = 1.0
                    local boneId = 1
                        
                    for i = 1 to mskin.numW0Verts do (                        
                        skin_setVertexWeight xskin vertId boneId weight
                        vertId += 1
                    )
                )
            )
        )
        for boneNode in boneNodes do (
            boneNode.setBoneEnable true sliderTime
        )
    )

    fn CreateObjects mobjects filename unitscale materials = (
        local buffer = TWorldBuffer()

        for i = 1 to mobjects.count do (
            local mobj = mobjects[i]
            local nnode
            local baseMesh

            case mobj.objectType of (
                1: case mobj.visualType of (
                    0: (  --standardmesh
                        local mmesh = mobj.definitions[1]

                        local nodes = #()
                        if mmesh.instanceId == 0 then (
                            nodes = CreateMesh mmesh mobj.name unitscale materials
                        )
                        else (
                            nodes[1] = instance buffer.mafiaNodes[mmesh.instanceId]
                        )

                        nnode = nodes[1]
                    )
                    2: (  --singlemesh
                        local mmesh = mobj.definitions[1]
                        local mskins = mobj.definitions[2]
                        local nodes = CreateMesh mmesh filename unitscale materials

                        baseMesh = nodes[1]
                        baseMesh.name = "_" + filename

                        append buffer.skinBuffer (TObjPair mdefs:mskins nodes:nodes)


                        nnode = CreateBone()
                        buffer.boneNodes[1] = nnode

                        --baseMesh.parent = nnode
                    )
                    3: (  --singlemorph
                        local mmesh = mobj.definitions[1]
                        local mskins = mobj.definitions[2]
                        local mmorph = mobj.definitions[3]
                        local nodes = CreateMesh mmesh filename unitscale materials
                        CreateMorph mmorph mmesh nodes[1] unitscale

                        baseMesh = nodes[1]
                        baseMesh.name = "_" + filename

                        append buffer.skinBuffer (TObjPair mdefs:mskins nodes:nodes)


                        nnode = CreateBone()
                        buffer.boneNodes[1] = nnode

                        --baseMesh.parent = nnode
                    )
                    4: ( --billboard
                        local mmesh = mobj.definitions[1]
                        local mbillboard = mobj.definitions[2]
                        local nodes = CreateMesh mmesh mobj.name unitscale materials
                        nnode = nodes[1]
                        CreateBillboard mbillboard nnode

                        Layers.AddTo nnode "Billboards"


                        --append buffer.normalNodes
                    )
                    5: ( --morph
                        local mmesh = mobj.definitions[1]
                        local mmorph = mobj.definitions[2]
                        local nodes = CreateMesh mmesh mobj.name unitscale materials
                        nnode = nodes[1]
                        CreateMorph mmorph mmesh nnode unitscale
                    )
                    6: ( --glow
                        local mglows = mobj.definitions[1]
                        nnode = CreateGlow mglows mobj unitscale materials
                        Layers.AddTo nnode "Glows"
                    )
                    8: (  --mirror
                        local mmirror = mobj.definitions[1]
                        nnode = CreateMirror mmirror mobj unitscale
                    )
                )
                5: ( --sector
                    local msector = mobj.definitions[1]
                    nnode = (CreateSector msector mobj unitscale)[1]
                    Layers.AddTo nnode "Sectors"
                )
                6: ( --dummy
                    local mdummy = mobj.definitions[1]
                    nnode = CreateDummy mdummy mobj unitscale
                    Layers.AddTo nnode "Dummies"
                )
                7: ( --target
                    local mtarget = mobj.definitions[1]
                    nnode = CreateTarget mtarget mobj unitscale

                    append buffer.targetBuffer (TObjPair mdefs:mtarget nodes:nnode)
                )
                10: ( --bone
                    local mbone = mobj.definitions[1]
                    nnode = CreateBone()

                    buffer.boneNodes[mbone.boneId+2] = nnode

                    --format "% | objId: % | boneid: %\n" mobj.name i mbone.boneid
                )
            )

            if mobj.cullFlags == 16 then (
                Layers.AddTo nnode "Disabled"
            )




            ---basebone


            local s = scaleMatrix mobj.scl
            local r = mobj.rot as matrix3
            local t = transMatrix (mobj.offset * unitscale)

            if mobj.parentId > 0 then (
                nnode.parent = buffer.mafiaNodes[mobj.parentId]
                nnode.transform = s * r * t * nnode.parent.transform
            )
            else (
                nnode.transform = s * r * t
            )


            if baseMesh != undefined then (
                baseMesh.parent = nnode
                baseMesh.transform = nnode.transform
            )

            nnode.name = mobj.name
            append buffer.mafiaNodes nnode
            --basebone


            ---basemesh
            local gp
            if baseMesh != undefined then gp = GetMafParams baseMesh
            else gp = GetMafParams nnode


            --cant set objectType in CreateMesh for singlemeshes, singlemorphs...
            gp.objectType = case mobj.objectType of (
                1: case mobj.visualType of (
                    6: "Dummy"
                    4: "Billboard"
                    8: "Mirror"
                    default: "Mesh"
                )
                5: "Sector"
                7: "Target"
                default: "Dummy"
            )

            gp.renderFlags = mobj.renderFlags
            gp.renderFlags2 = mobj.renderFlags2
            gp.cullFlags = mobj.cullFlags
            if mobj.strParams != undefined then gp.strParams = mobj.strParams

        )

        buffer
    )

    fn LinkTargets targetBuffer mafiaNodes = (
        for pair in targetBuffer do (
            local mtarget = pair.mdefs
            local targetNode = pair.nodes

            for linkId in mtarget.linkIds do (
                append targetNode.nodes mafiaNodes[linkId]
            )
        )
    )

    fn Import4ds file unitscale = (
        local mode = getCommandPanelTaskMode()
        local savedMode
        if mode == #modify then (
            savedMode = mode
            setCommandPanelTaskMode #create
        )

        filename = getFilenameFile file

        format "importing: %\n" file
        
        local st = timestamp()

        gc light:true

        local used_start = (heapsize - heapfree) / 1024.0

        local f = fopen file "rb"
        local parser = ::MafiaTools_4dsParser
        local m4ds = parser.Read4ds f
        fclose f

        if m4ds == undefined then (
            messageBox "This file cannot be imported. Unknown version or format." icon:#critical
        )
        else (
            with redraw off (
                local materials = CreateMaterials m4ds.materials filename
                local buffer = CreateObjects m4ds.objects filename unitscale materials

                LinkTargets buffer.targetBuffer buffer.mafiaNodes
                CreateSkins buffer.skinBuffer buffer.boneNodes
                Layers.Hide #("Disabled")
                --Layers.HideLods #{1..9}
            )

            CompleteRedraw()

            local used_end = (heapsize - heapfree) / 1024.0
            format "memory used ~ % KiB\n" (used_end - used_start)

            gc light:true

            local dur = elapsed_since(st) / 1000.0

            local message = "Importing took " + (dur as string) + " seconds\n"
            format message
            --messageBox message
            
            if savedMode != undefined do (
                setCommandPanelTaskMode savedMode
            )

            dur
        )
    )
)