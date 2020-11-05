(
    local maxver = (maxVersion())[1]
    local is2014 = false
    
    local skinops_getBoneName = skinops.getBoneName
    if maxver == 16000 and isProperty skinops #getbonenamebylistid do (
       skinops_getBoneName = skinops.getBoneNameByListID   
       is2014 = true     
    )
        
    
    struct xCachedData (
        skinMod,
        sysIds = #(),
        listIds = #()
    )
    
    -- Call this after adding bones and before setting weights.
    -- Whenever bones are added or removed, this becomes invalid
    fn makeCache skinMod = (
        xCachedData skinMod:skinMod
    )
    
    fn getBoneName xdata boneId = (
        skinOps.getBoneName xdata.skinMod boneId 0
    ) 
    
    fn getVertexWeightBoneId xdata vertId weightId = (   
        skinOps.GetVertexWeightBoneID xdata.skinMod vertId weightId
    )
    
    fn setVertexWeights xdata vertId boneId weight  = (
        skinOps.SetVertexWeights xdata.skinMod vertId boneId weight
    )
    
    fn replaceVertexWeights xdata vertId boneId weight  = (
        skinOps.ReplaceVertexWeights xdata.skinMod vertId boneId weight
    )
    
    fn selectBone xdata boneId = (
        skinOps.SelectBone xdata.skinMod boneId
    )
    
    ---------
    fn makeCache_2012 skinMod = (
        local boneNodeNames = for k in (refs.dependsOn skinMod) where (isValidNode k) collect k.name
        local listIds = #()
        local sysIds = #()
        for i = 1 to boneNodeNames.count do (
            local boneName = skinops_getBoneName skinMod i 0
            local id = findItem boneNodeNames boneName
            listIds[id] = i
            sysIds[i] = id
        )
        
        xCachedData skinMod:skinMod listIds:listIds sysIds:sysIds
    )
    
    fn getBoneName_2012 xdata boneId = (
        skinOps.getBoneName xdata.skinMod xdata.listIds[boneId] 0
    ) 
    
    fn getVertexWeightBoneId_2012 xdata vertId weightId = (   
        local boneId = skinOps.GetVertexWeightBoneID xdata.skinMod vertId weightId
        xdata.sysIds[boneId]
    )
    
    fn setVertexWeights_2012 xdata vertId boneId weight = (
        if classof boneId == Array then (
            for i = 1 to boneId.count do (
                boneId[i] = xdata.listIds[boneId[i]]
            )
        )
        else boneId = xdata.listIds[boneId]
        skinOps.SetVertexWeights xdata.skinMod vertId boneId weight
    )
    
    fn replaceVertexWeights_2012 xdata vertId boneId weight = (
        if classof boneId == Array then (
            for i = 1 to boneId.count do (
                boneId[i] = xdata.listIds[boneId[i]]
            )
        )
        else boneId = xdata.listIds[boneId]
        skinOps.ReplaceVertexWeights xdata.skinMod vertId boneId weight
    )
    
    fn selectBone_2012 xdata boneId = (
        skinOps.SelectBone xdata.skinMod xdata.listIds[boneId]
    )
    --------------------------
	
    
    ::skin_makeCache = makeCache
    ::skin_getBoneName = getBoneName
    ::skin_getVertexWeightBoneId = getVertexWeightBoneId
    ::skin_setVertexWeights = setVertexWeights
    ::skin_replaceVertexWeights = replaceVertexWeights
    ::skin_selectBone = selectBone    
    
    --2012, 2013, 
    if maxver == 14000 or maxver == 15000 then (
        ::skin_makeCache = makeCache_2012
        ::skin_getBoneName = getBoneName_2012
        ::skin_getVertexWeightBoneId = getVertexWeightBoneId_2012
        ::skin_setVertexWeights = setVertexWeights_2012
        ::skin_replaceVertexWeights = replaceVertexWeights_2012
        ::skin_selectBone = selectBone_2012
    )
    else if is2014 then (  --2014sp0-sp3
        ::skin_makeCache = makeCache_2012
        ::skin_getBoneName = getBoneName_2012
        ::skin_getVertexWeightBoneId = getVertexWeightBoneId_2012
        ::skin_selectBone = selectBone_2012
    )
    

    
)