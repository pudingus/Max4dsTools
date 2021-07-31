plugin SimpleObject Glow4ds
name:"4ds Glow"
classID:#(0x4ec442f4, 0x6cf47395)
category:"4ds Tools"
(
    parameters pblock
    (
        matIds type:#intTab tabSizeVariable:true
        positions type:#floatTab tabSizeVariable:true
        unknowns type:#floatTab tabSizeVariable:true default:1.0
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


        imgTag imgMat width:40 height:40 opacity:1.0 transparent:[255,0,255] align:#left across:2
        --bitmap imgMat width:40 height:40 align:#left across:2
        spinner spnPosition "Position " type:#float align:#right range:[-3.4e38, 3.4e38, 0] fieldWidth:38 offset:[0,2] enabled:false
        spinner spnUnknown  "Unknown" type:#float align:#right range:[-3.4e38, 3.4e38, 0] fieldWidth:38 offset:[0,-20] enabled:false tooltip:"Not supported in Mafia"
        dropdownlist ddlMats enabled:false tooltip:"Material"
        
        timer tmrCooldown interval:200 active:false

        local lstGlows_select
        local ddlMats_select
        local BuildMatItems
        local itemMatIds = #()   --stores material id for each item in ddlMats
    
        on tmrCooldown tick do (    --cooldown for material notifications
            tmrCooldown.active = false
            --print "cool story bro"
            local glowId = lstGlows.selection
            if glowId != 0 then (
                ddlMats.items = BuildMatItems $.mat
                local dsel = findItem itemMatIds matIds[glowId] 
                ddlMats_select dsel 
            )
        )
        
        fn GetGlowItemText glowId = (
            local spos = formattedPrint positions[glowId] format:".1f" userLocale:true
                
            local ss = stringstream ""
            
            local mat = (
                if classof $.mat == Multimaterial then (
                    local matId = matIds[glowId]
                    $.mat[matId]
                )
                else $.mat 
            )
            
            local matName = ""
            if mat != undefined then (
                matName = mat.name
            )
                            
            format "% | % | %" glowId matName spos to:ss
            
            ss as string
        )

        on btnAdd pressed do (
            append matIds 0
            append positions 0.0
            append unknowns 1.0
           
            local items = lstGlows.items
            local glowId = items.count + 1
            append items (GetGlowItemText glowId)

            lstGlows.items = items 
            lstGlows_select glowId
            
            ddlMats_select ddlMats.items.count
        )

        on btnRemove pressed do (
            local glowId = lstGlows.selection
            if glowId != 0 then (
                local items = lstGlows.items
                deleteItem items glowId
                deleteItem matIds glowId
                deleteItem positions glowId
                deleteItem unknowns glowId

                lstGlows.items = items

                if glowId > items.count then lstGlows_select items.count
                else lstGlows_select glowId
            )
        )
        
        fn BuildMatItems mat = (
            local items = #()
            itemMatIds = #()
            if mat != undefined then (
                if classof mat == multimaterial then (
                    for i = 1 to mat.numsubs do (
                        local submat = mat[i]
                        if submat != undefined then (
                            append items (i as string + " -  " + submat.name)
                            append itemMatIds i
                        )
                    )
                )
                else (
                    append items ("1 -  " + mat.name)
                    append itemMatIds 1
                )
            )
            
            items
        )
        
        fn GetPreviewBitmap mat = (
            --print "GetPreviewBitmap"
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
                
                if map != undefined and classof map == Bitmaptexture then (
                    --try (bmp = map.bitmap) catch()  --texture map could have no filename set
                    local maxver = (maxVersion())[1]
                    if maxVer >= 19000 then local scl = GetUIScaleFactor()
                    else local scl = 1
                    bmp = renderMap map size:[40*scl,40*scl] filter:true
                )
            )
            
            bmp
        )
        
        fn lstGlows_select glowId = (
            lstGlows.selection = glowId
            if glowId != 0 and glowId <= lstGlows.items.count then (
                local itemId = findItem itemMatIds matIds[glowId] 
                ddlMats_select itemId
                
                spnPosition.value = positions[glowId]
                spnUnknown.value = unknowns[glowId]
                
                ddlMats.enabled = true
                spnPosition.enabled = true
                spnUnknown.enabled = true
            )
            else (
                ddlMats.enabled = false
                spnPosition.enabled = false
                imgMat.bitmap = undefined
                spnUnknown.enabled = false                
            )
        )

        on lstGlows selected glowId do lstGlows_select glowId
        
        fn RefreshGlowText glowId = (
            local items = lstGlows.items
            items[glowId] = GetGlowItemText glowId
            lstGlows.items = items
        )

        on spnPosition changed val do (
            local glowId = lstGlows.selection
            if glowId != 0 then (
                positions[glowId] = val
                
                RefreshGlowText glowId
            )
        )
        
        on spnUnknown changed val do (
            local glowId = lstGlows.selection
            if glowId != 0 then (
                unknowns[glowId] = val
            )
        )
        
        fn GetGlowMaterial glowId = (
            if classof $.mat == Multimaterial then (
                local matId = matIds[glowId]
                $.mat[matId]
            )
            else $.mat
        )
        
        fn ddlMats_select sel = (
            --after selecting material update preview
            ddlMats.selection = sel
            if sel != 0 and sel <= ddlMats.items.count then (
                ddlMats.tooltip = ddlMats.selected
                
                --get material from selection id
                local glowId = lstGlows.selection
                matIds[glowId] = itemMatIds[sel]
                local mat = GetGlowMaterial glowId
                
                RefreshGlowText glowId
                
                
                imgMat.bitmap = GetPreviewBitmap mat  
            )
            else imgMat.bitmap = undefined
        )
        
        on ddlMats selected sel do ddlMats_select sel

        fn OnMatAdded scope: = (
            scope.tmrCooldown.active = true
        )
        
        on rltGlow open do (
            imgMat.bitmap = undefined
            
            --Create material items
            if $ != undefined then
                ddlMats.items = BuildMatItems $.mat
            
                
            --Events
            local events = ::Max4ds_Events
            events.AddHandler #mtlRefAdded OnMatAdded scope:rltGlow
            
            --Add glow items
            local items = #()
            for glowId = 1 to matIds.count do (                
                append items (GetGlowItemText glowId)
            )
            lstGlows.items = items
            
            --Restore selection
            if savedSel == undefined then savedSel = items.count

            --call on selected
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
        on mousePoint click do (
            nodeTM.translation = gridPoint;#stop
        )
    )
    
    local afterCreate = false
    
    on create do (
        --format "on create\n"
        afterCreate = true
    )
    
    on attachedToNode node do (
        --format "on attachedToNode\n"
        
        if afterCreate then (
            node.wirecolor = color 248 128 0
            node.boxmode = true
            node.renderable = false
        )
        
        afterCreate = false
    )
    
    on update do (
        if unknowns.count != positions.count then (
            unknowns[positions.count] = 1.0
        )
        --format "on update\n"
    )
    
    on load do (
        --format "on load\n"
    )
)
