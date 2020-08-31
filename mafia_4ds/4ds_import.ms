
struct MafiaTools_4dsImport (

    --imports--
    Layers = MafiaTools_Layers,
    parser = MafiaTools_4dsParser,
    -----------
    
    allMats = #(),

    fn GetMafParams nnode = (
        custAttributes.add nnode MafParams_def baseObject:false
        custAttributes.get nnode MafParams_def baseObject:false
    ),


    --returns array of nodes
    fn CreateMesh mmesh name unitscl = (
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
                    setVert msh i (vert * unitscl)
                )               
            
                local lodNode = mesh mesh:msh
                lodNode.wirecolor = color 0 0 0
                
                
                local usedMats = #{}
                
                for fcgrp in mlod.facegroups do (
                    if fcgrp.matId != 0 then (
                        usedMats[fcgrp.matId] = true                        
                    )
                )
                
                local multimat = multimaterial numsubs:(usedMats.numberSet + 1)
                multimat.name = name
                multimat[multimat.numsubs] = undefined
                local index = 1
                local indices = #()
                
                for matId in usedMats do (
                    multimat[index] = allMats[matId]
                    indices[matId] = index
                    index += 1
                )               
                
                
                lodnode.material = multimat
                
                
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

                custAttributes.add lodNode MafParams_def baseObject:false
                local gp = custAttributes.get lodNode mafParams_def baseObject:false

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
    ),


    fn CreateMorph mmorph mmesh nnode unitscl = (
        local baseMesh = mmesh.lods[1].mesh
        local meshes = #()

        for chan in mmorph.sections do (
            local sectionMeshes = #()

            for i = 1 to mmorph.numTargets do (
                sectionMeshes[i] = copy baseMesh
            )

            for i = 1 to chan.vertices.count do (
                local vertId = chan.vertexLinks[i] + 1
                local mvert = chan.vertices[i]

                for j = 1 to mvert.targets.count do (
                    local target = mvert.targets[j]
                    local vert = target.pos * unitscl
                    setVert sectionMeshes[j] vertId vert
                )
            )
            append meshes sectionMeshes
        )

        local tmod = Morpher()
        addModifier nnode tmod
        max modify mode
        select nnode

        local sectionNames = #("A", "B", "C")
        local layerNames = #("layer A", "layer B", "layer C")

        local sectionId = 1
        local marker = 1

        for sectMesh in meshes do (
            local sectionName = sectionNames[sectionId]
            WM3_CreateMarker tmod marker layerNames[sectionId]

            local targetId = 1

            for targetMesh in sectMesh do (
                local tnode = mesh mesh:targetMesh
                local finalId = (marker + targetId - 1)

                WM3_MC_BuildFromNode tmod finalId tnode
                WM3_MC_SetName tmod finalId (sectionName + " " + (targetId as string))

                delete tnode

                targetId += 1
            )
            marker = (sectionId * 10 + 1)
            sectionId += 1
        )

        WM3_SetCurrentMarker tmod 1
    ),

    fn CreateBillboard mbillboard nnode = (
        custAttributes.add nnode MafParams_def baseObject:false
        local gp = custAttributes.get nnode MafParams_def baseObject:false

        gp.rotAxis = mbillboard.rotAxis + 1
        gp.rotMode = mbillboard.rotMode + 1
    ),

    fn CreateGlow mglows mobj = (
        local nnode = M4dsGlow()
        nnode.wirecolor = color 248 128 0
        nnode.boxmode = true
        nnode.renderable = false
        
        local usedMats = #{}
        
        for mglow in mglows do (            
            usedMats[mglow.matId] = true
        )
        
        local multimat = multimaterial numsubs:(usedMats.numberSet + 1)
        multimat.name = "glow"
        multimat[multimat.numsubs] = undefined
        local index = 1
        local indices = #()
        
        for matId in usedMats do (
            multimat[index] = allMats[matId]
            indices[matId] = index
            index += 1
        )

        nnode.material = multimat

        for mglow in mglows do (
            append nnode.positions mglow.position
            append nnode.materials allMats[mglow.matId]
        )

        nnode
    ),

    fn CreateMirror mmirror mobj unitscl = (
        local msh = mmirror.mesh
        for i = 1 to msh.numverts do (
            local vert = getVert msh i
            setVert msh i (vert * unitscl)
        )     
        
        nnode = mesh mesh:msh
        nnode.wirecolor = white
        Layers.AddTo nnode "Mirrors"
        
        nnode
    ),

    fn CreateDummy mdummy mobj unitscl = (
        local dmin = mdummy.dmin * unitscl
        local dmax = mdummy.dmax * unitscl
        local nnode = dummy()
        nnode.boxsize = [(abs (dmin.x-dmax.x)), (abs (dmin.y-dmax.y)), (abs (dmin.z-dmax.z))]

        hide nnode

        nnode
    ),

    --returns array of nodes
    fn CreateSector msector mobj unitscl = (
        local nodes = #()
        
        local msh = msector.mesh
        
        for i = 1 to msh.numverts do (
            local vert = getVert msh i
            setVert msh i (vert * unitscl)
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
                setVert portalNode v (vert * unitscl)
            )
            local face = for v = 1 to numVerts collect v
            portalNode = convertToPoly portalNode
            polyop.createPolygon portalNode face

            portalNode.wirecolor = (color 255 0 199)
            portalNode.parent = nodes[1]

            custAttributes.add portalNode MafParams_def baseObject:false
            local gp = custAttributes.get portalNode MafParams_def baseObject:false

            gp.objectType = "Portal"
            gp.nearRange = mportal.nearRange
            gp.farRange = mportal.farRange

            Layers.AddTo portalNode "Portals"

            append nodes portalNode

            portalId += 1
        )
        nodes
    ),

    -- returns Node
    fn CreateTarget mtarget mobj = (
        local nnode = M4dsTarget()
        nnode.wirecolor = color 28 122 210
        hide nnode

        nnode
    ),

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
    ),

    fn CreateMaterials mmats filename = (
        if mmats.count > 0 then (
            pngio.ipngio.setType #gray8
            pngio.ipngio.setInterlaced false
            pngio.ipngio.setAlpha false
           
            allmats = #()

            for m = 1 to mmats.count do (
                local mmat = mmats[m]
                local mat = MafMat4()
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
                
                append allMats mat
            )
        )
    ),

    TWorldBuffer = (
        struct TWorldBuffer (
            skinBuffer = #(),   --array of TObjPair
            targetBuffer = #(),  --array of TObjPair
            boneNodes = #(),   --array of nodes sorted in boneid order
            normalNodes = #(),    --array of nodes for modifier normals
            mafiaNodes = #()
        )
    ),

    TObjPair = (
        struct TObjPair (
            mdefs,   --mafia object definitions
            nodes
        )
    ),


    fn CreateSkins skinBuffer boneNodes  = (
        for pair in skinBuffer do (
			local mskins = pair.mdefs
			local nodes = pair.nodes			
			
			for q = 1 to nodes.count do (			
				local nnode = nodes[q]
				local mskin = mskins[q]
			
				local oskin = Skin()	
                oskin.showNoEnvelopes = true
				addModifier nnode oskin				
				max modify mode			
				select nnode
                
                for i = 1 to boneNodes.count do (
					skinOps.AddBone oskin boneNodes[i] 0
                )
                
                for vertId = 1 to nnode.numverts do (                    
                    for bnId = 1 to boneNodes.count do (
                        skinOps.ReplaceVertexWeights oskin vertId bnId 0.0                       
                    )
                )
                
								
				local vertId = 1
				
				for i = 1 to mskin.vgroups.count do (
					local grp = mskin.vgroups[i]	
					local boneid1 = i+1
					local boneid2 = grp.boneId+1
					
					for j = 1 to grp.numW1Verts do (
						local weight = 1.0
						skinOps.SetVertexWeights oskin vertId boneid1 weight				
						
						vertId += 1
					)
					
					for weight in grp.weights do (
						skinOps.SetVertexWeights oskin vertId boneid1 weight						
						skinOps.SetVertexWeights oskin vertId boneid2 (1.0 - weight)						
								
						vertId += 1
					)
				)
				
				for i = 1 to mskin.numW0Verts do (
					local weight = 1.0
					skinOps.SetVertexWeights oskin vertId 1 weight
					vertid += 1
				)
			)		
		)
        for boneNode in boneNodes do (
            boneNode.setBoneEnable true sliderTime
        )
	),
	
	fn CreateObjects mobjects filename unitscl = (	
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
							nodes = CreateMesh mmesh mobj.name unitscl
						)
						else (
							nodes[1] = instance buffer.mafiaNodes[mmesh.instanceId]							
						)
												
						nnode = nodes[1]
					)
					2: (  --singlemesh
						local mmesh = mobj.definitions[1]
						local mskins = mobj.definitions[2]
						local nodes = CreateMesh mmesh filename unitscl
						
						baseMesh = nodes[1]
						baseMesh.name = filename
															
						append buffer.skinBuffer (TObjPair mdefs:mskins nodes:nodes)
						
						
						nnode = CreateBone()
						buffer.boneNodes[1] = nnode						
						
						--baseMesh.parent = nnode
					)
					3: (  --singlemorph
						local mmesh = mobj.definitions[1]
						local mskins = mobj.definitions[2]
						local mmorph = mobj.definitions[3]
						local nodes = CreateMesh mmesh filename unitscl
						CreateMorph mmorph mmesh nodes[1] unitscl
						
						baseMesh = nodes[1]
						baseMesh.name = filename
															
						append buffer.skinBuffer (TObjPair mdefs:mskins nodes:nodes)			
						
						
						nnode = CreateBone()
						buffer.boneNodes[1] = nnode						
						
						--baseMesh.parent = nnode
					)
					4: ( --billboard
						local mmesh = mobj.definitions[1]
						local mbillboard = mobj.definitions[2]
						local nodes = CreateMesh mmesh mobj.name unitscl
						nnode = nodes[1]
						CreateBillboard mbillboard nnode
						
						Layers.AddTo nnode "Billboards"
						
						
						--append buffer.normalNodes
					)
					5: ( --morph
						local mmesh = mobj.definitions[1]
						local mmorph = mobj.definitions[2]
						local nodes = CreateMesh mmesh mobj.name unitscl
						nnode = nodes[1]			
						CreateMorph mmorph mmesh nnode unitscl
					)
					6: ( --glow
						local mglows = mobj.definitions[1]
						nnode = CreateGlow mglows mobj
						Layers.AddTo nnode "Glows"
					)
					8: (  --mirror
						local mmirror = mobj.definitions[1]
						nnode = CreateMirror mmirror mobj unitscl
					)
				)
				5: ( --sector
					local msector = mobj.definitions[1]
					nnode = (CreateSector msector mobj unitscl)[1]
					Layers.AddTo nnode "Sectors"
				)
				6: ( --dummy
					local mdummy = mobj.definitions[1]
					nnode = CreateDummy mdummy mobj unitscl
					Layers.AddTo nnode "Dummies"
				)
				7: ( --target
					local mtarget = mobj.definitions[1]
					nnode = CreateTarget mtarget mobj
					
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
            local t = transMatrix (mobj.offset * unitscl)  
            
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
			

			gp.objectType = case mobj.objectType of (
				1: case mobj.visualType of (
					6: "Dummy"
					4: "Billboard"
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
	),

    fn LinkTargets targetBuffer mafiaNodes = (
        for pair in targetBuffer do (
            local mtarget = pair.mdefs
            local targetNode = pair.nodes

            for linkId in mtarget.linkIds do (
                append targetNode.nodes mafiaNodes[linkId]
            )
        )
    ),

    fn Import4ds file unitscl = (
        if getCommandPanelTaskMode() == #modify then (
            setCommandPanelTaskMode #create
        )

        filename = getFilenameFile file

        format "importing: %\n" file
        local start = timeStamp()

        gc light:true

        local used_start = (heapsize - heapfree) / 1024.0

        local f = fopen file "rb"
        local m4ds = parser.Read4ds f
        fclose f

        if m4ds == undefined then (
            messageBox "This file cannot be imported. Unknown version or format." icon:#critical
        )
        else (
            with redraw off (
                CreateMaterials m4ds.materials filename
                local buffer = CreateObjects m4ds.objects filename unitscl

                LinkTargets buffer.targetBuffer buffer.mafiaNodes
                CreateSkins buffer.skinBuffer buffer.boneNodes
                Layers.Hide #("Disabled")
                --Layers.HideLods #{1..9}
            )

            CompleteRedraw()
            gc light:true

            local end = timeStamp()
            if end < start then end += 86400000 --timing over midnight
            local dur = (end - start) / 1000.0

            local used_end = (heapsize - heapfree) / 1024.0
            format "memory used ~ % KiB\n" (used_end - used_start)

            local message = "Importing took " + (dur as string) + " seconds\n"
            format message
            --messageBox message

            dur
        )
    )
)
--MafiaTools_4dsImport = MafiaTools_4dsImport()