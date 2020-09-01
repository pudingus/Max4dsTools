plugin SimpleObject M4dsGlow
name:"4ds Glow"
classID:#(0x4ec442f4, 0x6cf47395)
category:"4dsTools"
(
    parameters pblock
    (
        matIds type:#intTab tabSizeVariable:true
        positions type:#floatTab tabSizeVariable:true
    )
    parameters pblock2 rollout:GlowViewportRoll
    (
        viewportSize type:#float default:1 ui:spnSize
    )
    local savedSel = 0

    rollout GlowRoll "Glow Parameters"
    (
        button btnAdd "Add" across:2 align:#left width:50
        button btnRemove "Remove" align:#right width:70
        listbox lstGlows ""


        imgTag imgMat "Material preview:" width:48 height:48 opacity:1.0 transparent:white align:#left across:2
        dropdownlist ddlMats  width:80 align:#right enabled:false 
        spinner spPosition "Offset" type:#float align:#left range:[-900000,900000,0] width:70 pos:[70,205] enabled:false

        local lstGlows_select

        on btnAdd pressed do (
            local items = lstGlows.items

            append items ("Glow " + ((items.count+1) as string))

            append matIds 0
            append positions 0.0

            lstGlows.items = items            

            lstGlows_select items.count
        )

        on btnRemove pressed do (
            local sel = lstGlows.selection
            if sel != 0 then (
                local items = lstGlows.items
                deleteItem items sel
                deleteItem matIds sel
                --deleteItem materials sel
                deleteItem positions sel

                lstGlows.items = items

                if sel > items.count then lstGlows_select items.count
                else lstGlows_select sel
            )

        )

        fn lstGlows_select sel = (
            lstGlows.selection = sel
            if sel != 0 and sel <= lstGlows.items.count then (
                local items = #()
                
                if $.mat != undefined then (
                    if classof $.mat == multimaterial then (
                        for i = 1 to $.mat.numsubs do (
                            local mat = $.mat[i]
                            local name
                            if mat == undefined then name = "undefined"
                            else name = mat.name
                                                
                            --append items ((i as string) + ": " + name)
                            append items name
                        )
                    )
                    else append items $.mat.name
                )
                
                ddlMats.items = items  
            
                ddlMats.enabled = true
                spPosition.enabled = true

                local pos = positions[sel]
				local mat
				if $.mat != undefined then mat = $.mat[matIds[sel]]

                if pos != undefined then (
                    spPosition.value = positions[sel]
                )

                ddlMats.selection = matIds[sel]

				imgMat.bitmap = undefined
			
				if mat != undefined then (
					local map
					local class = classOf mat
					if class == MafMat4 or class == Standard then (
						map = mat.diffuseMap
					)
					else if class == PhysicalMaterial then (
						map = mat.base_color_map
					)
					
					if map != undefined then (
						imgMat.bitmap = map.bitmap
					)                
				)
            )
            else (
                ddlMats.enabled = false
                spPosition.enabled = false
                imgMat.bitmap = undefined
            )
        )

        on lstGlows selected sel do lstGlows_select sel

        on spPosition changed val do (
            local sel = lstGlows.selection
            if sel != 0 then (
                positions[sel] = val
            )
        )
        
        on ddlMats selected sel do (
            
            ddlMats.tooltip = ddlMats.selected
            print "selected"
            
            local gsel = lstGlows.selection
            
            matIds[gsel] = sel
            
            local mat = $.mat[sel]
            
			imgMat.bitmap = undefined
			
            if mat != undefined then (
				local map
				local class = classOf mat
				if class == MafMat4 or class == Standard then (
					map = mat.diffuseMap
				)
				else if class == PhysicalMaterial then (
					map = mat.base_color_map
				)
				
				if map != undefined then (
					imgMat.bitmap = map.bitmap
				)                
            )
        )

        on GlowRoll open do (
            local count = matIds.count

            local items = #()
            for i = 1 to count do (
                append items ("Glow " + (i as string))
            )
            lstGlows.items = items

            lstGlows_select savedSel
            
            
            local items = #()
            print "open"
            print selection.count
        )

        on GlowRoll close do (
            savedSel = lstGlows.selection
            --imgMat.bitmap = undefined
        )
    )
    rollout GlowViewportRoll "Viewport" (
        spinner spnSize "Viewport size: " type:#float range:[0,90000,0]       
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
            $.wirecolor = color 248 128 0
            $.boxmode = true
            $.renderable = false
            
            local multi = multimaterial()
            for i = 1 to multi.numsubs do (
                multi[i] = undefined
            )          
            $.material = multi
            nodeTM.translation = gridPoint;#stop            
        )
    )
)
