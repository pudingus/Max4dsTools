(
    local destroyed = false
    if ImpExp != undefined and ImpExp.open then (
        DestroyDialog ImpExp
        destroyed = true
    )
    
    global MafiaTools_ImportPath
    global MafiaTools_ExportPath
    global MafiaTools_ImpExpPos
    global ImpExp
    local imp = MafiaTools_Import4ds()
	local exp = MafiaTools_Export4ds()

    rollout ImpExp "4ds Import/Export" (
        group "Import" (
        --checkbox    importNormalsD    "Import normals" enabled:false checked:true    
        --checkbox    importNormals     "Normals to modifier (slow)"
        button      btnImport         "Import..." align:#left across:2
        button      btnOpen        "Open..." align:#left
        )
        
        group "Export" (
            label       aa                "Normals:" align:#left
            --checkbox    en1               "Smoothing groups" checked:true enabled:false
            checkbox    en2               "Cached normals"
            checkbox    en3               "Edit Normals modifier"
            edittext    editName          align:#left offset:[0,10]  text:"" width:200
            button      btnBrowse         "Browse..." align:#left across:2
            
            button      btnExport         "Export" align:#right
            
        )
        timer       clock   interval:5000 active:false
        
        label       labelDone         "" offset:[0,10]
        
        on btnImport pressed do
        (		
            local prev_name = MafiaTools_ImportPath
            if prev_name == undefined then prev_name = ""
            local file = getOpenFileName types:"4DS models (*.4ds)|*.4ds|All files (*.*)|*.*" historyCategory:"4dsImport" filename:prev_name
            if file != undefined then (
                --progressStart ""
                labelDone.text = "Importing..."
                local dur = imp.Import4ds file
                MafiaTools_ImportPath = file
                labelDone.text = "Done in " + (dur as string) + " seconds"
                clock.active = true  
                --progressEnd()
            )	
        )
        
        on btnBrowse pressed do (
            local file = getSaveFileName types:"4DS file (*.4ds)|*.4ds|All files (*.*)|*.*" historyCategory:"4dsExport"
            if file != undefined then (
                editName.text = file
            )
        )
        

        on btnExport pressed do
        (		
            if doesDirectoryExist (getFilenamePath editName.text) then (
                --progressStart ""                
                labelDone.text = "Exporting..."  
                local dur = exp.Export4ds editName.text      
                labelDone.text = "Done in " + (dur as string) + " seconds"
                clock.active = true  
                --progressEnd()        
            )
           
        )
        on clock tick do (
            labelDone.text = "" 
            clock.active = false
        )
        
        on ImpExp open do (
			if MafiaTools_ExportPath != undefined then (				
				editName.text = MafiaTools_ExportPath
            )
            
        )
        
        on ImpExp close do (
            MafiaTools_ExportPath = editName.text
            MafiaTools_ImpExpPos = GetDialogPos ImpExp
        )
    )
    
    if not destroyed then (
        local pos = MafiaTools_ImpExpPos
        local style = #( #style_titlebar, #style_border,#style_sysmenu) 
        if pos != undefined then (
            CreateDialog ImpExp 220 230 pos.x pos.y style:style        
        )
        else (
            CreateDialog ImpExp 220 230 style:style
            
        )
        
    )

   

)