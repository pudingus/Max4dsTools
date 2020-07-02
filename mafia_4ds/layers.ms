struct Layers (
    --private
    lod_layers = #(),
    dummies,
    sectors,
    portals,
    bones,
    glows,
    billboards,
    disabled,
    
    --private
    fn GetLayer layerName layer = (
        if layer == undefined then (
            layer = LayerManager.getLayerFromName layerName
            if layer == undefined then (
                layer = LayerManager.newLayerFromName layerName
            )
        )
        layer
    ),
    
    fn AddToLayer obj layerName layer = (
        layer = GetLayer layerName layer
        layer.addnode obj
    ),
    
    
    --public
    fn AddTo obj type = (
        case type of (
            #glow: AddToLayer obj "Glows" glows
            #dummy: AddToLayer obj "Dummies" dummies
            #sector: AddToLayer obj "Sectors" sectors
            #portal: AddToLayer obj "Portals" portals
            #bone: AddToLayer obj "Bones" bones
            #billboard: AddToLayer obj "Billboards" billboards
            #disabled: AddToLayer obj "Disabled" disabled
        )
    ),
    
    fn AddLod obj lodId = (        
        local layer = lod_layers[lodId + 1]
        local str = "Lod" + (lodId as string)
        if layer == undefined then (
            layer = LayerManager.getLayerFromName str
            if layer == undefined then (
                layer = LayerManager.newLayerFromName str
                lod_layers[lodId + 1] = layer

                if lodId >= 1 then layer.ishidden = true
            )
        )
        layer.addnode obj        
    )
)

Layers = Layers()
