(
    local destroyed = false
    if ImpExp != undefined and ImpExp.open then (
        DestroyDialog ImpExp
        destroyed = true
    )
    
    global MafiaTools_ExportPath
    global ImpExp
    local imp = MafiaTools_Import4ds()
	local exp = MafiaTools_Export4ds()

    rollout ImpExp "4ds Import/Export" (
        checkbox    importNormalsD    "Import normals" enabled:false checked:true    
        checkbox    importNormals     "Normals to modifier (slow)"
        button      btnImport         "Import..." align:#left

        label       aa                "Export normals:" offset:[0,20] 
        checkbox    en1               "Smoothing groups" checked:true enabled:false
        checkbox    en2               "Cached normals"
        checkbox    en3               "Edit Normals modifier"
        edittext    editName          align:#left offset:[0,10]  text:"" width:200
        button      btnBrowse         "Browse..." align:#left across:3
        label       labelDone         ""
        button      btnExport         "Export" align:#right
        timer       clock   interval:4000 active:false
        
        on btnImport pressed do
        (		
            local file = getOpenFileName types:"4DS models (*.4ds)|*.4ds|All files (*.*)|*.*" historyCategory:"4dsImport"
            if file != undefined then (
                --progressStart "4ds Importing"
                imp.Import4ds file
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
                --progressStart "4ds Exporting"   
                labelDone.text = ". . ."  
                exp.Export4ds editName.text      
                labelDone.text = "Done!"    
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
        )
    )
    
    if not destroyed then (
        CreateDialog ImpExp 220 300 style:#(#style_resizing, #style_titlebar, #style_border,#style_sysmenu)
        
    )

   

)