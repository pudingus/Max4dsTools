global OnNodeRenamed
global OnSelectionChanged
global floater
global MafParamEditor
(
    --imports
    local util = ::MafiaTools_Util
    local containsItem = util.containsItem
    ---------

    local gp
    local EnabledMode
    local DisabledMode
    local OpenSelection
    local OnDeselected

    local visible = false

    rollout MafParamEditor "4ds Object Parameters"
    (
        timer timerDeselected interval:50 active:false

        on timerDeselected tick do (
            --format "DESELECTED!\n"
            timerDeselected.active = false
            OnDeselected()
        )

        label objectName "" align:#left
        button addParams "Add" align:#left pos:[10,25] tooltip:"Add parameters"
        button removeParams "Remove" align:#left pos:[50,25] tooltip:"Remove parameters"
        label objectTypeLabel "Object type:" across:2 offset:[0,3] align:#left
        dropdownlist objectType "" align:#left width:80  items:#("Dummy")

        on objectType selected i do (
            local strsel = objectType.items[i]

            if gp != undefined then gp.objectType = strsel

            OpenSelection strsel
        )

        on addParams pressed do (
            local obj = selection[1]
            if obj != undefined then (

                custAttributes.add obj MafParams_def baseObject:false
                gp = custAttributes.get obj MafParams_def baseObject:false

                local sel = objectType.selection
                local strsel = objectType.items[sel]

                gp.objectType = strsel

                if stricmp strsel "sector" == 0 then (
                    gp.cullFlags = 125
                )

                EnabledMode()
                MafParamEditor.objectType.selection = 1
                OpenSelection strsel
            )
        )

        on removeParams pressed do (
            local obj = selection[1]
            if obj != undefined then (

                if queryBox "Do you want to remove parameters from this object?" then (

                    custAttributes.delete obj MafParams_def baseObject:false

                    DisabledMode()
                    MafParamEditor.addParams.enabled = true
                )
            )
        )

        on MafParamEditor close do (
            --print "close"
            callbacks.removeScripts #selectionSetChanged id:#selChangedID
            callbacks.removeScripts #nodeRenamed id:#nodeRenamedID
        )
    )

    rollout rltObject ""
    (
        spinner renderFlags "Render flags:" range:[0,255,0] type:#integer align:#left fieldwidth:30 enabled:false across:2
        spinner renderFlags2 "" range:[0,255,0] type:#integer fieldwidth:30 enabled:false
        checkbox chkDepthBias "Depth bias" across:2
        checkbox chkShadowed "Shadowed"
        checkbox chkTexProj "Tex. proj." across:2 tooltip:"Texture projection"
        checkbox chkNoFog "No fog"

        spinner spnCullFlags "Culling flags:  " range:[0,255,0] offset:[0,10] type:#integer align:#left fieldwidth:50
        checkbox chkEnabled "" tooltip:"(1) Enabled" width:15 align:#left across:8 
        checkbox chkUnknown2 "" tooltip:"(2) Unknown" width:15 align:#left
        checkbox chkUnknown3 "" tooltip:"(3) Unknown" width:15 align:#left
        checkbox chkUnknown4 "" tooltip:"(4) Unknown" width:15 align:#left
        checkbox chkUnknown5 "" tooltip:"(5) Unknown" width:15 align:#left
        checkbox chkUnknown6 "" tooltip:"(6) Unknown" width:15 align:#left
        checkbox chkUnknown7 "" tooltip:"(7) Unknown" width:15 align:#left
        checkbox chkUnknown8 "" tooltip:"(8) Unknown" width:15 align:#left
        
        label paramsLabel "String params:" align:#left
        edittext strParams "" align:#left width:140 height:30

        on renderFlags changed val do (
            gp.renderFlags = val
        )

        on renderFlags2 changed val do (
            gp.renderFlags2 = val

            local flags = val

            chkDepthBias.checked = bit.get flags 1
            chkShadowed.checked = bit.get flags 2
            chkTexProj.checked = bit.get flags 6
            chkNoFog.checked = bit.get flags 8
        )

        on spnCullFlags changed val do (
            gp.cullFlags = val
            
            local cullFlags = gp.cullFlags
            
            chkEnabled.checked = bit.get cullFlags 1
            chkUnknown2.checked = bit.get cullFlags 2
            chkUnknown3.checked = bit.get cullFlags 3
            chkUnknown4.checked = bit.get cullFlags 4
            chkUnknown5.checked = bit.get cullFlags 5
            chkUnknown6.checked = bit.get cullFlags 6
            chkUnknown7.checked = bit.get cullFlags 7
            chkUnknown8.checked = bit.get cullFlags 8
        )

        on strParams changed val do (
            gp.strParams = val
        )

        on chkDepthBias changed val do (
            gp.renderFlags2 = bit.set gp.renderFlags2 1 val
            renderFlags2.value = gp.renderFlags2
        )

        on chkShadowed changed val do (
            gp.renderFlags2 = bit.set gp.renderFlags2 2 val
            renderFlags2.value = gp.renderFlags2
        )

        on chkTexProj changed val do (
            gp.renderFlags2 = bit.set gp.renderFlags2 6 val
            renderFlags2.value = gp.renderFlags2
        )

        on chkNoFog changed val do (
            gp.renderFlags2 = bit.set gp.renderFlags2 8 val
            renderFlags2.value = gp.renderFlags2
        )
        
        on chkEnabled changed val do (
            gp.cullFlags = bit.set gp.cullFlags 1 val
            spnCullFlags.value = gp.cullFlags
        )
        
        on chkUnknown2 changed val do (
            gp.cullFlags = bit.set gp.cullFlags 2 val
            spnCullFlags.value = gp.cullFlags
        )
        
        on chkUnknown3 changed val do (
            gp.cullFlags = bit.set gp.cullFlags 3 val
            spnCullFlags.value = gp.cullFlags
        )
        
        on chkUnknown4 changed val do (
            gp.cullFlags = bit.set gp.cullFlags 4 val
            spnCullFlags.value = gp.cullFlags
        )
        
        on chkUnknown5 changed val do (
            gp.cullFlags = bit.set gp.cullFlags 5 val
            spnCullFlags.value = gp.cullFlags
        )
        
        on chkUnknown6 changed val do (
            gp.cullFlags = bit.set gp.cullFlags 6 val
            spnCullFlags.value = gp.cullFlags
        )
        
        on chkUnknown7 changed val do (
            gp.cullFlags = bit.set gp.cullFlags 7 val
            spnCullFlags.value = gp.cullFlags
        )
        
        on chkUnknown8 changed val do (
            gp.cullFlags = bit.set gp.cullFlags 8 val
            spnCullFlags.value = gp.cullFlags
        )
    )

    rollout rltLod ""
    (
        label lblLodDist "Fadeout distance (meters):" align:#left
        spinner lodDist align:#left fieldwidth:70 range:[-3.4e38, 3.4e38, 0] scale:1 type:#float

        on lodDist changed val do (
            gp.lodDist = val
        )
    )

    rollout rltPortal ""
    (
        checkbox chkEnabled "Enabled"
        spinner spnFlags "Flags:" align:#left type:#integer range:[0, 65535, 0] fieldwidth:45
        spinner spnNearRange "Near range:" range:[-3.4e38, 3.4e38, 0] scale:0.5 align:#left fieldwidth:50 type:#float
        spinner spnFarRange "Far range:" range:[-3.4e38, 3.4e38, 0] scale:0.5 align:#left fieldwidth:50 type:#float
        spinner spnUnknown "Unknown:" range:[-3.4e38, 3.4e38, 0] scale:0.5 align:#left fieldwidth:50 type:#float tooltip:"Only version 41 and 42"
        
        on chkEnabled changed val do (
            gp.portalFlags = bit.set gp.portalFlags 3 val
            spnFlags.value = gp.portalFlags
        )
        
        on spnFlags changed val do (
            gp.portalFlags = val
            
            chkEnabled.checked = bit.get val 3
        )

        on spnNearRange changed val do (
            gp.portalNearRange = val
        )
        
        on spnFarRange changed val do (
            gp.portalFarRange = val
        )
        
        on spnUnknown changed val do (
            gp.portalUnknown = val
        )
    )

    rollout rltBbrd ""
    (
        radiobuttons rotMode "Rotation mode:" labels:#("All axes", "Single axis:") align:#left columns:1
        dropdownlist rotAxis "" items:#("X", "Z", "Y") offset:[20,0] width:50

        on rotMode changed val do (
            gp.rotMode = val
        )

        on rotAxis selected i do (
            gp.rotAxis = i
        )
    )

    rollout rltMirror ""
    (
        colorpicker cpColor "Background color: " align:#left
        spinner spnDistance "Active range:" range:[-3.4e38, 3.4e38,0] type:#float align:#left

        on cpColor changed val do (
            gp.mirrorColor = val
        )

        on spnDistance changed val do (
            gp.mirrorDist = val
        )
    )
    
    rollout rltSector ""
    (
        spinner spnFlags1 "Flags1: " fieldwidth:80 type:#integer range:[-4294967295, 4294967295, 0] align:#left
        spinner spnFlags2 "Flags2: " fieldwidth:80 type:#integer range:[-4294967295, 4294967295, 0] align:#left
        
        on spnFlags1 changed val do (
            gp.sectorFlags1 = val
        )
        
        on spnFlags2 changed val do (
            gp.sectorFlags2 = val
        )
    )

    fn OnDeselected = (
        MafParamEditor.objectName.text = ""

        DisabledMode()

        MafParamEditor.addParams.enabled = false
    )

    local availableRlts = #(rltLod, rltPortal, rltBbrd, rltMirror, rltSector)

--     struct TView (
--
--     )


    fn AddAndRemoveRlts floater addRlts removeRlts = (
        for rlt in removeRlts do (
            removeRollout rlt floater
        )

        for rlt in addRlts do (
            addRollout rlt floater
        )
    )

    fn GetDisplayedRlts rlts = (
        for rlt in rlts where rlt.isDisplayed collect rlt
    )

    fn DisableControls controls = (
        for ctrl in controls do (
            ctrl.enabled = false
        )
    )

    fn SetNonVisual = (
        DisableControls #(
            rltObject.renderFlags,
            rltObject.renderFlags2,
            rltObject.chkDepthBias,
            rltObject.chkShadowed,
            rltObject.chkTexProj,
            rltObject.chkNoFog
        )
    )

    fn EnableControls controls = (
        for ctrl in controls do (
            ctrl.enabled = true
        )
    )


    fn OpenSelection strsel = (

        local requestedRlts = #()
        if stricmp strsel "mesh" == 0 then (
            EnableControls rltObject.controls

            requestedRlts = #(rltLod)
        )
        else if stricmp strsel "lod" == 0 then (
            DisableControls rltObject.controls

            requestedRlts = #(rltLod)
        )
        else if stricmp strsel "sector" == 0 then (
            EnableControls rltObject.controls
            SetNonVisual()
            
            requestedRlts = #(rltSector)
        )
        else if stricmp strsel "portal" == 0 then (
            DisableControls rltObject.controls

            requestedRlts = #(rltPortal)
        )
        else if stricmp strsel "billboard" == 0 then (
            EnableControls rltObject.controls

            requestedRlts = #(rltLod, rltBbrd)
        )
        else if stricmp strsel "dummy" == 0 then (
            EnableControls rltObject.controls
            SetNonVisual()
        )
        else if stricmp strsel "bone" == 0 then (
            EnableControls rltObject.controls
            SetNonVisual()
        )
        else if stricmp strsel "target" == 0 then (
            EnableControls rltObject.controls
            SetNonVisual()
        )
        else if stricmp strsel "glow" == 0 then (
            EnableControls rltObject.controls
        )
        else if stricmp strsel "mirror" == 0 then (
            EnableControls rltObject.controls
            requestedRlts = #(rltMirror)
        )
        else if stricmp strsel "occluder" == 0 then (
            EnableControls rltObject.controls
            SetNonVisual()
        )

        local rltsToRemove = #()
        local rltsToUpdate = #()
        local rltsToAdd = #()

        local displayedRlts = GetDisplayedRlts availableRlts

        for rlt in displayedRlts do (
            if not containsItem requestedRlts rlt then append rltsToRemove rlt
            else append rltsToUpdate rlt
        )

        for rlt in requestedRlts do (
            if not containsItem displayedRlts rlt then append rltsToAdd rlt
        )

        AddAndRemoveRlts floater rltsToAdd rltsToRemove

        if rltObject.isDisplayed then (
            rltObject.renderFlags.value = gp.renderFlags
            rltObject.renderFlags2.value = gp.renderFlags2
            rltObject.spnCullFlags.value = gp.cullFlags

            if gp.strParams != undefined then (
                rltObject.strParams.text = gp.strParams
            )

            local flags = gp.renderFlags2

            rltObject.chkDepthBias.checked = bit.get flags 1
            rltObject.chkShadowed.checked = bit.get flags 2
            rltObject.chkTexProj.checked = bit.get flags 6
            rltObject.chkNoFog.checked = bit.get flags 8
            
            local cullFlags = gp.cullFlags
            
            rltObject.chkEnabled.checked = bit.get cullFlags 1
            rltObject.chkUnknown2.checked = bit.get cullFlags 2
            rltObject.chkUnknown3.checked = bit.get cullFlags 3
            rltObject.chkUnknown4.checked = bit.get cullFlags 4
            rltObject.chkUnknown5.checked = bit.get cullFlags 5
            rltObject.chkUnknown6.checked = bit.get cullFlags 6
            rltObject.chkUnknown7.checked = bit.get cullFlags 7
            rltObject.chkUnknown8.checked = bit.get cullFlags 8
        )

        if rltLod.isDisplayed then (
            rltLod.lodDist.value = gp.lodDist
        )

        if rltPortal.isDisplayed then (
            rltPortal.spnFlags.value = gp.portalFlags
            rltPortal.spnNearRange.value = gp.portalNearRange
            rltPortal.spnFarRange.value = gp.portalFarRange
            rltPortal.spnUnknown.value = gp.portalUnknown
            
            local flags = gp.portalFlags
            
            rltPortal.chkEnabled.checked = bit.get flags 3
        )

        if rltBbrd.isDisplayed then (
            rltBbrd.rotMode.state = gp.rotMode
            rltBbrd.rotAxis.selection = gp.rotAxis
        )

        if rltMirror.isDisplayed then (
            rltMirror.cpColor.color = gp.mirrorColor
            rltMirror.spnDistance.value = gp.mirrorDist
        )
        
        if rltSector.isDisplayed then (
            rltSector.spnFlags1.value = gp.sectorFlags1
            rltSector.spnFlags2.value = gp.sectorFlags2
        )
    )

    fn SetSelectionStr sel = (
        local items = MafParamEditor.objectType.items

        local id = findItem items sel
        if id == 0 then id = 1

        MafParamEditor.objectType.selection = id
    )

    fn EnabledMode = (
        MafParamEditor.addParams.enabled = false
        MafParamEditor.removeParams.enabled = true
        MafParamEditor.objectType.enabled = true
        MafParamEditor.objectTypeLabel.enabled = true

        if not visible then (
            --format "REVIS \n"
            for c in rltObject.controls do c.visible = true
            for c in rltLod.controls do c.visible = true
            for c in rltPortal.controls do c.visible = true
            for c in rltBbrd.controls do c.visible = true
            for c in rltMirror.controls do c.visible = true
            for c in rltSector.controls do c.visible = true

            visible = true
        )
    )

    fn DisabledMode = (
        --MafParamEditor.addParams.enabled = true
        MafParamEditor.removeParams.enabled = false

        MafParamEditor.objectTypeLabel.enabled = false
        MafParamEditor.objectType.enabled = false

        MafParamEditor.objectType.selection = 1

        for c in rltObject.controls do c.visible = false
        for c in rltLod.controls do c.visible = false
        for c in rltPortal.controls do c.visible = false
        for c in rltBbrd.controls do c.visible = false
        for c in rltMirror.controls do c.visible = false
        for c in rltSector.controls do c.visible = false

        visible = false
    )

    fn OnSelectionChanged =
    (
        local obj = selection[1]

        -- Workaround for performance reasons - when selecting in scene explorer,
        -- callback fires twice, once with 'undefined', then with correct object.
        if obj == undefined then (
            MafParamEditor.timerDeselected.active = true
        )
        else (
            MafParamEditor.timerDeselected.active = false
        )


        if selection.count >= 2 then (
            MafParamEditor.objectName.text = ""
            DisabledMode()
            MafParamEditor.addParams.enabled = false
        )
        else if selection.count == 1 then (
            local exp = ::MafiaTools_4dsExport
            MafParamEditor.objectName.text = obj.name

            local items = #()

            local nodeType = exp.GetNodeType obj
            case nodeType of (
                #sector:        items = #("Sector")
                #portal:        items = #("Portal")
                #lod:           items = #("Lod")
                #mesh:          items = #("Mesh", "Billboard", "Mirror", "Occluder")
                #billboard:     items = #("Mesh", "Billboard", "Mirror", "Occluder")
                #singlemesh:    items = #("Mesh")
                #singlemorph:   items = #("Mesh")
                #morph:         items = #("Mesh")
                #dummy:         items = #("Dummy")
                #target:        items = #("Target")
                #glow:          items = #("Glow")
                #bone:          items = #("Bone")
                #mirror:        items = #("Mesh", "Billboard", "Mirror", "Occluder")
                #occluder:      items = #("Mesh", "Billboard", "Mirror", "Occluder")
                default:        items = #("Dummy")
            )
            MafParamEditor.objectType.items = items

            gp = custAttributes.get obj MafParams_def baseObject:false

            if gp != undefined then (
                local items = MafParamEditor.objectType.items
                --format "gp.objectType: %\n" gp.objectType
                if findItem items gp.objectType == 0 then gp.objectType = items[1]

                EnabledMode()
                SetSelectionStr gp.objectType
                OpenSelection gp.objectType

                local instances
                local count = InstanceMgr.GetInstances obj &instances


                if instances[count] == obj then (
                    --format "MASTER INSTANCE\n"
                    for c in rltLod.controls do c.visible = true
                )
                else (
                    for c in rltLod.controls do c.visible = false
                )

            )
            else (  --no custom attributes
                DisabledMode()
                MafParamEditor.addParams.enabled = true                
            )
        )

    )

    fn OnNodeRenamed = (
        OnSelectionChanged()
    )


    local title = "4ds Object Parameters"

    if floater != undefined then (
        if floater.open then (
            closeRolloutFloater floater
        )
        else (
            local pos = floater.pos
            local size = floater.size
            floater = newRolloutFloater title size[1] size[2] pos[1] pos[2]
        )
    )
    else (
        floater = newRolloutFloater title 190 490
    )

    if floater.open then (
        callbacks.addScript #selectionSetChanged "OnSelectionChanged()" id:#selChangedID
        callbacks.addScript #nodeRenamed "OnNodeRenamed()" id:#nodeRenamedID

        addRollout MafParamEditor floater
        addRollout rltObject floater

        for c in rltObject.controls do c.visible = false

        OnSelectionChanged()
    )

)