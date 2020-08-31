(
    local destroyed = false
    if ::ImpExp != undefined and ::ImpExp.open then (
        DestroyDialog ::ImpExp
        destroyed = true
    )
    
    struct settings (
        importPath,
        exportPath,
        exportFilename,
        position,
        editNorm,
        cachedNorm,
        unitsSel = 2
    )
    global MafiaTools_ImpExpSettings
    if MafiaTools_ImpExpSettings == undefined then MafiaTools_ImpExpSettings = settings()

    rollout ImpExp "4ds Import/Export" (
        local unitItems = #(
			"Milimeters",
			"Centimeters",
			"Decimeters",
			"Meters",
			"Kilometers",
			"Inches",
			"Feet",
			"Yards",
			"Miles"			
        )
        
        local unitMeterRatios = #(     --  n * (1/ratio) for import, n * ratio for export
            0.001,     
            0.01,     --1cm = 0.01m
            0.1,
            1.0,
            1000.0,   --1km = 1000m
            0.0254,   --1in = 0.0254m
            0.3048,
            0.9144,
            1609.344
        )
        
        local settings = ::MafiaTools_ImpExpSettings
        
        label lblUnits "Units:" offset:[0,3] align:#left across:2
        dropdownList ddlUnits    align:#right width:160  items:unitItems height:11 selection:settings.unitsSel
        
        group "Import" (
            label       lblUnitSclI     "Scale factor:" align:#left across:2
            label       lblSclI         "" align:#right
            button		btnImport		"Import..." align:#left across:2 width:70
            button      btnOpen			"Open..." align:#right width:70
        )

        group "Export" (
            label       lblUnitSclE     "Scale factor:" align:#left across:2
            label       lblSclE         "" align:#right
            checkbox    cbCachedNorm    "Cached normals" checked:true
            checkbox    cbEditNorm      "Edit Normals modifier" checked:true
            edittext    edtNamePath    align:#left offset:[0,10]  text:"" width:200
            edittext    edtName        align:#left  text:"" width:200
            button      btnBrowse       "Browse..." align:#left across:2 width:70
            button      btnExport       "Export" align:#right width:70
        )
        timer       clock   interval:5000 active:false
        label       labelDone         "" offset:[0,10]
        
        fn ddlUnits_select sel = (
            lblSclI.text = (1/unitMeterRatios[sel]) as string
            lblSclE.text = unitMeterRatios[sel] as string
        )
        
        on ddlUnits selected sel do ddlUnits_select sel    
        
        fn StartImport del:false = (
            local proceed = true
            if del then (
                proceed = CheckForSave()
            )
    
            if proceed then (
                local prev_name = MafiaTools_ImpExpSettings.importPath
                if prev_name == undefined then prev_name = ""
                local file = getOpenFileName types:"4DS models (*.4ds)|*.4ds|All files (*.*)|*.*" historyCategory:"4dsImport" filename:prev_name
                if file != undefined then (
                    local util = ::MafiaTools_Util
                    local layers = ::MafiaTools_Layers
                    local imp = MafiaTools_4dsImport()
                    MafiaTools_ImpExpSettings.importPath = file
                    labelDone.text = "Importing..."
                    if del then (
                        delete $*
                        layers.Clear()
                        gc()                    
                    )
                    local sel = ddlUnits.selection
                    local unitscl = 1 / unitMeterRatios[sel]
                    local dur = imp.Import4ds file unitscl  
                    
                    labelDone.text = "Done in " + (dur as string) + " seconds"
                    clock.active = true
                )
            )
        )

        on btnImport pressed do (
            StartImport del:false
        )

        on btnOpen pressed do (
            StartImport del:true
        )

        on btnBrowse pressed do (
            local file = getSaveFileName types:"4DS file (*.4ds)|*.4ds|All files (*.*)|*.*" historyCategory:"4dsExport"
            if file != undefined then (

                edtNamePath.text = getFilenamePath file
                edtName.text = filenameFromPath file
            )
        )

        on btnExport pressed do (
            local path = getFilenamePath edtNamePath.text

            if doesDirectoryExist path then (
                local exp = MafiaTools_4dsExport()
                local filepath = pathConfig.appendPath path edtName.text
                labelDone.text = "Exporting..."
                local sel = ddlUnits.selection
                local unitscl = unitMeterRatios[sel]
                local dur = exp.Export4ds filepath cbCachedNorm.checked cbEditNorm.checked unitscl
                labelDone.text = "Done in " + (dur as string) + " seconds"
                clock.active = true
            )

        )
        on clock tick do (
            labelDone.text = ""
            clock.active = false
        )

        on ImpExp open do (
            local settings = ::MafiaTools_ImpExpSettings
            
            if settings.exportPath != undefined then (
                edtNamePath.text = settings.exportPath
            )
            if settings.exportFilename != undefined then (
                edtName.text = settings.exportFilename
            )
            if settings.exportFilename != undefined then (
                edtName.text = settings.exportFilename
            )
            if settings.cachedNorm != undefined then (
                cbCachedNorm.checked = settings.cachedNorm
            )            
            if settings.editNorm != undefined then (
                cbEditNorm.checked = settings.editNorm
            )
            ddlUnits_select settings.unitsSel
        )

        on ImpExp close do (
            local settings = ::MafiaTools_ImpExpSettings
            print "close"
            settings.exportPath = edtNamePath.text
            settings.exportFilename = edtName.text
            settings.position = GetDialogPos ImpExp
            settings.cachedNorm = cbCachedNorm.checked
            settings.editNorm = cbEditNorm.checked
            settings.unitsSel = ddlUnits.selection
        )
    )

    if not destroyed then (
        local pos = ::MafiaTools_ImpExpSettings.position
        local style = #(#style_titlebar, #style_border, #style_sysmenu)
        local w = 220
        local h = 310
        if pos != undefined then (
            CreateDialog ImpExp w h pos.x pos.y style:style
        )
        else (
            CreateDialog ImpExp w h style:style
        )
    )
)