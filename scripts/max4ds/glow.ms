plugin SimpleObject Glow4ds
name:"4ds Glow"
classID:#(0x4ec442f4, 0x6cf47395)
category:"4ds Tools"
(
    parameters pblock
    (
        matIds type:#intTab tabSizeVariable:true
        positions type:#floatTab tabSizeVariable:true
        notify type:#integer
    )
    
    parameters pblock2 rollout:rltViewport
    (
        viewportSize type:#float default:1 ui:spnSize
    )
    
    local savedSel

    rollout rltGlow "Glow Parameters"
    (
        button btnAdd "Add" across:2 align:#left width:50
        button btnRemove "Remove" align:#right width:70
        listbox lstGlows ""


        imgTag imgMat "Material preview:" width:40 height:40 opacity:1.0 transparent:white align:#left across:2
        spinner spnPosition "Position" type:#float align:#right range:[-3.4e38, 3.4e38 ,0] fieldWidth:40 offset:[0, 18] enabled:false
        dropdownlist ddlMats enabled:false tooltip:"Material"
        
        timer tmrCooldown interval:400 active:false

        local lstGlows_select
        local ddlMats_select
        local BuildMatItems
        local itemIds = #()
    
        on tmrCooldown tick do (            
            tmrCooldown.active = false
            --print "cool story bro"
            local sel = lstGlows.selection
            if sel != 0 then (
                
                ddlMats.items = BuildMatItems $.mat
                local dsel = findItem itemIds matIds[sel] 
                ddlMats_select dsel 
            )
        )

        on btnAdd pressed do (
            local items = lstGlows.items
            append items ("Glow " + ((items.count+1) as string))
            append matIds 0
            append positions 0.0

            lstGlows.items = items 
            lstGlows_select items.count
            
            ddlMats_select ddlMats.items.count
        )

        on btnRemove pressed do (
            local sel = lstGlows.selection
            if sel != 0 then (
                local items = lstGlows.items
                deleteItem items sel
                deleteItem matIds sel
                deleteItem positions sel

                lstGlows.items = items

                if sel > items.count then lstGlows_select items.count
                else lstGlows_select sel
            )
        )
        
        fn BuildMatItems mat = (
            local items = #()
            itemIds = #()
            if mat != undefined then (
                if classof mat == multimaterial then (
                    for i = 1 to mat.numsubs do (
                        local submat = mat[i]
                        if submat != undefined then (
                            append items (i as string + " -  " + submat.name)
                            append itemIds i
                        )
                    )
                )
                else (
                    append items ("1 -  " + mat.name)
                    append itemIds 1
                )
            )
            
            items
        )
        
        fn GetPreviewBitmap mat = (
            local bmp
            if mat != undefined then (
                local map
                local class = classOf mat
                if class == Mat4ds or class == Standard then (
                    map = mat.diffuseMap
                )
                else if class == PhysicalMaterial then (
                    map = mat.base_color_map
                )
                
                if map != undefined then (
                    try (bmp = map.bitmap) catch()
                )                
            )
            bmp
        )
        
        fn lstGlows_select sel = (
            lstGlows.selection = sel
            if sel != 0 and sel <= lstGlows.items.count then (     
                local dsel = findItem itemIds matIds[sel] 
                ddlMats_select dsel          
                
                spnPosition.value = positions[sel]                
                
                ddlMats.enabled = true
                spnPosition.enabled = true
            )
            else (
                ddlMats.enabled = false
                spnPosition.enabled = false
            )
        )

        on lstGlows selected sel do lstGlows_select sel

        on spnPosition changed val do (
            local sel = lstGlows.selection
            if sel != 0 then (
                positions[sel] = val
            )
        )
        
        fn ddlMats_select sel = (
            ddlMats.selection = sel             
            if sel != 0 and sel <= ddlMats.items.count then (  
                ddlMats.tooltip = ddlMats.selected
                
                local gsel = lstGlows.selection            
                matIds[gsel] = itemIds[sel]            
                local mat = $.mat[sel]            
                imgMat.bitmap = GetPreviewBitmap mat  
            )
        )
        
        on ddlMats selected sel do ddlMats_select sel

        fn OnMatAdded sender param = (
            sender.tmrCooldown.active = true
        )
        
        on rltGlow open do (
            if $ != undefined then
                ddlMats.items = BuildMatItems $.mat
            
            local events = ::Max4ds_Events
            events.AddHandler #mtlRefAdded OnMatAdded rltGlow
            
            local count = matIds.count

            local items = #()
            for i = 1 to count do (
                append items ("Glow " + (i as string))
            )
            lstGlows.items = items
            if savedSel == undefined then savedSel = items.count

            lstGlows_select savedSel
        )

        on rltGlow close do (
            savedSel = lstGlows.selection
            
            local events = ::Max4ds_Events
            events.RemoveHandler #mtlRefAdded OnMatAdded
        )
    )    
    
    rollout rltViewport "Viewport" (
        spinner spnSize "Viewport size: " type:#float range:[0, 3.4e38, 0]
    )
    
    on buildMesh do (
        local size = viewportSize/2
        local verts = #()
        append verts [size,size,size]
        append verts [-size,-size,-size]
        setMesh mesh verts:verts
    )
    
    tool create
    (
        on mousePoint click do
        (
            nodeTM.translation = gridPoint;#stop
        )
    )
    
    local afterCreate = false
    
    on create do (
        afterCreate = true
    )
    
    on attachedToNode node do (
        if afterCreate then (
            node.wirecolor = color 248 128 0
            node.boxmode = true
            node.renderable = false
            
            local multi = multimaterial()
            for i = 1 to multi.numsubs do (
                multi[i] = undefined
            )          
            node.material = multi
        )
        
        afterCreate = false
    )
)
