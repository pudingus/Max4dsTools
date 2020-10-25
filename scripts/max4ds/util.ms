
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
    
    fn GetDependingNodes mod = (
        for k in (refs.dependsOn mod) where (isValidNode k) collect k
    )
    ----------
    
    
    ---skin ops-------
    fn GetBoneNodes skinMod = (   --delete this
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
        if existingWeight == undefined then existingWeight = 0.0

        if weight != undefined then (
            skin_setVertexWeight xskin vertid oldid 0.0
            skin_setVertexWeight xskin vertid newid (weight + existingWeight)
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
    -----------------
    
    fn ToBoxsize dmin dmax = (
        [abs (dmin.x-dmax.x), abs (dmin.y-dmax.y), abs (dmin.z-dmax.z)]
    )

    -------------------
    fn PrintMatrix mtr = (
        local ss = StringStream ""

        for m = 1 to 4 do (
            for n = 1 to 3 do (
                local val = mtr[m][n]
                local fmvalue = ""

                if val as string == "0.0" then fmvalue = " 0     "
                else fmvalue = formattedPrint val format:" .4f"

                format "% " fmvalue to:ss
            )
            format "\n" to:ss
        )
        --format "\n" to:ss
        format (ss as string)
        --ss
    )
    
    -----------------
          
)

fn elapsed_since time = (
    local now = timeStamp()
        
    if now < time then now += 86400000 --timing over midnight
    (now - time)
)