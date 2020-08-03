struct MafiaTools_Layers (    
    fn GetLayer layerName = (
        local layer = LayerManager.getLayerFromName layerName
        if layer == undefined then (
            layer = LayerManager.newLayerFromName layerName
        )
        layer
    ),    
    
    fn AddTo obj layerName = (
        layer = GetLayer layerName
        layer.addnode obj
    ),
    
    fn Hide arr = (
        for layerName in arr do (
            local layer = LayerManager.getLayerFromName layerName
            if layer != undefined then layer.ishidden = true
        )
    ),
    
    fn HideLods bitArr = (
        for b in bitArr do (
            local layerName = "Lod" + (b as string)
            local layer = LayerManager.getLayerFromName layerName
            if layer != undefined then layer.ishidden = true
        )
    )
)
MafiaTools_Layers = MafiaTools_Layers()
