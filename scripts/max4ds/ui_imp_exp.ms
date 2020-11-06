(
    local destroyed = false
    if ::ImpExp != undefined and ::ImpExp.isDisplayed then (
        DestroyDialog ::ImpExp
        destroyed = true
    )

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
        local util = ::MafiaTools_Util

        label lblUnits "Units:" offset:[0,3] align:#left across:2
        dropdownList ddlUnits    align:#right width:140  items:unitItems height:11 selection:settings.unitsSel

        group "Import" (
            label       lblUnitSclI     "Scale factor:" align:#left across:2
            label       lblSclI         "" align:#right
            button      btnImport       "Import..." align:#left across:2 width:70
            button      btnOpen         "Open..." align:#right width:70
        )

        group "Export" (            
            label       lblUnitSclE     "Scale factor:" align:#left across:2
            label       lblSclE         "" align:#right
            checkbox    cbCachedNorm    "Cached normals" checked:true
            checkbox    cbEditNorm      "Edit Normals modifier" checked:true
            checkbox    cbAllow5ds      "Has animation file" align:#left offset:[0,5]
            edittext    edtDirectory    "Directory:"   align:#left offset:[0,5]  text:""labelOnTop:true
            edittext    edtFilename     "Filename:"      align:#left  text:"" labelOnTop:true
            button      btnBrowse       "Browse..." align:#left width:70 across:2 
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
            local settings = ::MafiaTools_ImpExpSettings
            local proceed = true
            if del then (
                proceed = CheckForSave()
            )

            if proceed then (
                local prev_name = settings.importPath
                if prev_name == undefined then prev_name = ""
                local file = getOpenFileName types:"4ds Model (*.4ds)|*.4ds|All files (*.*)|*.*" historyCategory:"4dsImport" filename:prev_name
                if file != undefined then (
                    local layers = ::MafiaTools_Layers
                    local imp = ::MafiaTools_4dsImport
                    settings.importPath = file
                    settings.useImportedFilename = true
                    labelDone.text = "Importing..."
                    if del then (
                        if numsubobjectlevels != undefined then subobjectlevel = 0
                        --setCommandPanelTaskMode #create
                        delete $*
                        layers.Clear()
                        gc()
                    )
                    local sel = ddlUnits.selection
                    local unitscl = 1 / unitMeterRatios[sel]
                    local result = imp.Import4ds file unitscl
                    
                    if result != undefined then (
                        local dur = result[1]
                        local allow5ds = result[2]
                        
                        if del then (
                            cbAllow5ds.checked = allow5ds
                        )
                        else (
                            if cbAllow5ds.checked == false then cbAllow5ds.checked = allow5ds
                        )

                        labelDone.text = "Done in " + (dur as string) + " seconds"
                        clock.active = true
                    )
                    else labelDone.text = ""
                )
            )
        )

        on btnImport pressed do (
            StartImport del:false
        )

        on btnOpen pressed do (
            StartImport del:true
        )
        
        on edtFilename changed val do (
            local settings = ::MafiaTools_ImpExpSettings
            settings.useImportedFilename = false
        )

        on btnBrowse pressed do (
            local settings = ::MafiaTools_ImpExpSettings
            
            local filename            
            if settings.useImportedFilename and settings.importPath != undefined then (
                filename = getFilenameFile settings.importPath
            )
            else (
                filename = edtFilename.text
            )            
            
            if util.isStringEmpty filename then (
                filename = getfilenamefile maxFilename
                if util.isStringEmpty filename then (
                    filename = ""
                )
            )           
        
            local file = getSaveFileName types:"4ds Model (*.4ds)|*.4ds|All files (*.*)|*.*" historyCategory:"4dsExport" filename:filename
            if file != undefined then (
                edtDirectory.text = getFilenamePath file
                edtFilename.text = filenameFromPath file
                settings.useImportedFilename = false
            )
        )

        on btnExport pressed do (
            local dir = edtDirectory.text

            if doesFileExist dir then (
                local exp = ::MafiaTools_4dsExport
                local filename = edtFilename.text
                if util.isStringEmpty filename then (
                    messageBox "Provide a filename."
                )
                else (
                    local ext = ".4ds"
                    if filename.count < ext.count then (
                        append filename ext
                    )
                    else (
                        local sub = substring filename (filename.count-3) 4                        
                        if toLower sub != ext then append filename ext                        
                    )
                    
                    local filepath = pathConfig.appendPath dir filename
                    labelDone.text = "Exporting..."
                    local sel = ddlUnits.selection
                    local unitscl = unitMeterRatios[sel]
                    local dur = exp.Export4ds filepath cbCachedNorm.checked cbEditNorm.checked unitscl cbAllow5ds.checked
                    labelDone.text = "Done in " + (dur as string) + " seconds"
                    clock.active = true
                )
            )
            else (
                messageBox "Specified directory doesn't exist."
            )
        )
        on clock tick do (
            labelDone.text = ""
            clock.active = false
        )

        on ImpExp open do (
            local settings = ::MafiaTools_ImpExpSettings

            if settings.exportPath != undefined then (
                edtDirectory.text = settings.exportPath
            )
            if settings.exportFilename != undefined then (
                edtFilename.text = settings.exportFilename
            )
            if settings.exportFilename != undefined then (
                edtFilename.text = settings.exportFilename
            )
            if settings.cachedNorm != undefined then (
                cbCachedNorm.checked = settings.cachedNorm
            )
            if settings.editNorm != undefined then (
                cbEditNorm.checked = settings.editNorm
            )
            if settings.allow5ds != undefined then (
                cbAllow5ds.checked = settings.allow5ds
            )
            ddlUnits_select settings.unitsSel
        )

        on ImpExp close do (
            local settings = ::MafiaTools_ImpExpSettings
            --print "close"
            settings.exportPath = edtDirectory.text
            settings.exportFilename = edtFilename.text
            settings.position = GetDialogPos ImpExp
            settings.cachedNorm = cbCachedNorm.checked
            settings.editNorm = cbEditNorm.checked
            settings.unitsSel = ddlUnits.selection	
            settings.allow5ds = cbAllow5ds.checked
        )
    )

    if not destroyed then (
        local pos = ::MafiaTools_ImpExpSettings.position
        local style = #(#style_titlebar, #style_border, #style_sysmenu)
        local w = 200
        local h = 355
        if pos != undefined then (
            CreateDialog ImpExp w h pos.x pos.y style:style
        )
        else (
            CreateDialog ImpExp w h style:style
        )
    )
)