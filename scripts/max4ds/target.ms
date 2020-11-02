plugin Helper Target4ds
name:"4ds Target"
classID:#(0x3cbc454, 0x64e73235)
category:"4ds Tools"
extends:point
replaceUI:true
(
    parameters pblock rollout:TargetRoll
    (
        nodes type:#nodeTab tabSizeVariable:true
    )
    parameters pblock2 rollout:TargetViewportRoll
    (
        viewportSize type:#float default:1 ui:spnSize
        
        on viewportSize set val do (
            delegate.size = val
        )
    )
    rollout TargetRoll "Target Parameters"
    (
        pickbutton pbAdd "Add" across:2 align:#left width:50
        button btnRemove "Remove" align:#right width:70
        listbox lbNodes "Targeting nodes" height:6

        on pbAdd picked val do (
            append nodes val
            local items = lbNodes.items
            append items val.name
            lbNodes.items = items
        )


        on btnRemove pressed do (
            local sel = lbNodes.selection
            if sel != 0 then (
                local items = lbNodes.items
                deleteItem items sel
                deleteItem nodes sel
                lbNodes.items = items

                if sel > items.count then lbNodes.selection = items.count
                else lbNodes.selection = sel
            )
        )

        on TargetRoll open do (
            local items = #()
            for obj in nodes do (
                local name = 
                    if isValidNode obj then obj.name
                    else "<deleted>"                
                append items name
            )
            lbNodes.items = items
        )

    )
    rollout TargetViewportRoll "Viewport"
    (
        spinner spnSize "Viewport size: " type:#float range:[0,90000,0]
    )
    tool create
    (
        on mousePoint click do
        (
            $.wirecolor = color 28 122 210
            nodeTM.translation = gridPoint;#stop
        )
    )

    on create do (
        delegate.size = viewportSize
        delegate.centermarker = true
        delegate.axistripod  = false
        delegate.cross = false
        delegate.box = true
        -- nnode.constantscreensize = true
    )
)
