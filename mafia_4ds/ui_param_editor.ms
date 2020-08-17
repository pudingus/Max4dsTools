global OnNodeRenamed
global OnSelectionChanged
global floater
global MafParamEditor
(
    --include "util.ms"
    
    local util = MafiaTools_Util
    
    local gp
    local EnabledMode
    local DisabledMode    
    local OpenSelection
    local OnDeselected

    local visible = false

    rollout MafParamEditor "4DS Parameters"
    (
        timer timerDeselected interval:50 active:false

        on timerDeselected tick do (
            --format "DESELECTED!\n"
            timerDeselected.active = false            
            OnDeselected()
        )

        label objectName "" align:#left
        --edittext objectName "" readOnly:true align:#left
        --hyperlink objectName "" align:#left
        button addParams "Add" align:#left pos:[10,25] tooltip:"Add parameters"
        button removeParams "Remove" align:#left pos:[50,25] tooltip:"Remove parameters"
        label objectTypeLabel "Object type:" across:2 offset:[0,3] align:#left
        dropdownlist objectType "" align:#left width:80	 items:#("Dummy")

        on objectType selected i do (
            
            local strsel = objectType.items[i]

            if gp != undefined then gp.objectType = strsel

            OpenSelection strsel
        )

        on addParams pressed do (
            local obj = selection[1]
            if obj != undefined then (
                
                custAttributes.add obj MafParams_def baseObject:false
                gp = custAttributes.get obj MafParams_def baseObject:false

                local sel = objectType.selection
                local strsel = objectType.items[sel]

                gp.objectType = strsel

                if stricmp strsel "sector" == 0 then (
                    gp.cullFlags = 125
                )
                
                EnabledMode()
                MafParamEditor.objectType.selection = 1
                OpenSelection strsel 
            )
        )

        on removeParams pressed do (
            local obj = selection[1]
            if obj != undefined then (

                if queryBox "Do you want to remove parameters from this object?" then (                    

                    custAttributes.delete obj MafParams_def baseObject:false

                    DisabledMode()
                    MafParamEditor.addParams.enabled = true
                )
            )
        )

        on MafParamEditor close do (
            --print "close"
            callbacks.removeScripts #selectionSetChanged id:#selChangedID
            callbacks.removeScripts #nodeRenamed id:#nodeRenamedID
        )
    )

    rollout ObjectRoll ""
    (
        spinner renderFlags "Render flags:" range:[0,255,0] type:#integer align:#left fieldwidth:30 enabled:false across:2
        spinner renderFlags2 "" range:[0,255,0] type:#integer fieldwidth:30 enabled:false
        checkbox depthBias "Depth bias" across:2
        checkbox shadowed "Shadowed" 
        checkbox texProj "Tex. proj." across:2 tooltip:"Texture projection"
        checkbox noFog "No fog"

        spinner cullFlags "Culling flags:  " range:[0,255,0]  type:#integer align:#left fieldwidth:50 tooltip:"9=normal, 125=sector, \n61=wall, 29=in portal, \n16=disabled, 17=disabled"
        label paramsLabel "String params:" align:#left
        edittext strParams "" align:#left width:140 height:30

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

        on strParams changed val do (
            gp.strParams = val
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

        on lodDist changed val do (
            gp.lodDist = val
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
        radiobuttons rotMode "Rotation mode:" labels:#("All axes", "Single axis:") align:#left columns:1
        dropdownlist rotAxis "" items:#("X", "Y", "Z") offset:[20,0] width:50

        on rotMode changed val do (
            gp.rotMode = val        
        )

        on rotAxis selected i do (
            gp.rotAxis = i
        )
    )
    
    -- rollout GlowRoll ""
    -- (        
    --     button add "Add" across:2
    --     button remove "Remove"
    --     listbox glows ""
    --     spinner position "Position" type:#float
    --     --spinner matID "Material ID" type:#integer range:[0,65535,0]       
    --     materialButton mat "Material" 
        
    --     on mat picked mtl do
    --     (
    --         print mtl
    --         mat.caption = mtl.name
    --     )
    --     on mat rightclick mtl do
    --     (
    --         print mtl
    --         mat.caption = mtl.name
    --     )
    -- )

    fn OnDeselected = (
        MafParamEditor.objectName.text = ""

        DisabledMode()        

        MafParamEditor.addParams.enabled = false
    )
	
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
            ObjectRoll.depthBias.enabled = false
            ObjectRoll.shadowed.enabled = false
            ObjectRoll.texProj.enabled = false
            ObjectRoll.noFog.enabled = false
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
            ObjectRoll.depthBias.enabled = false
            ObjectRoll.shadowed.enabled = false
            ObjectRoll.texProj.enabled = false
            ObjectRoll.noFog.enabled = false
        )
        else if stricmp strsel "bone" == 0 then (
            for c in ObjectRoll.controls do c.enabled = true  
            ObjectRoll.renderFlags.enabled = false
            ObjectRoll.renderFlags2.enabled = false
            ObjectRoll.depthBias.enabled = false
            ObjectRoll.shadowed.enabled = false
            ObjectRoll.texProj.enabled = false
            ObjectRoll.noFog.enabled = false
        )
        else if stricmp strsel "target" == 0 then (
            for c in ObjectRoll.controls do c.enabled = true  
            ObjectRoll.renderFlags.enabled = false
            ObjectRoll.renderFlags2.enabled = false
            ObjectRoll.depthBias.enabled = false
            ObjectRoll.shadowed.enabled = false
            ObjectRoll.texProj.enabled = false
            ObjectRoll.noFog.enabled = false
        )
        -- else if stricmp strsel "glow" == 0 then (
        --     for c in ObjectRoll.controls do c.enabled = true  
            
        --     rlts = #(GlowRoll)
        -- )

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

        -- format "displayed_rolls: %\n" displayed_rolls
        -- format "rlts: %\n" rlts
        -- format "remove_rolls %\n" remove_rolls
        -- format "add_rolls: %\n" add_rolls
        -- format "update_rolls: %\n" update_rolls


        for roll in remove_rolls do (
            removeRollout roll floater
        )

        for roll in add_rolls do (
            addRollout roll floater
        )

        displayed_rolls = rlts
        

        if ObjectRoll.isDisplayed then (
            ObjectRoll.renderFlags.value = gp.renderFlags
            ObjectRoll.renderFlags2.value = gp.renderFlags2
            ObjectRoll.cullFlags.value = gp.cullFlags

            if gp.strParams != undefined then (
                ObjectRoll.strParams.text = gp.strParams
            ) 

            local flags = gp.renderFlags2

            ObjectRoll.depthBias.checked = bit.get flags 1
            ObjectRoll.shadowed.checked = bit.get flags 2 
            ObjectRoll.texProj.checked = bit.get flags 6 
            ObjectRoll.noFog.checked = bit.get flags 8
        )

        if LodRoll.isDisplayed then (
            LodRoll.lodDist.value = gp.lodDist
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

    fn SetSelectionStr sel = (
        local items = MafParamEditor.objectType.items
        
        local id = findItem items sel
        if id == 0 then id = 1

        MafParamEditor.objectType.selection = id      
    )

    fn EnabledMode = (
        MafParamEditor.addParams.enabled = false
        MafParamEditor.removeParams.enabled = true        
        MafParamEditor.objectType.enabled = true        
        MafParamEditor.objectTypeLabel.enabled = true

        if not visible then (
            --format "REVIS \n"
            for c in ObjectRoll.controls do c.visible = true
            for c in LodRoll.controls do c.visible = true
            for c in PortalRoll.controls do c.visible = true
            for c in BillRoll.controls do c.visible = true

            visible = true
        ) 
    )

    fn DisabledMode = (
        --MafParamEditor.addParams.enabled = true
        MafParamEditor.removeParams.enabled = false

        MafParamEditor.objectTypeLabel.enabled = false 
        MafParamEditor.objectType.enabled = false 
        
        MafParamEditor.objectType.selection = 1 

        for c in ObjectRoll.controls do c.visible = false
        for c in LodRoll.controls do c.visible = false
        for c in PortalRoll.controls do c.visible = false
        for c in BillRoll.controls do c.visible = false

        visible = false
    )

    --local start = timestamp()
    --local end = timestamp()
    fn OnSelectionChanged =
    (    
        local obj = selection[1]

        --print selection.count
        --print obj

        -- if obj == undefined then start = timeStamp()       
        -- else (
        --     end = timeStamp()  
        --     format "dur: % ms\n" (end - start)               
        -- )

        -- Workaround for performance reasons - when selecting in scene explorer,
        -- callback fires twice, once with 'undefined', then with correct object.
        if obj == undefined then (
            MafParamEditor.timerDeselected.active = true
        )
        else (
            MafParamEditor.timerDeselected.active = false
        )


        if selection.count >= 2 then (
            MafParamEditor.objectName.text = ""
            DisabledMode()        
            MafParamEditor.addParams.enabled = false
        )
        else if selection.count == 1 then (
            MafParamEditor.objectName.text = obj.name
            --MafParamEditor.objectName.tooltip = obj.name

            local nodeType = util.GetNodeType obj
            case nodeType of (
                #sector: (
                    MafParamEditor.objectType.items = #("Sector")
                )
                #portal: (
                    MafParamEditor.objectType.items = #("Portal")
                )
                #lod: (
                    MafParamEditor.objectType.items = #("Lod")
                )
                #mesh: (
                    MafParamEditor.objectType.items = #("Mesh", "Billboard")
                )
                #billboard: (
                    MafParamEditor.objectType.items = #("Mesh", "Billboard")
                )
                #singlemesh: (
                    MafParamEditor.objectType.items = #("Mesh")
                )
                #dummy: (
                    MafParamEditor.objectType.items = #("Dummy")
                )
                #target: (
                    MafParamEditor.objectType.items = #("Target")
                )
                #morph: (
                    DisabledMode()        
                    MafParamEditor.addParams.enabled = false
                   -- MafParamEditor.objectType.items = #("")
                )
                #bone: (
                    MafParamEditor.objectType.items = #("Bone")
                )
                default: (
                    MafParamEditor.objectType.items = #("Dummy")
                )
            )
              
            
            gp = custAttributes.get obj MafParams_def baseObject:false

            if gp != undefined and nodeType != #morph then (    
                local items = MafParamEditor.objectType.items   
                --format "gp.objectType: %\n" gp.objectType
                if findItem items gp.objectType == 0 then gp.objectType = items[1]                

                EnabledMode()
                SetSelectionStr gp.objectType
                OpenSelection gp.objectType 

                local instances

                local count = InstanceMgr.GetInstances obj &instances 

                
                if instances[count] == obj then (
                    --format "MASTER INSTANCE\n"
                    for c in LodRoll.controls do c.visible = true
                )
                else (
                    for c in LodRoll.controls do c.visible = false
                )
                
            )
            else (  --no custom attributes
                if nodeType != #morph then (
                    DisabledMode()
                    MafParamEditor.addParams.enabled = true
                )                
            )
        )       

    )

    fn OnNodeRenamed = ( 
        OnSelectionChanged()
    )    
	
    
    local title = "4DS Params"

    if floater != undefined then (    
        if floater.open then (
            closeRolloutFloater floater
        )
        else (
            local pos = floater.pos
            local size = floater.size
            floater = newRolloutFloater title size[1] size[2] pos[1] pos[2]
        )    
    )
    else (
        floater = newRolloutFloater title 190 470
    )

	if floater.open then (
		callbacks.addScript #selectionSetChanged "OnSelectionChanged()" id:#selChangedID
        callbacks.addScript #nodeRenamed "OnNodeRenamed()" id:#nodeRenamedID	
        	
		addRollout MafParamEditor floater
        addRollout ObjectRoll floater
        
        for c in ObjectRoll.controls do c.visible = false
        
		OnSelectionChanged()		
	)
	
)