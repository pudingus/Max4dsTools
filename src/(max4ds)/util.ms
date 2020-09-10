
rollout MafiaTools_Util "" (    --module
    
    --modifier ops
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
    )
    
    fn HasMod obj mclass = (
        GetModByClass obj mclass != undefined
    )
    ----------
    
    
    ---skin ops-------
    fn GetBoneNodes skinMod = (
        for k in (refs.dependsOn skinMod) where (isValidNode k) collect k
    )
    
    fn GetBoneVertexWeight skinMod vertid boneid = (
        local xskin = skin_makeCache skinMod
        local weight
        local count = skinOps.GetVertexWeightCount skinMod vertid
        local nth
        for i = 1 to count while nth == undefined do (
            id = skin_GetVertexWeightBoneID xskin vertid i
            if id == boneid then nth = i
        )
        if nth != undefined then (
            weight = skinOps.GetVertexWeight skinMod vertid nth
        )
        weight
    )

    fn TransferWeight skinMod vertid oldId newId = (
        local xskin = skin_makeCache skinMod
        local weight = GetBoneVertexWeight skinMod vertid oldid
        
        local existingWeight = GetBoneVertexWeight skinMod vertid newId

        if weight != undefined then (
            skin_SetVertexWeights xskin vertid oldid 0.0
            skin_SetVertexWeights xskin vertid newid (weight + existingWeight)
        )
    )
    ------------------
    
    
    
    ---node ops----------
    fn IsGeometry obj = (
        Superclassof obj == GeometryClass and ClassOf obj != TargetObject
    )
    
    fn isDescendantOf node1 node2 = (
        while node1.parent != undefined and node1.parent != node2 do (
            node1 = node1.parent
        )
        node1.parent == node2
    )
    
    fn directlyRelated node1 node2 = (
        node1.parent == node2 or node2.parent == node1
    )
    ----------------------
    
    
    ---array ops----
    fn containsItem array value = (
        (findItem array value) > 0
    )

    fn PrintArray arr = (
        local ss = stringstream ""
        format "count: %\n" arr.count to:ss
        for item in arr do (
            format "%\n" item to:ss
        )
        format (ss as string)
    )
    
    fn ReverseArray arr = (
        local newArr = #()
        for i = 1 to arr.count do (
            append newArr arr[arr.count-i+1]
        )
        newArr
    )
    ---------------
    
    ---string ops----
    fn isStringEmpty str = (
        str == undefined or str.count == 0
    )
    
    -------------------
    
    
    -----------------
    fn GetNodeType obj = (
        local gp = custAttributes.get obj MafParams_def baseObject:false
        if (isKindOf obj BoneGeometry) or (obj.boneEnable) then (
            #bone
        )
        else if isKindOf obj Target4ds then (
            #target
        )
        else if isKindOf obj Glow4ds then (
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

fn elapsed_since time = (
    local now = timeStamp()
        
    if now < time then now += 86400000 --timing over midnight
    (now - time)
)