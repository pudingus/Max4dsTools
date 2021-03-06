rollout Max4ds_ImpExp "" (  --module
    
    local settings = (
        struct settings (
            importPath,
            exportPath,
            exportFilename,
            position,
            editNorm,
            cachedNorm,
            unitsSel = 4,
            useImportedFilename = false,
            allow5ds,
            versionSel = 1
        )
        settings()
    ) 
    
    local rltImpExp
    
    fn PostReset scope: = (
        scope.settings.useImportedFilename = false
        scope.settings.allow5ds = false
        scope.rltImpExp.cbAllow5ds.checked = false
    )
    
    fn Toggle = (
        local destroyed = false
        if rltImpExp != undefined and rltImpExp.isDisplayed then (
            DestroyDialog rltImpExp
            destroyed = true
        )
        
        
        if not destroyed then (
            local pos = settings.position
            local style = #(#style_titlebar, #style_border, #style_sysmenu)
            local w = 200
            local h = 420--395
            if pos != undefined then (
                CreateDialog rltImpExp w h pos.x pos.y style:style
            )
            else (
                CreateDialog rltImpExp w h style:style
            )
        )
    )

    rollout rltImpExp "4ds Import/Export" (
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
        
        local versionItems = #(
            "29 - Mafia",
            "41 - Hidden & Dangerous 2",
            "42 - Chameleon, WoW, CE"
        )
        
        local util = ::Max4ds_Util

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
            dropdownlist ddlVersion     "Version:" items:versionItems selection:settings.versionSel
            
            edittext    edtDirectory    "Directory:"   align:#left offset:[0,5]  text:""labelOnTop:true
            edittext    edtFilename     "Filename:"      align:#left  text:"" labelOnTop:true
            button      btnBrowse       "Browse..." align:#left width:70 across:2 
            button      btnExport       "Export" align:#right width:70
        )
        timer       clock   interval:5000 active:false
        progressBar prgProgress offset:[0,5]
        label       labelDone         "" 

        fn ddlUnits_select sel = (
            lblSclI.text = (1/unitMeterRatios[sel]) as string
            lblSclE.text = unitMeterRatios[sel] as string
        )

        on ddlUnits selected sel do ddlUnits_select sel
        
        fn OnProgress perc status = (
            labelDone.text = status
            prgProgress.value = perc
            progressUpdate perc
        )

        fn StartImport del:false = (
            local proceed = true
            if del then (
                proceed = CheckForSave()
            )

            if proceed then (
                local prev_name = settings.importPath
                if prev_name == undefined then prev_name = ""
                local file = getOpenFileName types:"4ds Model (*.4ds)|*.4ds|All files (*.*)|*.*" historyCategory:"4dsImport" filename:prev_name
                if file != undefined then (
                    local layers = ::Max4ds_Layers
                    local imp = ::Max4ds_4dsImport
                    settings.importPath = file
                    settings.useImportedFilename = true
                    if del then (
                        if numsubobjectlevels != undefined then subobjectlevel = 0
                        delete $*
                        layers.Clear()
                        local maxver = (maxVersion())[1]
                        if maxVer >= 20000 do UpdateSceneMaterialLib()
                        gc()
                    )
                    local sel = ddlUnits.selection
                    local unitscl = 1 / unitMeterRatios[sel]
                    local allow5ds = imp.Import4ds file unitscale:unitscl progHandler:OnProgress
                    
                    clock.active = true
                    
                    if allow5ds != undefined then (                        
                        if del then (
                            cbAllow5ds.checked = allow5ds
                        )
                        else (
                            if cbAllow5ds.checked == false then cbAllow5ds.checked = allow5ds
                        )
                    )
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
            settings.useImportedFilename = false
        )

        on btnBrowse pressed do (
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
                local exp = ::Max4ds_4dsExport
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
                    local sel = ddlUnits.selection
                    local unitscl = unitMeterRatios[sel]
                    local versionSel = 
                    local version = case ddlVersion.selection of (
                        1: #mafia
                        2: #hd2
                        3: #chameleon
                    )
                    local expSettings = 
                        exp.TSettings \
                            useCachedNormals:cbCachedNorm.checked \
                            useEditNormals:cbEditNorm.checked \
                            allow5ds:cbAllow5ds.checked \
                            version:version
                    
                    exp.Export4ds filepath settings:expSettings unitscale:unitscl progHandler:OnProgress
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

        on rltImpExp open do (
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

        on rltImpExp close do (
            --print "close"
            settings.exportPath = edtDirectory.text
            settings.exportFilename = edtFilename.text
            settings.position = GetDialogPos rltImpExp
            settings.cachedNorm = cbCachedNorm.checked
            settings.editNorm = cbEditNorm.checked
            settings.unitsSel = ddlUnits.selection	
            settings.allow5ds = cbAllow5ds.checked
            settings.versionSel = ddlVersion.selection
        )
    )
)

callbacks.removeScripts id:#Max4ds_ImpExp
callbacks.addScript #systemPostNew "::Max4ds_ImpExp.PostReset scope:::Max4ds_ImpExp" id:#Max4ds_ImpExp
callbacks.addScript #systemPostReset "::Max4ds_ImpExp.PostReset scope:::Max4ds_ImpExp" id:#Max4ds_ImpExp