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
        checkbox depthBias "Depth bias" across:2
        checkbox shadowed "Shadowed"
        checkbox texProj "Tex. proj." across:2 tooltip:"Texture projection"
        checkbox noFog "No fog"

        spinner cullFlags "Culling flags:  " range:[0,255,0]  type:#integer align:#left fieldwidth:50 tooltip:"9=normal, 125=sector, \n61=wall, 29=in portal, \n16=disabled, 17=disabled"
        label paramsLabel "String params:" align:#left
        edittext strParams "" align:#left width:140 height:30

        on renderFlags changed val do (
            gp.renderFlags = val
        )

        on renderFlags2 changed val do (
            gp.renderFlags2 = val

            local flags = val

            depthBias.checked = bit.get flags 1
            shadowed.checked = bit.get flags 2
            texProj.checked = bit.get flags 6
            noFog.checked = bit.get flags 8
        )

        on cullFlags changed val do (
            gp.cullFlags = val
        )

        on strParams changed val do (
            gp.strParams = val
        )

        on depthBias changed val do (
            gp.renderFlags2 = bit.set gp.renderFlags2 1 val
            renderFlags2.value = gp.renderFlags2
        )

        on shadowed changed val do (
            gp.renderFlags2 = bit.set gp.renderFlags2 2 val
            renderFlags2.value = gp.renderFlags2
        )

        on texProj changed val do (
            gp.renderFlags2 = bit.set gp.renderFlags2 6 val
            renderFlags2.value = gp.renderFlags2
        )

        on noFog changed val do (
            gp.renderFlags2 = bit.set gp.renderFlags2 8 val
            renderFlags2.value = gp.renderFlags2
        )
    )

    rollout rltLod ""
    (
        label lblLodDist "Fadeout distance (meters):" align:#left
        spinner lodDist align:#left fieldwidth:70 range:[-9000000000,9000000000,10] scale:1 type:#float

        on lodDist changed val do (
            gp.lodDist = val
        )
    )

    rollout rltPortal ""
    (
        spinner nearRange "Near range:" range:[-9000000000,9000000000,0] align:#left fieldwidth:50 type:#float
        spinner farRange "Far range:  " range:[-9000000000,9000000000,0] align:#left fieldwidth:50 type:#float

        on nearRange changed val do (
            gp.nearRange = val
        )

        on farRange changed val do (
            gp.farRange = val
        )
    )

    rollout rltBbrd ""
    (
        radiobuttons rotMode "Rotation mode:" labels:#("All axes", "Single axis:") align:#left columns:1
        dropdownlist rotAxis "" items:#("X", "Y", "Z") offset:[20,0] width:50

        on rotMode changed val do (
            gp.rotMode = val
        )

        on rotAxis selected i do (
            gp.rotAxis = i
        )
    )

    rollout rltMirror ""
    (
        spinner spnUnk1 "Unknown 1: " range:[-9000000000,9000000000,0] type:#float align:#left
        spinner spnUnk2 "Unknown 2: " range:[-9000000000,9000000000,0] type:#float align:#left
        spinner spnUnk3 "Unknown 3: " range:[-9000000000,9000000000,0] type:#float align:#left
        spinner spnUnk4 "Unknown 4: " range:[-9000000000,9000000000,0] type:#float align:#left
        colorpicker cpColor "Background color: " align:#left
        spinner spnDistance "Active range:" range:[-9000000000,9000000000,0] type:#float align:#left

        on spnUnk1 changed val do (
            gp.mirrorUnk1 = val
        )

        on spnUnk2 changed val do (
            gp.mirrorUnk2 = val
        )

        on spnUnk3 changed val do (
            gp.mirrorUnk3 = val
        )

        on spnUnk4 changed val do (
            gp.mirrorUnk4 = val
        )

        on cpColor changed val do (
            gp.mirrorColor = val
        )

        on spnDistance changed val do (
            gp.mirrorDist = val
        )
    )

    fn OnDeselected = (
        MafParamEditor.objectName.text = ""

        DisabledMode()

        MafParamEditor.addParams.enabled = false
    )

    local availableRlts = #(rltLod, rltPortal, rltBbrd, rltMirror)

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
            rltObject.depthBias,
            rltObject.shadowed,
            rltObject.texProj,
            rltObject.noFog
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
            rltObject.cullFlags.value = gp.cullFlags

            if gp.strParams != undefined then (
                rltObject.strParams.text = gp.strParams
            )

            local flags = gp.renderFlags2

            rltObject.depthBias.checked = bit.get flags 1
            rltObject.shadowed.checked = bit.get flags 2
            rltObject.texProj.checked = bit.get flags 6
            rltObject.noFog.checked = bit.get flags 8
        )

        if rltLod.isDisplayed then (
            rltLod.lodDist.value = gp.lodDist
        )

        if rltPortal.isDisplayed then (
            rltPortal.nearRange.value = gp.nearRange
            rltPortal.farRange.value = gp.farRange
        )

        if rltBbrd.isDisplayed then (
            rltBbrd.rotMode.state = gp.rotMode
            rltBbrd.rotAxis.selection = gp.rotAxis
        )

        if rltMirror.isDisplayed then (
            rltMirror.spnUnk1.value = gp.mirrorUnk1
            rltMirror.spnUnk2.value = gp.mirrorUnk2
            rltMirror.spnUnk3.value = gp.mirrorUnk3
            rltMirror.spnUnk4.value = gp.mirrorUnk4
            rltMirror.cpColor.color = gp.mirrorColor
            rltMirror.spnDistance.value = gp.mirrorDist
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
        floater = newRolloutFloater title 190 470
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