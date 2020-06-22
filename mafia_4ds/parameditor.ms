global OnNodeRenamed
global OnSelectionChanged
global aaa
(
    local gp
    local EnabledMode
    local DisabledMode    

    rollout ObjectRoll ""
    (
        spinner renderFlags "Render flags:" range:[0,255,0] type:#integer align:#left fieldwidth:30 enabled:false across:2
        spinner renderFlags2 "" range:[0,255,0] type:#integer fieldwidth:30 enabled:false
        checkbox depthBias "Depth bias" across:2
        checkbox shadowed "Shadowed" 
        checkbox texProj "Tex. proj." across:2
        checkbox noFog "No fog"

        spinner cullFlags "Culling flags:  " range:[0,255,0]  type:#integer align:#left fieldwidth:50 tooltip:"9=normal, 125=sector, \n61=wall, 29=in portal, \n16=disabled, 17=disabled"
        label paramsLabel "String params:" align:#left
        edittext userParams "" align:#left width:130    

        on renderFlags changed val do (
            gp.renderFlags = val
        )

        on renderFlags2 changed val do (
            gp.renderFlags2 = val

            local flags = val

            depthBias.checked = bit.get flags 1
            shadowed.checked = bit.get flags 2 
            texProj.checked = bit.get flags 6 
            noFog.checked = bit.get flags 8
        )

        on cullFlags changed val do (
            gp.cullFlags = val
        )

        on userParams changed val do (
            gp.userParams = val
        )

        on depthBias changed val do (
            gp.renderFlags2 = bit.set gp.renderFlags2 1 val
            renderFlags2.value = gp.renderFlags2
        )

        on shadowed changed val do (
            gp.renderFlags2 = bit.set gp.renderFlags2 2 val
            renderFlags2.value = gp.renderFlags2
        )

        on texProj changed val do (
            gp.renderFlags2 = bit.set gp.renderFlags2 6 val
            renderFlags2.value = gp.renderFlags2
        )

        on noFog changed val do (
            gp.renderFlags2 = bit.set gp.renderFlags2 8 val
            renderFlags2.value = gp.renderFlags2
        )
    )

    rollout LodRoll ""
    (
        spinner lodDist "LOD distance:" align:#left fieldwidth:50 range:[0,9999,10] scale:1
        label exporterLabel "Exporter:" align:#left		
        checkbox dontOptimize "Don't optimize vertices" align:#left

        on lodDist changed val do (
            gp.lodDist = val
        )

        on dontOptimize changed val do (
            gp.dontOptimize = val
        )
    )

    rollout PortalRoll ""
    (
        spinner nearRange "Near range:" range:[-900000,900000,0] align:#left fieldwidth:50
        spinner farRange "Far range:  " range:[-900000,900000,0] fieldwidth:50 align:#left 

        on nearRange changed val do (
            gp.nearRange = val
        )

        on farRange changed val do (
            gp.farRange = val
        )
    )

    rollout BillRoll ""
    (
        --Billboard
        radiobuttons rotMode "Rotation Mode:" labels:#("All axes", "Single axis:") align:#left columns:1
        dropdownlist rotAxis "" items:#("X", "Y", "Z") offset:[20,0] width:50

        on rotMode changed val do (
            gp.rotMode = val        
        )

        on rotAxis selected i do (
            gp.rotAxis = i
        )
    )

    -- fn RemoveRollouts = (
    --     --removeRollout ObjectRoll aaa
    --     removeRollout LodRoll aaa    
    --     removeRollout PortalRoll aaa
    --     removeRollout BillRoll aaa    
    -- )

    --local displayed_rolls = #()
	
	local rolls = #(LodRoll, PortalRoll, BillRoll)

    fn OpenSelection strsel = (
        
        local rlts = #()
        if stricmp strsel "mesh" == 0 then (            
            for c in ObjectRoll.controls do c.enabled = true  

            rlts = #(LodRoll)
        )
        else if stricmp strsel "lod" == 0 then (
            for c in ObjectRoll.controls do c.enabled = false    

            rlts = #(LodRoll)
        )
        else if stricmp strsel "sector" == 0 then (            
            for c in ObjectRoll.controls do c.enabled = true  
            ObjectRoll.renderFlags.enabled = false
            ObjectRoll.renderFlags2.enabled = false
        )
        else if stricmp strsel "portal" == 0 then (            
            for c in ObjectRoll.controls do c.enabled = false 
            
            rlts = #(PortalRoll)
        )
        else if stricmp strsel "billboard" == 0 then (            
            for c in ObjectRoll.controls do c.enabled = true 
            
            rlts = #(LodRoll, BillRoll)
        )
        else if stricmp strsel "dummy" == 0 then (
            for c in ObjectRoll.controls do c.enabled = true  
            ObjectRoll.renderFlags.enabled = false
            ObjectRoll.renderFlags2.enabled = false
        )

        local remove_rolls = #()
        local update_rolls = #()
        local add_rolls = #()


        local displayed_rolls = for roll in rolls where roll.isDisplayed collect roll

        for roll in displayed_rolls do (

            if findItem rlts roll == 0 then append remove_rolls roll
            else append update_rolls roll
        )

        for roll in rlts do (
            if findItem displayed_rolls roll == 0 then append add_rolls roll
        )

        format "displayed_rolls: %\n" displayed_rolls
        format "rlts: %\n" rlts
        format "remove_rolls %\n" remove_rolls
        format "add_rolls: %\n" add_rolls
        format "update_rolls: %\n" update_rolls


        for roll in remove_rolls do (
            removeRollout roll aaa
        )

        for roll in add_rolls do (
            addRollout roll aaa
        )

        displayed_rolls = rlts
        

        if ObjectRoll.isDisplayed then (
            ObjectRoll.renderFlags.value = gp.renderFlags
            ObjectRoll.renderFlags2.value = gp.renderFlags2
            ObjectRoll.cullFlags.value = gp.cullFlags

            if gp.userParams != undefined then (
                ObjectRoll.userParams.text = gp.userParams
            ) 

            local flags = gp.renderFlags2

            ObjectRoll.depthBias.checked = bit.get flags 1
            ObjectRoll.shadowed.checked = bit.get flags 2 
            ObjectRoll.texProj.checked = bit.get flags 6 
            ObjectRoll.noFog.checked = bit.get flags 8
        )

        if LodRoll.isDisplayed then (
            LodRoll.lodDist.value = gp.lodDist
            LodRoll.dontOptimize.checked = gp.dontOptimize
        )

        if PortalRoll.isDisplayed then (
            PortalRoll.nearRange.value = gp.nearRange
            PortalRoll.farRange.value = gp.farRange
        )

        if BillRoll.isDisplayed then (
            BillRoll.rotMode.state = gp.rotMode
            BillRoll.rotAxis.selection = gp.rotAxis
        )       
    )

    rollout MafParamEditor "4DS Parameters"
    (
        label objectName "" align:#left
        button addParams "Add" align:#left pos:[15,30] tooltip:"Add parameters"
        button removeParams "Remove" align:#left pos:[55,30] tooltip:"Remove parameters"
        dropdownlist objectType "Object type:" align:#left width:130 offset:[0,10]	

        on objectType selected i do (
            
            local strsel = objectType.items[i]

            if gp != undefined then gp.objectType = strsel

            OpenSelection strsel
        )

        on addParams pressed do (
            local obj = selection[1]
            if obj != undefined then (
                custAttributes.add obj MafParams_def
                gp = custAttributes.get obj MafParams_def

                local sel = objectType.selection
                local strsel = objectType.items[sel]

                gp.objectType = strsel

                if stricmp strsel "sector" == 0 then (
                    gp.cullFlags = 129
                )
                
                EnabledMode()
                OpenSelection strsel 
            )
        )

        on removeParams pressed do (
            local obj = selection[1]
            if obj != undefined then (

                if queryBox "Do you want to remove parameters from this object?" then (
                    custAttributes.delete obj MafParams_def

                    DisabledMode()
                )
            )
        )

        on MafParamEditor close do (
            print "close"
            callbacks.removeScripts #selectionSetChanged id:#selChangedID
            callbacks.removeScripts #nodeRenamed id:#nodeRenamedID
        )
    )

    -- fn FindItemLower items value = (
    --     local found = false
    --     local i = 1
    --     for item in items while not found do (
    --         if stricmp item sel == 0 then found = true
    --         else i = i + 1
    --     )
    -- )

    fn EnabledMode sel:undefined = (
        MafParamEditor.addParams.enabled = false
        MafParamEditor.removeParams.enabled = true        
        MafParamEditor.objectType.enabled = true

        local items = MafParamEditor.objectType.items
        local found = false
        local i = 1

        if sel == undefined then (
            sel = items[i]
        )
        else (
            for item in items while not found do (
                if stricmp item sel == 0 then found = true
                else i = i + 1
            )
        )

        MafParamEditor.objectType.selection = i            
        
        addRollout ObjectRoll aaa
    )

    fn DisabledMode = (
        MafParamEditor.addParams.enabled = true
        MafParamEditor.removeParams.enabled = false
        MafParamEditor.objectType.selection = 1 
        MafParamEditor.objectType.enabled = false
        
        removeRollout ObjectRoll aaa
        removeRollout LodRoll aaa    
        removeRollout PortalRoll aaa
        removeRollout BillRoll aaa   
    )



    fn OnSelectionChanged =
    (    
        local obj = selection[1]

        print obj
        --print selection
        print $


        if obj != undefined then (
            MafParamEditor.objectName.text = obj.name

            -- for c in ObjectRoll.controls do c.enabled = true
            -- for c in LodRoll.controls do c.enabled = true
            -- for c in PortalRoll.controls do c.enabled = true
            -- for c in BillRoll.controls do c.enabled = true

            -- for c in ObjectRoll.controls do c.visible = true
            -- for c in LodRoll.controls do c.visible = true
            -- for c in PortalRoll.controls do c.visible = true
            -- for c in BillRoll.controls do c.visible = true


            if matchPattern obj.name pattern:"sector*" then (
                MafParamEditor.objectType.items = #("Sector")
            )
            else if matchPattern obj.name pattern:"$portal*" then(
                MafParamEditor.objectType.items = #("Portal")
            )
            else if matchPattern obj.name pattern:"$lod*" then(
                MafParamEditor.objectType.items = #("Lod")
            )
            else if isKindOf obj helper then (
                MafParamEditor.objectType.items = #("Dummy", "Glow")
            ) 
            else (
                MafParamEditor.objectType.items = #("Mesh", "Billboard")
            )

            

            

            gp = custAttributes.get obj MafParams_def

            if gp != undefined then (    
                local items = MafParamEditor.objectType.items   
                format "gp.objectType: %\n" gp.objectType
                if findItem items gp.objectType == 0 then gp.objectType = items[1]

                EnabledMode sel:gp.objectType
                OpenSelection gp.objectType 
            )
            else (  --no custom attributes
                DisabledMode()
            )
        )	   
        else (
            --MafParamEditor.objectName.text = ""
            --MafParamEditor.objectType.enabled = false
            --RemoveRollouts()

            --MafParamEditor.addParams.enabled = false
            --MafParamEditor.removeParams.enabled = false

            -- for c in ObjectRoll.controls do c.enabled = false
            -- for c in LodRoll.controls do c.enabled = false
            -- for c in PortalRoll.controls do c.enabled = false
            -- for c in BillRoll.controls do c.enabled = false

            -- for c in ObjectRoll.controls do c.visible = false
            -- for c in LodRoll.controls do c.visible = false
            -- for c in PortalRoll.controls do c.visible = false
            -- for c in BillRoll.controls do c.visible = false

        )
        
        

    )

    fn OnNodeRenamed = (
        -- local obj = selection[1]
        -- if obj != undefined then (
        --     MafParamEditor.objectName.text = obj.name

        --     if matchPattern obj.name pattern:"sector*" then (
        --         MafParamEditor.objectType.items = #("Sector")
        --     )
        --     else if matchPattern obj.name pattern:"$portal*" then(
        --         MafParamEditor.objectType.items = #("Portal")
        --     )
        --     else if matchPattern obj.name pattern:"$lod*" then(
        --         MafParamEditor.objectType.items = #("Lod")
        --     )
        --     else (
        --         MafParamEditor.objectType.items = #("Mesh", "Billboard")
        --     )
        -- )

        OnSelectionChanged()
    )
    

    callbacks.addScript #selectionSetChanged "OnSelectionChanged()" id:#selChangedID

    callbacks.addScript #nodeRenamed "OnNodeRenamed()" id:#nodeRenamedID


    if aaa != undefined then (    
        if aaa.open then (
            closeRolloutFloater aaa
        )
        else (
            local pos = aaa.pos
            local size = aaa.size
            aaa = newRolloutFloater "aaaa" size[1] size[2] pos[1] pos[2]
        )    
    )
    else (
        aaa = newRolloutFloater "aaaa" 190 460
    )


    addRollout MafParamEditor aaa
    addRollout ObjectRoll aaa

    OnSelectionChanged()


)