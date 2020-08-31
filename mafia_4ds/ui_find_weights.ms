(
    local destroyed = false
    if ::FindWeights != undefined and ::FindWeights.open do (
        DestroyDialog ::FindWeights
        destroyed = true
    )

    global M4dsTools_FindWeights_pos
    
    fn traverseUp lowNode highNode = (   --finding nodes inside hierarchy between lownode and highnode
        local nodes = #()
        while lowNode != undefined and lowNode.parent != highNode  do (
            
            lowNode = lowNode.parent
            if lowNode != undefined then (
                append nodes lownode                    
            )
        )
        nodes
    )

    rollout FindWeights "Find weight conflicts"
    (        
        local util = ::MafiaTools_Util        
        
        button btnFind "Find" width:70
        
        listbox lstConflicts "" height:9
        --label numSel ""
        listbox lstBones "" height:5 offset:[0,10]
        label lblTransfer "Transfer weights:"
        button btnTransfer1 "back3  ->  r_shoulder" enabled:false
        button btnTransfer2 "r_arm  ->  r_shoulder" enabled:false
        button btnTable "Open Weight Table" offset:[0,10]
        
        on FindWeights close do (
            M4dsTools_FindWeights_pos = GetDialogPos FindWeights
        )

        on btnTable pressed do (            
            local obj = selection[1]
            if obj != undefined then (
                local sk = util.GetModByClass obj Skin
                if sk != undefined then (
                    skinOps.buttonWeightTable sk
                )
            )
        )
        
        
        local groups = #()
        local boneNodes
        local skinMod
        local bonesItemData = #()

        struct WeightGroup (
            boneid1,
            boneid2,
            verts = #{},
            weightSum1 = 0.0,
            weightSum2 = 0.0,
            avg1,
            avg2,
            upnodes = #(),
            upBoneIds = #()     
        )
        
        fn FindGroup groups boneid1 boneid2 = (
            local foundGrp
            for grp in groups while foundGrp == undefined do (
                if (grp.boneid1 == boneid1 and grp.boneid2 == boneid2) or (grp.boneid1 == boneid2 and grp.boneid2 == boneid1) then (
                    foundGrp = grp
                )
            )
            foundGrp
        )              
        
        struct VertBone (
            boneid,
            weight
        )       
        
        fn CompareVertBones v1 v2 = (
            if v1.weight > v2.weight then -1
            else if v2.weight > v1.weight then 1
            else 0
        )

        on btnFind pressed do (
            local obj = selection[1]

            if obj == undefined then (
                messageBox "No object selected!"
            )
            else (
                skinMod = util.GetModByClass obj Skin
                if skinMod == undefined then (
                    messageBox "Select an object with Skin modifier!"
                )
                else (

                    boneNodes = util.GetBoneNodes skinMod
                    groups = #()
                    local numverts = skinOps.GetNumberVertices skinMod

                    --collect broken weights into groups
                    for i = 1 to numverts do (
                        local count = skinOps.GetVertexWeightCount skinMod i

                        if count > 1 then (                             
                            local vertBones = #()
                                        
                            for n = 1 to count do (
                                local w = skinOps.GetVertexWeight skinMod i n
                                local id = skinOps.GetVertexWeightBoneID skinMod i n
                                local vb = VertBone boneid:id weight:w
                                append vertBones vb            
                            )
                            qsort vertBones CompareVertBones   
                            
                            local weight1 = vertBones[1].weight
                            local weight2 = vertBones[2].weight                                                
                            local boneid1 = vertBones[1].boneid
                            local boneid2 = vertBones[2].boneid
                            
                            local sum = weight1 + weight2
                            weight1 = weight1 / sum
                            weight2 = weight2 / sum  
                            
                            
                            if boneid1 != boneid2 then (  --for some reason it can happen that vertex is weighted twice to the same bone
                                local boneNode1 = boneNodes[boneid1]
                                local boneNode2 = boneNodes[boneid2]                                
                                
                                if weight1 != 0.0 and weight2 != 0.0 then (
                                    if not util.directlyRelated bonenode1 bonenode2 then (
                                            
                                        if util.isDescendantOf boneNode2 boneNode1 then (
                                            swap boneid1 boneid2
                                            swap weight1 weight2
                                            swap boneNode1 boneNode2
                                        )
        
                                        --create new group if it doesnt exist
                                        local grp = FindGroup groups boneid1 boneid2
                                        if grp == undefined then (
                                            grp = WeightGroup()
                                            grp.boneid1 = boneid1
                                            grp.boneid2 = boneid2
                                            append groups grp
                                        )
        
                                        grp.verts[i] = true
                                        grp.weightSum1 += weight1
                                        grp.weightSum2 += weight2
                                    )
                                )                                
                            ) 
                        )
                    )
                    ---------
                    
                    if groups.count == 0 then (
                        messageBox "No conflicts found."
                    )

                    --build listbox items from groups
                    local items = #()
                    for grp in groups do (
                        local bonename1 = boneNodes[grp.boneid1].name
                        local bonename2 = boneNodes[grp.boneid2].name

                        local item = bonename2 + " ... [ " + bonename1 + " ]    " + (grp.verts.numberset as string) + " verts"
                        append items item
                    )
                    lstConflicts.items = items
                    ------------------

                    ---create extra data
                    for grp in groups do (
                        grp.avg1 = grp.weightSum1 / grp.verts.numberset
                        grp.avg2 = grp.weightSum2 / grp.verts.numberset

                        local bonenode1 = bonenodes[grp.boneid1]
                        local bonenode2 = bonenodes[grp.boneid2]
                        
                        if (util.isDescendantOf boneNode1 boneNode2) or (util.isDescendantOf boneNode2 bonenode1)  then (
                            local upnodes = traverseUp bonenode1 bonenode2          --in order from lowest to highest, 1-lowest  N-highest
                            upnodes = util.ReverseArray upnodes

                            grp.upnodes = upnodes

                            for i = 1 to upnodes.count do (
                                grp.upBoneIds[i] = findItem bonenodes upnodes[i]
                            )
                        )
                        
                        
                    )
                    --------------------------
                )
            )

        )
        
        on lstConflicts selected val do (
            if skinMod != undefined then (
                btnTransfer1.enabled = true
                btnTransfer2.enabled = true

                local grp = groups[val]
                ---edit envelopes mode
                if getCommandPanelTaskMode() == #modify then (
                    if modPanel.getCurrentObject() != skinMod then (
                        modPanel.setCurrentObject skinMod                        
                    )
                    subObjectLevel = 1
                ) 
                
                ---select vertices and bone
                skinOps.SelectVertices skinMod grp.verts
                skinOps.SelectBone skinMod grp.boneid1


                local bonenode1 = bonenodes[grp.boneid1]
                local bonenode2 = bonenodes[grp.boneid2]
                
                
                ---------------------------------------------
                ------------------BUILD ITEMS----------------
                ---------------------------------------------
                -- TODO: rewrite this mess
                
                local items = #()
                bonesItemData = #()
                if grp.upnodes.count == 0 then (                    
                    append items bonenode2.parent.name
                    append bonesItemData (findItem bonenodes bonenode2.parent)
                    append items ("  " + bonenode2.name + "    avg.weight: " + (formattedPrint grp.avg2 format:".3f"))
                    append bonesItemData grp.boneid2
                    if bonenode1.parent != bonenode2.parent then (
                        append items bonenode1.parent.name
                        append bonesItemData (findItem bonenodes bonenode1.parent)
                    )
                    append items ("  " + bonenode1.name + "    avg.weight: " + (formattedPrint grp.avg1 format:".3f"))
                    append bonesItemData grp.boneid1
                )
                else (
                    ------create basic item names   
                    items[1] = bonenode2.name + "    avg.weight: " + (formattedPrint grp.avg2 format:".3f")
                    for i = 1 to grp.upnodes.count do (
                        items[i+1] = grp.upnodes[i].name
                    )
                    append items (bonenode1.name + "    avg.weight: " + (formattedPrint grp.avg1 format:".3f"))
                    --------------
                    
                    
                    -----indent items----
                    if grp.upnodes.count != 0 then (
                        local totalIndent = "  "
                        local indent = "  "
                        for i = 2 to items.count do (
                            items[i] = totalIndent + items[i]
                            totalIndent += indent
                        )
                    )
                    ---------------------
                    
                    ----second listbox data---
                    bonesItemData[1] = grp.boneid2
                    for i = 1 to grp.upnodes.count do (
                        bonesItemData[i+1] = grp.upBoneIds[i]
                    )
                    append bonesItemData grp.boneid1
                    ---------------------------
                )
                

                
                ----add items to second listbox
                lstBones.items = items
                lstBones.selection = items.count
                ---------------------------------------------
                ---------------------------------------------
                ---------------------------------------------
                
                


                -----
                if grp.upnodes.count == 0 then (
                    btnTransfer1.text = bonenode2.name + "  ->  " + bonenode1.parent.name
                    btnTransfer2.text = bonenode1.name + "  ->  " + bonenode2.parent.name
                )
                else (
                    btnTransfer1.text = bonenode2.name + "  ->  " + grp.upnodes[1].name
                    btnTransfer2.text = bonenode1.name + "  ->  " + grp.upnodes[grp.upnodes.count].name                    
                )
                -------


                skinMod.wt_activeVertexSet = 2
                skinMod.wt_activeVertexSet = 1
            )
        )

        on lstBones selected val do (
            if skinMod != undefined then (
                skinOps.SelectBone skinMod bonesItemData[val]
            )
        )        

        on btnTransfer1 pressed do (
            undo "Transfer1" on (
                skinOps.bakeSelectedVerts skinMod --undo workaround
                local sel = lstConflicts.selection
                local grp = groups[sel]

                local oldId = grp.boneid2
                
                local newId
                if grp.upnodes.count == 0 then (
                    newId = findItem bonenodes bonenodes[grp.boneid1].parent                    
                )
                else (
                    newId = grp.upBoneIds[1]                    
                )
                

                local verts = skinOps.getSelectedVertices skinMod
                
                for vertId in verts do (
                    util.TransferWeight skinMod vertId oldid newId
                )

                -- local items = lstConflicts.items
                -- deleteItem items sel
                -- lstConflicts.items = items

                -- deleteItem groups sel
            )
        )

        on btnTransfer2 pressed do (
            undo "Transfer2" on (  
                skinOps.bakeSelectedVerts skinMod --undo workaround
                local sel = lstConflicts.selection
                local grp = groups[sel]

                local oldId = grp.boneid1
                
                local newId
                if grp.upnodes.count == 0 then (
                    newId = findItem bonenodes bonenodes[grp.boneid2].parent
                )
                else (
                    newId = grp.upBoneIds[grp.upBoneIds.count]
                )
                
                local verts = skinOps.getSelectedVertices skinMod

                for vertId in verts do (
                    util.TransferWeight skinMod vertId oldid newId
                )

                -- local items = lstConflicts.items
                -- deleteItem items sel
                -- lstConflicts.items = items

                -- deleteItem groups sel
            )
        )
    )

    if not destroyed do (
        local pos = ::M4dsTools_FindWeights_pos
        local style = #(#style_resizing, #style_titlebar, #style_sysmenu)
        local w = 240
        local h = 360
        if pos != undefined then (
            CreateDialog FindWeights width:w height:h pos:pos style:style
        )
        else (
            CreateDialog FindWeights width:w height:h style:style
        )
    )
)