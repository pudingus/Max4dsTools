
rollout MafiaTools_4dsImport "" (   --module

    --imports--
    local Layers = ::MafiaTools_Layers    
    local util = ::MafiaTools_Util
    -----------
    
    local BAD_TYPES = #()
    

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
                local normals = #()                
                
                for i = 1 to msh.numverts do (
                    local vert = getVert msh i
                    setVert msh i (vert * unitscale)
                    append normals (getNormal msh i)
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
                    --lodNode.name = "$lod" + (lodId as string)
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
                cmod.normals = normals

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
        
        if mmorph.lods.count > 1 then (
            BAD_TYPES[4] = "Morph lods"
        )

        for region in mmorph.lods[1].regions do (
            local regionMeshes = #()

            for i = 1 to mmorph.numTargets - 1 do (
                regionMeshes[i] = copy baseMesh
            )

            for vert in region.vertices do (
                local vertId = vert.index

                for j = 1 to vert.points.count - 1 do (
                    local point = vert.points[j + 1]
                    local pos = point.pos * unitscale
                    setVert regionMeshes[j] vertId pos
                )
            )
            append meshes regionMeshes
        )

        local tmod = Morpher()
        addModifier nnode tmod
        local maxver = (maxversion())[1]
        if maxver < 15000 then (   --2013 works without selecting, 2009 doesnt, todo: find which version exactly
            max modify mode
            select nnode
        )

        local letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        
        local channelsPerRegion = 10

        -- Keep this! For some reason BuildFromNode builds data only after
        -- certain morpher function is called first (SetName, IsActive, HasData and maybe other)
        WM3_MC_HasData tmod 1
        
        for regionId = 1 to meshes.count do (
            local regionMeshes = meshes[regionId]
            local regionLetter = letters[regionId]
            local channelId = (regionId - 1) * channelsPerRegion + 1
            WM3_CreateMarker tmod channelId ("region " + regionLetter)

            for i = 1 to regionMeshes.count do (
                local targetMesh = regionMeshes[i]
                local tnode = mesh mesh:targetMesh
                local channelId = (regionId - 1) * channelsPerRegion + i + 1

                WM3_MC_BuildFromNode tmod channelId tnode
                WM3_MC_SetName tmod channelId (regionLetter + " " + ((i + 1) as string))
                
                delete tnode
            )            
        )

        WM3_SetCurrentMarker tmod 1
    )

    fn CreateBillboard mbillboard nnode = (
        local gp = GetMafParams nnode

        gp.rotAxis = mbillboard.rotAxis
        gp.rotMode = mbillboard.rotMode
    )

    fn CreateGlow mglows name unitscale materials = (
        local nnode = Glow4ds()
        nnode.viewportSize = 0.1 * unitscale

        local usedMats = #{}

        for mglow in mglows do (
            usedMats[mglow.matId] = true
        )

        local multimat = multimaterial numsubs:(usedMats.numberSet + 1)
        multimat.name = name
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

    fn CreateMirror mirr unitscale = (
        util.TransformVerts mirr.mesh unitscale

        local nnode = mesh mesh:mirr.mesh
        nnode.wirecolor = white
        Layers.AddTo nnode "Mirrors"
        
        local gp = GetMafParams nnode
        gp.mirrorColor = mirr.backColor
        gp.mirrorDist = mirr.drawDistance
        
        local size = 2 * unitscale
        
        local viewbox = dummy boxsize:[size, size, size]
        viewbox.name = "$viewbox"
        local mtr = mirr.matrix
        local s = scaleMatrix mtr.scalepart
        local r = mtr.rotationpart as matrix3
        local t = transMatrix (mtr.translationpart * unitscale)
        viewbox.transform = s * r * t
        viewbox.parent = nnode
        
        util.PrintMatrix mirr.matrix

        nnode
    )  

    fn CreateDummy mdummy unitscale = (
        local dmin = mdummy.dmin * unitscale
        local dmax = mdummy.dmax * unitscale
        local nnode = dummy()
        nnode.boxsize = util.ToBoxsize dmin dmax

        hide nnode

        nnode
    )

    --returns array of nodes
    fn CreateSector msector name unitscale = (
        local nodes = #()

        util.TransformVerts msector.mesh unitscale

        nodes[1] = mesh mesh:msector.mesh
        nodes[1].wirecolor = (color 255 199 0)
        
        local sgp = GetMafParams nodes[1]
        sgp.sectorFlags1 = msector.flags1
        sgp.sectorFlags2 = msector.flags2

        local portalId = 0
        for mportal in msector.portals do (
            util.TransformVerts mportal.mesh unitscale
            
            local portalNode = mesh mesh:mportal.mesh
            portalNode.name = "$portal" + (formattedPrint portalId format:".2u") + "__" + name
            
            local face = for v = 1 to portalnode.numVerts collect v
            portalNode = convertToPoly portalNode
            polyop.createPolygon portalNode face

            portalNode.wirecolor = (color 255 0 199)
            portalNode.parent = nodes[1]

            local gp = GetMafParams portalNode

            gp.objectType = "Portal"
            gp.portalFlags = mportal.flags
            gp.portalNearRange = mportal.nearRange
            gp.portalFarRange = mportal.farRange
            gp.portalUnknown = mportal.unknown
            

            Layers.AddTo portalNode "Portals"

            append nodes portalNode

            portalId += 1
        )
        nodes
    )

    -- returns Node
    fn CreateTarget mtarget unitscale = (
        local nnode = Target4ds()
        nnode.flags = mtarget.flags
        nnode.viewportSize = 0.1 * unitscale
        hide nnode
        
        Layers.AddTo nnode "Targets"

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
            --disables set handlers, they are re-enabled after instatiation (in Mat4ds 'postCreate')
            ::mat4ds_disable_set = true     
            local mat = Mat4ds()
            mat.name = "4dsMat"+(m as string)

            local flags = mmat.flags
            

            mat.envTile = mmat.envTile
            mat.envMode = mmat.envMode
            mat.envType = mmat.envType
            mat.addEffect = mmat.addEffect
            
            mat.tileU = not bit.get flags 1
            mat.tileV = not bit.get flags 2
            mat.diffuseMapEnable = bit.get flags 3
            mat.envMapEnable = bit.get flags 4
            mat.unknown5 = bit.get flags 5
            mat.unknown6 = bit.get flags 6
            mat.unknown7 = bit.get flags 7
            mat.mipMapping = bit.get flags 8
           
            mat.imageAlpha = bit.get flags 9
            mat.animatedAlpha = bit.get flags 10
            mat.animatedDiffuse = bit.get flags 11
            mat.colored = bit.get flags 12
            mat.twoSided = bit.get flags 13
            mat.colorKey = bit.get flags 14
            mat.alphaMapEnable = bit.get flags 15
            mat.additiveMixing = bit.get flags 16

            mat.ambient = mmat.ambient
            mat.diffuse = mmat.diffuse
            mat.emission = mmat.emission
            mat.opacity = mmat.opacity*100
            mat.glossiness = mmat.glossiness
            mat.specular = mmat.specular


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
        skinBuffer = #(),   --array of TSkin
        targetBuffer = #(),  --array of TObjPair
        boneNodes = #(),   --array of nodes sorted in boneid order
        normalNodes = #(),    --array of nodes for modifier normals
        mafiaNodes = #()
    )
    
    struct TSkin (
        skinlods = #(),
        lodnodes = #(),
        bonenodes = #()
    )

    struct TObjPair (
        mdefs,   --mafia object definitions
        nodes
    )


    fn CreateSkins skinBuffer = (
        local maxver = (maxversion())[1]
       
        for pair in skinBuffer do (
            local mskins = pair.skinlods
            local nodes = pair.lodnodes
            local boneNodes = pair.bonenodes

            for lodId = 1 to nodes.count do (
                local nnode = nodes[lodId]
                local mskin = mskins[lodId]

                local skinMod = Skin()
                skinMod.showNoEnvelopes = true
                addModifier nnode skinMod
                if maxver < 22000 then (
                    max modify mode
                    select nnode
                )   

                for boneId = 1 to boneNodes.count - 1 do (
                    skinOps.AddBone skinMod boneNodes[boneId] 0
                )
                skinOps.AddBone skinMod boneNodes[boneNodes.count] 1
                
                -- The update integer in AddBone doesnt work on old versions (2013, 2009...)
                -- and this somehow updates it, so keep it!
                nnode.numverts  --keep this!
                
                local xskin = skin_makeCache skinMod
                
                for vertId = 1 to mskin.weights.count do (
                    local boneId = mskin.weights[vertId][1]
                    local weight = mskin.weights[vertId][2]
                    
                    local parentId = mskin.parentIds[boneId]
                    
                    if parentId == undefined then (
                        skin_replaceVertexWeights xskin vertId boneId weight
                    )
                    else (
                        skin_replaceVertexWeights xskin vertId #(boneId, parentId) #(weight, 1.0 - weight)
                    )
                )
                
                for vertId = mskin.weights.count + 1 to nnode.numverts do (
                    skin_replaceVertexWeights xskin vertId 1 0.0
                )
            )
            
            for boneNode in boneNodes where bonenode != undefined do (
                boneNode.setBoneEnable true sliderTime
                boneNode.setSkinPose()
            )
        )
    )
    
    fn CreateOccluder ocl unitscale = (        
        util.TransformVerts ocl.mesh unitscale
        
        mesh mesh:ocl.mesh wirecolor:(color 178 89 255)
    )

    fn CreateObjects mobjects filename unitscale materials = (
        local buffer = TWorldBuffer()
        
        local currentSkin
        
        BAD_TYPES = #()

        for i = 1 to mobjects.count do (
            local mobj = mobjects[i]
            local nnode
            local baseMesh

            case mobj.objectType of (
                1: case mobj.visualType of (
                    0: (  --object
                        local mmesh = mobj.mesh

                        local nodes = #()
                        if mmesh.instanceId == 0 then (
                            nodes = CreateMesh mmesh mobj.name unitscale materials
                        )
                        else (
                            nodes[1] = instance buffer.mafiaNodes[mmesh.instanceId]
                        )

                        nnode = nodes[1]
                    )
                    1: (  --litobject
                        local mmesh = mobj.mesh

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
                        local mmesh = mobj.mesh
                        local mskins = mobj.skin
                        
                        local name = mobj.name + ".skin"
                        local nodes = CreateMesh mmesh name unitscale materials

                        baseMesh = nodes[1]
                        baseMesh.name = "_" + name


                        nnode = CreateBone()
                        
                        currentSkin = TSkin()
                        currentSkin.boneNodes[1] = nnode
                        currentSkin.skinLods = mskins
                        currentSkin.lodnodes = nodes
                        
                        
                        append buffer.skinBuffer currentSkin

                        --baseMesh.parent = nnode
                    )
                    3: (  --singlemorph
                        local mmesh = mobj.mesh
                        local mskins = mobj.skin
                        local mmorph = mobj.morph
                        
                        local name = mobj.name + ".skin"
                        local nodes = CreateMesh mmesh name unitscale materials
                        CreateMorph mmorph mmesh nodes[1] unitscale

                        baseMesh = nodes[1]
                        baseMesh.name = "_" + name

                        nnode = CreateBone()
                        
                        currentSkin = TSkin()
                        currentSkin.boneNodes[1] = nnode
                        currentSkin.skinLods = mskins
                        currentSkin.lodnodes = nodes
                        
                        
                        append buffer.skinBuffer currentSkin

                        --baseMesh.parent = nnode
                    )
                    4: ( --billboard
                        local mmesh = mobj.mesh
                        local mbillboard = mobj.billboard
                        local nodes = #()
                        if mmesh.instanceId == 0 then (
                            nodes = CreateMesh mmesh mobj.name unitscale materials
                        )
                        else (
                            nodes[1] = instance buffer.mafiaNodes[mmesh.instanceId]
                        )

                        nnode = nodes[1]
                        
                        CreateBillboard mbillboard nnode

                        Layers.AddTo nnode "Billboards"


                        --append buffer.normalNodes
                    )
                    5: ( --morph
                        local mmesh = mobj.mesh
                        local mmorph = mobj.morph
                        local nodes = CreateMesh mmesh mobj.name unitscale materials
                        nnode = nodes[1]
                        CreateMorph mmorph mmesh nnode unitscale
                    )
                    6: ( --glow
                        local mglows = mobj.glow
                        nnode = CreateGlow mglows mobj.name unitscale materials
                        Layers.AddTo nnode "Glows"
                    )
                    7: (  --visual_projector
                        local size = 1.0 * unitscale
                        local boxsize = [size, size, size]
                        nnode = dummy boxsize:boxsize
                        
                        BAD_TYPES[1] = "VISUAL_PROJECTOR"
                        
                        format "% : projector\n" mobj.name
                        
                        -- UNSUPPORTED
                    )
                    8: (  --mirror
                        local mmirror = mobj.mirror
                        nnode = CreateMirror mmirror unitscale
                    )
                    9: (  --visual_emitor
                        local size = 1.0 * unitscale
                        local boxsize = [size, size, size]
                        nnode = dummy boxsize:boxsize
                        
                        BAD_TYPES[2] = "VISUAL_EMITOR"
                        
                        format "% : emitor\n" mobj.name
                        -- UNSUPPORTED
                    )
                    default: (
                        local size = 1.0 * unitscale
                        local boxsize = [size, size, size]
                        nnode = dummy boxsize:boxsize
                    )
                )
                2: (  --frame_light
                    local size = 1.0 * unitscale
                    local boxsize = [size, size, size]
                    nnode = dummy boxsize:boxsize
                    
                    BAD_TYPES[3] = "FRAME_LIGHT"
                    
                    format "% : light\n" mobj.name
                    
                    -- UNSUPPORTED
                )
                5: ( --sector
                    local msector = mobj.sector
                    nnode = (CreateSector msector mobj.name unitscale)[1]
                    Layers.AddTo nnode "Sectors"
                )
                6: ( --dummy
                    local mdummy = mobj.dummy
                    nnode = CreateDummy mdummy unitscale
                    Layers.AddTo nnode "Dummies"
                )
                7: ( --target
                    local mtarget = mobj.target
                    nnode = CreateTarget mtarget unitscale

                    append buffer.targetBuffer (TObjPair mdefs:mtarget nodes:nnode)
                )
                10: ( --bone
                    local mbone = mobj.bone
                    nnode = CreateBone()

                    if currentSkin != undefined then (
                        currentSkin.boneNodes[mbone.boneId + 1] = nnode
                    )
                )
                12: (  --occluder
                    local ocl = mobj.occluder
                    nnode = CreateOccluder ocl unitscale
                    Layers.AddTo nnode "Occluders"
                )
                default: (
                    local size = 1.0 * unitscale
                    local boxsize = [size, size, size]
                    nnode = dummy boxsize:boxsize
                )
            ) 
            

            if not bit.get mobj.cullFlags 1 then (
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
                nnode.parent = undefined   --needed because instanced meshes by default inherit parent from the main instance 
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
                12: "Occluder"
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
    
    fn Import4ds file unitscale:1.0 progHandler: = (
        -- switch away from modify panel, for performance
        local mode = getCommandPanelTaskMode()
        local savedMode
        if mode == #modify then (
            savedMode = mode
            setCommandPanelTaskMode #create
        )
        -----------------------------

        filename = getFilenameFile file
        format "importing: %\n" file
        
        local showProgress = true
            
        local progress = 0
        if progHandler != unsupplied do progHandler progress "Reading..."
        
        local st = timestamp()        
        local fileStart = timestamp()
        
        local f = fopen file "rb"
        local parser = ::MafiaTools_4dsParser
        try (
            local m4ds = parser.Read4ds f
        )
        catch (
            messageBox (getCurrentException()) icon:#critical
        )
        try (fclose f) catch()
        
        local fileDur = (elapsed_since fileStart) / 1000.0

        if m4ds == undefined then (
            if progHandler != unsupplied do progHandler 0 "Error"
            messageBox "This file cannot be imported. Unknown version or format." icon:#critical
            undefined
        )
        else (
            with redraw off (
                local matStart = timestamp()
                
                if showProgress do (
                    progress += 12            
                    if progHandler != unsupplied do progHandler progress "Creating materials..."
                )
                
                local materials = CreateMaterials m4ds.materials filename
                
                local matDur = (elapsed_since matStart) / 1000.0
                if showProgress do (
                    progress += 16
                    if progHandler != unsupplied do progHandler progress "Creating objects..."
                )
                
                local objStart = timestamp()
                
                local buffer = CreateObjects m4ds.objects filename unitscale materials

                LinkTargets buffer.targetBuffer buffer.mafiaNodes
                CreateSkins buffer.skinBuffer
                Layers.Hide #("Disabled")
                --Layers.HideLods #{1..9}
                
                local objDur = (elapsed_since objStart) / 1000.0
                if showProgress do (                 
                    progress += 60
                    if progHandler != unsupplied do progHandler progress "Redrawing..."
                )
            )

            local redrawStart = timestamp()
            redrawViews()
            local redrawDur = (elapsed_since redrawStart) / 1000.0
            
            local totalDur = fileDur + matDur + objDur + redrawDur
            local dur = (elapsed_since st) / 1000.0
            

            progress = 100
            if progHandler != unsupplied do (
                progHandler progress ("Done in " + (dur as string) + " seconds")
            )            
            
            local stats = stringstream ""
            
            format "Reading: % (%\%)\n" fileDur (fileDur / totalDur * 100) to:stats
            format "Materials: % (%\%)\n" matDur (matDur / totalDur * 100) to:stats
            format "Objects: % (%\%)\n" objDur (objDur / totalDur * 100) to:stats
            format "Redrawing: % (%\%)\n" redrawDur (redrawDur / totalDur * 100) to:stats
            format "Pendur: %\n" pendDur to:stats
            format "Total: %\n" totalDur to:stats
            format "Total + overhead: %\n" dur to:stats
            format "%" (stats as string)
            
            if savedMode != undefined do (
                setCommandPanelTaskMode savedMode
            )
            
            if BAD_TYPES.count > 0 then (
                local types = ""
                for type in BAD_TYPES where type != undefined do (
                    types += type + "\n"
                )
                
                messageBox ("Following object types were skipped:\n" + types) icon:#warning
            )

            m4ds.allow5ds
        )
    )
)