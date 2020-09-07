
rollout MafiaTools_Layers "" (  --module

    fn AddTo obj layerName = (
        local layer = LayerManager.getLayerFromName layerName
        if layer == undefined then (
            layer = LayerManager.newLayerFromName layerName
        )

        if layer != undefined then (
            layer.addnode obj
        )
    )

    fn Hide arr = (
        for layerName in arr do (
            local layer = LayerManager.getLayerFromName layerName
            if layer != undefined then layer.ishidden = true
        )
    )

    fn HideLods bitArr = (
        for b in bitArr do (
            local layerName = "Lod" + (b as string)
            local layer = LayerManager.getLayerFromName layerName
            if layer != undefined then layer.ishidden = true
        )
    )

    fn Clear = (
        local count = LayerManager.count
        local layerNames = for i = 1 to count-1 collect (
            local layer = LayerManager.getLayer i
            layer.name
        )

        for lname in layerNames do (
            LayerManager.deleteLayerByName lname
        )
    )
)
