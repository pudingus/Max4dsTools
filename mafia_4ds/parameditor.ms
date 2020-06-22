global OnNodeRenamed
global OnSelectionChanged
global aaa
(

local gp

rollout ObjectRoll ""
(
    spinner renderFlags "Rendering flags:" range:[0,65535,0] type:#integer align:#left fieldwidth:45 enabled:false
    spinner cullFlags "Culling flags:      " range:[0,255,0]  type:#integer align:#left fieldwidth:45
    label paramsLabel "String params:" align:#left
    edittext userParams "" align:#left width:130    

    on renderFlags changed val do (
        gp.renderFlags = val
    )

    on cullFlags changed val do (
        gp.cullFlags = val
    )

    on userParams changed val do (
        gp.userParams = val
    )

    on ObjectRoll open do (        
        renderFlags.value = gp.renderFlags
        cullFlags.value = gp.cullFlags
        
        if gp.userParams != undefined then (
            userParams.text = gp.userParams
        ) 
    )
)

rollout LodRoll ""
(
    spinner lodDist "LOD distance:   " align:#left fieldwidth:45 range:[0,9999,10] scale:1
    label exporterLabel "Exporter:" align:#left		
    checkbox dontOptimize "Don't optimize vertices" align:#left

    on lodDist changed val do (
        gp.lodDist = val
    )

    on dontOptimize changed val do (
        gp.dontOptimize = val
    )

    on LodRoll open do (
        lodDist.value = gp.lodDist
        dontOptimize.checked = gp.dontOptimize
    )
)

rollout PortalRoll ""
(
    spinner nearRange "Near range:" range:[-900000,900000,0] align:#left fieldwidth:45
    spinner farRange "Far range:  " range:[-900000,900000,0] fieldwidth:45 align:#left 

    on nearRange changed val do (
        gp.nearRange = val
    )

    on farRange changed val do (
        gp.farRange = val
    )
	
	on PortalRoll open do (
        nearRange.value = gp.nearRange
        farRange.value = gp.farRange
	)
)

rollout BillRoll ""
(
    --Billboard
    radiobuttons rotMode "Rotation Mode:" labels:#("All axes", "Single axis:") align:#left columns:1
    dropdownlist rotAxis "" items:#("X", "Y", "Z") offset:[20,0] width:50

    on rotMode changed val do (
        gp.rotMode = val        
    )

    on rotAxis selected i do (
        gp.rotAxis = i
    )

    on BillRoll open do (
        rotMode.state = gp.rotMode
        rotAxis.selection = gp.rotAxis
    )
)

fn RemoveRollouts = (
    removeRollout ObjectRoll aaa
    removeRollout LodRoll aaa    
    removeRollout PortalRoll aaa
    removeRollout BillRoll aaa    
)



fn OpenSelection strsel = (
    RemoveRollouts()
    if stricmp strsel "mesh" == 0 then (
        addRollout ObjectRoll aaa 
        ObjectRoll.renderFlags.enabled = true       
        addRollout LodRoll aaa
    )
    else if stricmp strsel "lod" == 0 then (
        addRollout LodRoll aaa
    )
    else if stricmp strsel "sector" == 0 then (
        addRollout ObjectRoll aaa
    )
    else if stricmp strsel "portal" == 0 then (
        addRollout PortalRoll aaa
    )
    else if stricmp strsel "billboard" == 0 then (
        addRollout ObjectRoll aaa
        ObjectRoll.renderFlags.enabled = true
        addRollout LodRoll aaa
        addRollout BillRoll aaa
    )
    else if stricmp strsel "dummy" == 0 then (
        addRollout ObjectRoll aaa
    )

    if gp != undefined then gp.objectType = strsel
)

rollout MafParamEditor "4DS Parameters"
(
	label objectName "" align:#left
    button addParams "Add" align:#left pos:[15,30]
    button removeParams "Remove" align:#left pos:[55,30]
    dropdownlist objectType "Object type:" align:#left width:130 offset:[0,10]	

    on objectType selected i do (
        RemoveRollouts()
        local strsel = objectType.items[i]
        OpenSelection strsel
    )

    on addParams pressed do (
        local obj = selection[1]
        if obj != undefined then (
            custAttributes.add obj MafParams_def
            gp = custAttributes.get obj MafParams_def

            local sel = objectType.selection
            local selstr = objectType.items[sel]
            if stricmp selstr "sector" == 0 then (
                gp.cullFlags = 129
            )
            
            EnabledMode()
        )
    )

    on removeParams pressed do (
        local obj = selection[1]
        if obj != undefined then (

            if queryBox "Do you want to remove parameters from this object?" then (
                custAttributes.delete obj MafParams_def

                DisabledMode()
            )
        )
    )

    on MafParamEditor close do (
        print "close"
        callbacks.removeScripts #selectionSetChanged id:#selChangedID
        callbacks.removeScripts #nodeRenamed id:#nodeRenamedID
    )
)

fn EnabledMode sel:undefined = (
    MafParamEditor.addParams.enabled = false
    MafParamEditor.removeParams.enabled = true
    
    MafParamEditor.objectType.enabled = true

    local items = MafParamEditor.objectType.items
    local found = false
    local i = 1

    if sel == undefined then (
        sel = items[i]
    )
    else (
        for item in items while not found do (
            if stricmp item sel == 0 then found = true
            else i = i + 1
        )
    )

    MafParamEditor.objectType.selection = i            
    
    OpenSelection sel 
)

fn DisabledMode = (
    MafParamEditor.addParams.enabled = true
    MafParamEditor.removeParams.enabled = false
    RemoveRollouts()
    MafParamEditor.objectType.selection = 1 
    MafParamEditor.objectType.enabled = false
)

fn OnSelectionChanged =
(    
	local obj = selection[1]
	if obj != undefined then (
        MafParamEditor.objectName.text = obj.name


        if matchPattern obj.name pattern:"sector*" then (
            MafParamEditor.objectType.items = #("Sector")
        )
        else if matchPattern obj.name pattern:"$portal*" then(
            MafParamEditor.objectType.items = #("Portal")
        )
        else if matchPattern obj.name pattern:"$lod*" then(
            MafParamEditor.objectType.items = #("Lod")
        )
        else if isKindOf obj helper then (
            MafParamEditor.objectType.items = #("Dummy", "Glow")
        ) 
        else (
            MafParamEditor.objectType.items = #("Mesh", "Billboard")
        )

        gp = custAttributes.get obj MafParams_def

        if gp != undefined then (
            EnabledMode sel:gp.objectType
        )
        else (  --no custom attributes
            DisabledMode()
        )
    )	   
    else (
        MafParamEditor.objectName.text = ""
        MafParamEditor.objectType.enabled = false
        RemoveRollouts()

        MafParamEditor.addParams.enabled = false
        MafParamEditor.removeParams.enabled = false
    )
    
    print obj

)

fn OnNodeRenamed = (
    local obj = selection[1]
	if obj != undefined then (
        MafParamEditor.objectName.text = obj.name

        if matchPattern obj.name pattern:"sector*" then (
            MafParamEditor.objectType.items = #("Sector")
        )
        else if matchPattern obj.name pattern:"$portal*" then(
            MafParamEditor.objectType.items = #("Portal")
        )
        else if matchPattern obj.name pattern:"$lod*" then(
            MafParamEditor.objectType.items = #("Lod")
        )
        else (
            MafParamEditor.objectType.items = #("Mesh", "Billboard")
        )
    )
)
 

callbacks.addScript #selectionSetChanged "OnSelectionChanged()" id:#selChangedID

callbacks.addScript #nodeRenamed "OnNodeRenamed()" id:#nodeRenamedID


aaa = newRolloutFloater "aaaa" 200 500

addRollout MafParamEditor aaa




)