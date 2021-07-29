-- (
--     local events = ::Max4ds_Events
--     events.RemoveHandler #systemPostNew ::Max4ds_ImpExp.PostReset
--     events.RemoveHandler #systemPostReset ::Max4ds_ImpExp.PostReset
--     events.RemoveHandler #filePreSave ::Max4ds_ImpExp.PreSave
-- )

(
    if ::Max4ds_ImpExp != undefined then (
        DestroyDialog ::Max4ds_ImpExp.rltImpExp
    )
)

rollout Max4ds_ImpExp "" (  --module
    
    local impExpAttr = attributes impExpAttr
    attribID:#(0x5fae4469, 0x55578fab)
    (
        parameters main (
            vversion type:#integer default:1
            hasAnimFile type:#boolean default:false
            units type:#integer default:1
            filename type:#string default:""
        )
    )
    

    local settings = (
        struct settings (
            importPath,
            exportPath = "",
            exportFilename = "",
            position,
            unitsSel = 1,
            useImportedFilename = false,
            allow5ds = false,
            versionSel = 1
        )
        settings()
    ) 
    
    local rltImpExp
    
    fn PostReset scope: = (
        scope.settings.useImportedFilename = false
        scope.settings.allow5ds = false
        scope.rltImpExp.cbAllow5ds.checked = false
        
        scope.rltImpExp.edtFilename.text = ""
        scope.settings.exportFilename = ""
    )
    
    fn PreSave scope: = (
        custAttributes.add rootNode scope.impExpAttr
        local attr = custAttributes.get rootNode scope.impExpAttr
        
        if scope.rltImpExp.isDisplayed then (
            attr.hasAnimFile = scope.rltImpExp.cbAllow5ds.checked
            attr.vversion = scope.rltImpExp.ddlVersion.selection
            attr.units = scope.rltImpExp.ddlUnits.selection
            attr.filename = scope.rltImpExp.edtFilename.text
        )
        else (
            attr.hasAnimFile = scope.settings.allow5ds
            attr.vversion = scope.settings.versionSel       
            attr.units = scope.settings.unitsSel
            attr.filename = scope.settings.exportFilename
        )        
    )
    
    fn PostOpen scope: = (
        local attr = custAttributes.get rootNode scope.impExpAttr
        
        if attr != undefined then (
            if scope.rltImpExp.isDisplayed then (
                scope.rltImpExp.cbAllow5ds.checked = attr.hasAnimFile
                scope.rltImpExp.ddlVersion.selection = attr.vversion
                scope.rltImpExp.ddlUnits.selection = attr.units
                scope.rltImpExp.ddlUnits_select attr.units
                scope.rltImpExp.edtFilename.text = attr.filename
            )
            else (
                scope.settings.allow5ds = attr.hasAnimFile
                scope.settings.versionSel = attr.vversion
                scope.settings.unitsSel = attr.units
                scope.settings.exportFilename = attr.filename
            )
        )
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
            local h = 380
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
            "Auto ()",      --1
            "Millimeters",   --2
            "Centimeters",  --3
            "Decimeters",   --4
            "Meters",       --5
            "Kilometers",   --6
            "Inches",       --7
            "Feet",         --8
            "Yards",        --9
            "Miles"         --10
        )

        local unitMeterRatios = #(     --  n * (1/ratio) for import, n * ratio for export
            -1,         --auto
            0.001,      --mm
            0.01,       --1cm = 0.01m
            0.1,        --dm
            1.0,        --m
            1000.0,     --1km = 1000m
            0.0254,     --1in = 0.0254m
            0.3048,     --feet
            0.9144,     --yards
            1609.344    --miles
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
            checkbox    cbAllow5ds      "Has animation file" align:#left offset:[0,5]
            dropdownlist ddlVersion     "Version:" items:versionItems selection:settings.versionSel
            
            edittext    edtDirectory    "Directory:" align:#left offset:[0,5]  text:settings.exportPath labelOnTop:true
            edittext    edtFilename     "Filename:" align:#left  text:settings.exportFilename labelOnTop:true
            button      btnBrowse       "Browse..." align:#left width:70 across:2 
            button      btnExport       "Export" align:#right width:70
        )
        timer       clock   interval:5000 active:false
        progressBar prgProgress offset:[0,5]
        label       labelDone         "" 

        fn GetSystemUnits = (
            local sysType = units.SystemType
            local sysScale = units.SystemScale
            
            local scale = case sysType of (
                #inches:    0.0254
                #feet:      0.3048
                #miles:     1609.344
                #millimeters:   0.001
                #centimeters:   0.01
                #meters:        1.0
                #kilometers:    1000.0
            )
            
            scale * sysScale
        )
        
        fn ddlUnits_select sel = (
            if sel == 1 then ( --auto
                local scale = GetSystemUnits()
            )
            else (
                local scale = unitMeterRatios[sel]
            )
            
            lblSclI.text = (1/scale) as string
            lblSclE.text = scale as string
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
                    if sel == 1 then ( --auto
                        local unitscl = 1 / GetSystemUnits()
                    )
                    else (
                        local unitscl = 1 / unitMeterRatios[sel]
                    )
                
                    local allow5ds = imp.Import4ds file unitscale:unitscl progHandler:OnProgress
                    
                    clock.active = true
                    
                    setfocus ::Max4ds_ImpExp.rltImpExp
                    
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
                    clock.active = false
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
                    if sel == 1 then ( --auto
                        local unitscl = GetSystemUnits()
                    )
                    else (
                        local unitscl = unitMeterRatios[sel]
                    )
                    
                    local version = case ddlVersion.selection of (
                        1: #mafia
                        2: #hd2
                        3: #chameleon
                    )
                    local expSettings = 
                        exp.TSettings \
                            allow5ds:cbAllow5ds.checked \
                            version:version
                    
                    local maxver = (maxVersion())[1]
                    if maxVer >= 20000 do UpdateSceneMaterialLib()
                    
                    exp.Export4ds filepath settings:expSettings unitscale:unitscl progHandler:OnProgress
                    clock.active = true
                    
                    setfocus ::Max4ds_ImpExp.rltImpExp
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
        
        fn OnUnitsChange scope: = (
            format "units change \n"
                        
            local scale = scope.GetSystemUnits()
            
            local id = findItem scope.unitMeterRatios scale
            
            if id > 0 then (
                scope.unitItems[1] = "Auto (" + scope.unitItems[id] + ")"
            )
            else (
                scope.unitItems[1] = "Auto (" + (scale as string) + ")"
            )
            
            scope.ddlUnits.items = scope.unitItems
            
            if scope.ddlUnits.selection == 1 then ( --auto
                scope.lblSclI.text = (1/scale) as string
                scope.lblSclE.text = scale as string
            )
        )

        on rltImpExp open do (
            
            if settings.allow5ds != undefined then (
                cbAllow5ds.checked = settings.allow5ds
            )
            ddlUnits_select settings.unitsSel
            
            
            local scale = GetSystemUnits()
            
            local id = findItem unitMeterRatios scale
            
            if id > 0 then (
                unitItems[1] = "Auto (" + unitItems[id] + ")"
            )
            else (
                unitItems[1] = "Auto (" + (scale as string) + ")"
            )
            
            ddlUnits.items = unitItems
            
            ddlUnits.enabled = ddlUnits.enabled
            
            local events = ::Max4ds_Events
            events.AddHandler #unitsChange OnUnitsChange scope:rltImpExp
        )

        on rltImpExp close do (
            local events = ::Max4ds_Events
            events.RemoveHandler #unitsChange OnUnitsChange
            
            --print "close"
            settings.exportPath = edtDirectory.text
            settings.exportFilename = edtFilename.text
            settings.position = GetDialogPos rltImpExp
            settings.unitsSel = ddlUnits.selection	
            settings.allow5ds = cbAllow5ds.checked
            settings.versionSel = ddlVersion.selection
        )
        
        -- on cbAllow5ds changed val do (
        --     format "checked\n"
        -- )
    )
)

-- not using event.ms because handlers could not be removed in this case
callbacks.removeScripts id:#Max4ds_ImpExp
callbacks.addScript #systemPostNew "::Max4ds_ImpExp.PostReset scope:::Max4ds_ImpExp" id:#Max4ds_ImpExp
callbacks.addScript #systemPostReset "::Max4ds_ImpExp.PostReset scope:::Max4ds_ImpExp" id:#Max4ds_ImpExp
callbacks.addScript #filePreSave "::Max4ds_ImpExp.PreSave scope:::Max4ds_ImpExp" id:#Max4ds_ImpExp
callbacks.addScript #filePostOpen "::Max4ds_ImpExp.PostOpen scope:::Max4ds_ImpExp" id:#Max4ds_ImpExp

-- (
--     local events = ::Max4ds_Events
--     events.AddHandler #systemPostNew ::Max4ds_ImpExp.PostReset scope:::Max4ds_ImpExp
--     events.AddHandler #systemPostReset ::Max4ds_ImpExp.PostReset scope:::Max4ds_ImpExp
        
--     events.addHandler #filePreSave ::Max4ds_ImpExp.PreSave scope:::Max4ds_ImpExp
-- )

::Max4ds_ImpExp.PostOpen scope:::Max4ds_ImpExp