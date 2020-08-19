struct MafiaTools_Util (
    fn GetModByClass obj mclass = (    --to support versions prior 2013
        local foundMod
        if obj != undefined then (
            for modd in obj.modifiers while foundMod == undefined do (
                if classof modd == mclass then (
                    foundMod = modd
                )
            )
        )
        foundMod
    ),

    fn IsGeometry obj = (
        Superclassof obj == GeometryClass and ClassOf obj != TargetObject
    ),

    fn containsItem array value = (
        (findItem array value) > 0
    ),

    fn PrintArray arr = (
        local ss = stringstream ""
        format "count: %\n" arr.count to:ss
        for item in arr do (
            format "%\n" item to:ss
        )
        format (ss as string)
    ),

    fn GetNodeType obj = (
        local gp = custAttributes.get obj MafParams_def baseObject:false
        if (isKindOf obj BoneGeometry) or (obj.boneEnable) then (
            #bone
        )
        else if isKindOf obj M4dsTarget then (
            #target
        )
        else if isKindOf obj M4dsGlow then (
            #glow
        )
        else if isKindOf obj Dummy then (
            #dummy
        )
        else if IsGeometry obj then (
            if matchPattern obj.name pattern:"$portal*" then (
                #portal
            )
            else if matchPattern obj.name pattern:"$lod*" then (
                #lod
            )
            else if matchPattern obj.name pattern:"sector*" then (
                #sector
            )
            else if matchPattern obj.name pattern:"$morph*" then (
                #morph
            )
            else if (gp != undefined) and (stricmp gp.objectType "billboard" == 0) then (
                #billboard
            )
            else if GetModByClass obj Skin != undefined then (
                #singlemesh
            )
            else (
                #mesh
            )
        )
        else #unsupported
    )
)
MafiaTools_Util = MafiaTools_Util()