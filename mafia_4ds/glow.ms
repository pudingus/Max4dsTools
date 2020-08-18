plugin geometry M4dsGlow
name:"4ds Glow"
classID:#(0x4ec442f4, 0x6cf47395)
category:"4dsTools"
extends:Box
replaceUI:true
(
    parameters pblock rollout:GlowRoll
    (
        materials type:#materialTab tabSizeVariable:true
        positions type:#floatTab tabSizeVariable:true
    )
	local savedSel = 1
	
    rollout GlowRoll "Glow Parameters"
    (        
        button btnAdd "Add" across:2 align:#left width:50
        button btnRemove "Remove" align:#right width:70
        listbox lbGlows ""
        
		
		imgTag imgMat "Material preview:" width:48 height:48 opacity:1.0 transparent:white align:#left across:2     
		materialButton mbMat "Material" width:80 align:#right
		spinner spPosition "Offset" type:#float align:#left range:[-900000,900000,0] width:70 pos:[70,205]
		
		on btnAdd pressed do (
			local items = lbGlows.items
			
			append items ("Glow " + ((items.count+1) as string))
			
			append materials undefined
			append positions 0.0
			
			lbGlows.items = items
		)
		
		on btnRemove pressed do (
			local sel = lbGlows.selection
			if sel != 0 then (
				local items = lbGlows.items
                deleteItem items sel
                deleteItem materials sel
                deleteItem positions sel
				
				lbGlows.items = items
			)
			
		)
		
		on lbGlows selected sel do (
			spPosition.value = positions[sel]
			mbMat.material = materials[sel]
			savedSel = sel
			
			imgMat.bitmap = materials[sel].diffuseMap.bitmap
		)
		
		on spPosition changed val do (
			local sel = lbGlows.selection
			if sel != 0 then (				
				positions[sel] = val
			)
		)
		
		on mbMat picked mtl do (
			mbMat.material = mtl
			local sel = lbGlows.selection
			if sel != 0 then (				
				materials[sel] = mtl
			)			
        )
		
		on GlowRoll open do (			
			local count = materials.count
			
			local items = #()
			for i = 1 to count do (
				append items ("Glow " + (i as string))
			)
            lbGlows.items = items            
            
			lbGlows.selection = savedSel
			
			spPosition.value = positions[savedSel]
			mbMat.material = materials[savedSel]
			imgMat.bitmap = materials[savedSel].diffuseMap.bitmap
        )
    )
    tool create
    (
        on mousePoint click do
        (		
            $.wirecolor = color 248 128 0
			$.boxmode = true
			$.renderable = false			
            nodeTM.translation = gridPoint;#stop				
        )
    )
    
    on create do (
        delegate.width = delegate.length = delegate.height = 0.1
    )
)