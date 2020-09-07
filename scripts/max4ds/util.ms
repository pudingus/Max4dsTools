
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
        for k in (refs.dependsOn skinMod) where (isKindOf k node) collect k
    )
    
    fn GetBoneVertexWeight skinMod vertid boneid = (
        local weight
        local count = skinOps.GetVertexWeightCount skinMod vertid
        local nth
        for i = 1 to count while nth == undefined do (
            id = skinOps.GetVertexWeightBoneID skinMod vertid i
            if id == boneid then nth = i
        )
        if nth != undefined then (
            weight = skinOps.GetVertexWeight skinMod vertid nth
        )
        weight
    )

    fn TransferWeight skinMod vertid oldId newId = (
        local weight = GetBoneVertexWeight skinMod vertid oldid
        
        local existingWeight = GetBoneVertexWeight skinMod vertid newId

        if weight != undefined then (
            skinOps.SetVertexWeights skinMod vertid oldid 0.0
            skinOps.SetVertexWeights skinMod vertid newid (weight + existingWeight)
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