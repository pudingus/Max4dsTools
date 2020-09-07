undo off (
    
    local destroyed = false
    if ::ConvertSkeleton != undefined and ::ConvertSkeleton.open do (
        DestroyDialog ::ConvertSkeleton
        destroyed = true
    )
    
    
    rollout ConvertSkeleton "Convert old skeleton"
    (
        label lblInfo "This tool converts old 0.4.x skeleton \nformat to the new one." height:30
        button btnConvert "Convert" width:70
        
        on btnConvert pressed do (
            local util = ::MafiaTools_util   
    
            local found = false
            for obj in objects while not found do (
                if obj.parent == undefined and util.GetNodeType obj == #singlemesh then (
                    found = true
                    local skinMesh = obj
                    local imp = ::MafiaTools_4dsImport
                    local rootBone = imp.CreateBone()
                    rootBone.transform = skinMesh.transform
                    rootBone.name = skinMesh.name
                    skinMesh.name = "_mesh"
                    skinMesh.parent = rootBone
                    
                    local children = copy skinMesh.children #noMap
                    local fixBones = #()
                    
                    for child in children do (
                        if util.GetNodeType child == #bone then (
                            child.parent = rootBone
                            append fixBones child
                        )
                    )
                    
                    local skinMod = util.GetModByClass skinMesh Skin            
                    skinOps.AddBone skinMod rootBone 1            
                    rootBone.setBoneEnable true sliderTime            
                    local rootBoneId = skinOps.GetNumberBones skinMod            
                    local boneNodes = util.GetBoneNodes skinMod
                    
                    local numverts = skinOps.GetNumberVertices skinMod 
                    for i = 1 to numverts do (
                        local count = skinOps.GetVertexWeightCount skinMod i
                        
                        if count == 1 then (
                            local id = skinOps.GetVertexWeightBoneID skinMod i 1
                            local weight = skinOps.GetVertexWeight skinMod i 1
                            
                            if weight != 1.0 then (
                                if findItem fixBones boneNodes[id] > 0 then (
                                    local weight2 = 1.0 - weight
                                    skinOps.SetVertexWeights skinMod i rootBoneId weight2
                                    skinOps.unNormalizeVertex skinMod i false
                                )
                            )                    
                        )
                        else if count == 0 then (
                            local weight2 = 1.0
                            skinOps.SetVertexWeights skinMod i rootBoneId weight2
                            skinOps.unNormalizeVertex skinMod i false
                        )
                    )
                )
            )    
            
            if not found then (
                messageBox "Nothing to convert."
            )
        )
    )
    
    if not destroyed do (
        local style = #(#style_resizing, #style_titlebar, #style_sysmenu)
        local w = 200
        local h = 75
        
        CreateDialog ConvertSkeleton width:w height:h style:style        
    )
)