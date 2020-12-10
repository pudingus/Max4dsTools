global Max4ds_ParamFloater


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
    
    local OnSelectionChanged

    rollout rltParams "4ds Object Parameters"
    (
        timer tmrDeselected interval:50 active:false

        on tmrDeselected tick do (
            --format "DESELECTED!\n"
            tmrDeselected.active = false
            OnDeselected()
        )

        label lblObjectName "" align:#left
        button btnAddParams "Add" align:#left pos:[10,25] tooltip:"Add parameters"
        button btnRmoveParams "Remove" align:#left pos:[50,25] tooltip:"Remove parameters"
        label lblObjectType "Object type:" across:2 offset:[0,3] align:#left
        dropdownlist ddlObjectType "" align:#left width:80  items:#("Dummy")

        on ddlObjectType selected i do (
            local strsel = ddlObjectType.items[i]

            if gp != undefined then gp.objectType = strsel

            OpenSelection strsel
        )

        on btnAddParams pressed do (
            local obj = selection[1]
            if obj != undefined then (

                custAttributes.add obj MafParams_def baseObject:false
                gp = custAttributes.get obj MafParams_def baseObject:false

                local sel = ddlObjectType.selection
                local strsel = ddlObjectType.items[sel]

                gp.objectType = strsel

                if stricmp strsel "sector" == 0 then (
                    gp.cullFlags = 125
                )

                EnabledMode()
                ddlObjectType.selection = 1
                OpenSelection strsel
            )
        )

        on btnRmoveParams pressed do (
            local obj = selection[1]
            if obj != undefined then (

                if queryBox "Do you want to remove parameters from this object?" then (

                    custAttributes.delete obj MafParams_def baseObject:false

                    DisabledMode()
                    btnAddParams.enabled = true
                )
            )
        )
        
        on rltParams open do (
            --format "open\n"
            
            local events = ::Max4ds_Events
            events.AddHandler #selectionSetChanged OnSelectionChanged rltParams
            events.AddHandler #nodeRenamed OnSelectionChanged rltParams
        )

        on rltParams close do (
            --format "close\n"
            
            local events = ::Max4ds_Events
            events.RemoveHandler #selectionSetChanged OnSelectionChanged
            events.RemoveHandler #nodeRenamed OnSelectionChanged
        )
    )

    rollout rltObject ""
    (
        spinner spnRenderFlags "Render flags:" range:[0,255,0] type:#integer align:#left fieldwidth:30 enabled:false across:2
        spinner spnRenderFlags2 "" range:[0,255,0] type:#integer fieldwidth:30 enabled:false
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
        
        label lblStringParams "String params:" align:#left
        edittext edtStringParams "" align:#left width:140 height:30

        on spnRenderFlags changed val do (
            gp.renderFlags = val
        )

        on spnRenderFlags2 changed val do (
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

        on edtStringParams changed val do (
            gp.strParams = val
        )

        on chkDepthBias changed val do (
            gp.renderFlags2 = bit.set gp.renderFlags2 1 val
            spnRenderFlags2.value = gp.renderFlags2
        )

        on chkShadowed changed val do (
            gp.renderFlags2 = bit.set gp.renderFlags2 2 val
            spnRenderFlags2.value = gp.renderFlags2
        )

        on chkTexProj changed val do (
            gp.renderFlags2 = bit.set gp.renderFlags2 6 val
            spnRenderFlags2.value = gp.renderFlags2
        )

        on chkNoFog changed val do (
            gp.renderFlags2 = bit.set gp.renderFlags2 8 val
            spnRenderFlags2.value = gp.renderFlags2
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
        spinner spnLodDist align:#left fieldwidth:70 range:[-3.4e38, 3.4e38, 0] scale:1 type:#float

        on spnLodDist changed val do (
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
        radiobuttons rdoRotMode "Rotation mode:" labels:#("All axes", "Single axis:") align:#left columns:1
        dropdownlist ddlRotAxis "" items:#("X", "Z", "Y") offset:[20,0] width:50

        on rdoRotMode changed val do (
            gp.rotMode = val
        )

        on ddlRotAxis selected i do (
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
        rltParams.lblObjectName.text = ""

        DisabledMode()

        rltParams.btnAddParams.enabled = false
    )

    local availableRlts = #(rltLod, rltPortal, rltBbrd, rltMirror, rltSector)

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
            rltObject.spnRenderFlags,
            rltObject.spnRenderFlags2,
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

        AddAndRemoveRlts ::Max4ds_ParamFloater rltsToAdd rltsToRemove

        if rltObject.isDisplayed then (
            rltObject.spnRenderFlags.value = gp.renderFlags
            rltObject.spnRenderFlags2.value = gp.renderFlags2
            rltObject.spnCullFlags.value = gp.cullFlags

            if gp.strParams != undefined then (
                rltObject.edtStringParams.text = gp.strParams
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
            rltLod.spnLodDist.value = gp.lodDist
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
            rltBbrd.rdoRotMode.state = gp.rotMode
            rltBbrd.ddlRotAxis.selection = gp.rotAxis
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
        local items = rltParams.ddlObjectType.items

        local id = findItem items sel
        if id == 0 then id = 1

        rltParams.ddlObjectType.selection = id
    )

    fn EnabledMode = (
        rltParams.btnAddParams.enabled = false
        rltParams.btnRmoveParams.enabled = true
        rltParams.ddlObjectType.enabled = true
        rltParams.lblObjectType.enabled = true

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
        --rltParams.btnAddParams.enabled = true
        rltParams.btnRmoveParams.enabled = false

        rltParams.lblObjectType.enabled = false
        rltParams.ddlObjectType.enabled = false

        rltParams.ddlObjectType.selection = 1

        for c in rltObject.controls do c.visible = false
        for c in rltLod.controls do c.visible = false
        for c in rltPortal.controls do c.visible = false
        for c in rltBbrd.controls do c.visible = false
        for c in rltMirror.controls do c.visible = false
        for c in rltSector.controls do c.visible = false

        visible = false
    )

    fn OnSelectionChanged sender param =
    (
        local obj = selection[1]

        -- Workaround for performance reasons - when selecting in scene explorer,
        -- callback fires twice, once with 'undefined', then with correct object.
        if obj == undefined then (
            sender.tmrDeselected.active = true
        )
        else (
            sender.tmrDeselected.active = false
        )


        if selection.count >= 2 then (
            sender.lblObjectName.text = ""
            DisabledMode()
            sender.btnAddParams.enabled = false
        )
        else if selection.count == 1 then (
            local exp = ::MafiaTools_4dsExport
            sender.lblObjectName.text = obj.name

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
            sender.ddlObjectType.items = items

            gp = custAttributes.get obj MafParams_def baseObject:false

            if gp != undefined then (
                local items = sender.ddlObjectType.items
                if findItem items gp.objectType == 0 then gp.objectType = items[1]

                EnabledMode()
                SetSelectionStr gp.objectType
                OpenSelection gp.objectType

                local instances
                local count = InstanceMgr.GetInstances obj &instances


                if instances[count] == obj then (  --main instance
                    for c in rltLod.controls do c.visible = true
                )
                else (
                    for c in rltLod.controls do c.visible = false
                )

            )
            else (  --no custom attributes
                DisabledMode()
                sender.btnAddParams.enabled = true                
            )
        )

    )
    
    local title = "4ds Object Parameters"
    
    local floater = ::Max4ds_ParamFloater

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
        addRollout rltParams floater
        addRollout rltObject floater

        for c in rltObject.controls do c.visible = false

        OnSelectionChanged rltParams undefined
    )

    ::Max4ds_ParamFloater = floater
)