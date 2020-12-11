plugin Helper Target4ds
name:"4ds Target"
classID:#(0x3cbc454, 0x64e73235)
category:"4ds Tools"
extends:point
replaceUI:true
(
    parameters pblock rollout:rltTarget
    (
        flags type:#integer default:1 ui:spnFlags
        nodes type:#nodeTab tabSizeVariable:true
    )
    
    parameters pblock2 rollout:rltViewport
    (
        viewportSize type:#float default:1 ui:spnSize
        
        on viewportSize set val do (
            delegate.size = val
        )
    )
    
    rollout rltTarget "Target Parameters"
    (
        spinner spnFlags "Flags: " type:#integer range:[0, 65535, 0] align:#left fieldwidth:90
        label lblNodes "Targeting nodes: " align:#left offset:[0, 10]
        pickbutton pbAdd "Add" across:2 align:#left width:50
        button btnRemove "Remove" align:#right width:70
        listbox lbNodes "" height:6

        on pbAdd picked val do (
            undo "Add targeting node" on (
                append nodes val
                local items = lbNodes.items
                append items val.name
                lbNodes.items = items
            )
        )


        on btnRemove pressed do (
            local sel = lbNodes.selection
            if sel != 0 then (
                undo "Remove targeting node" on (
                    local items = lbNodes.items
                    deleteItem items sel
                    deleteItem nodes sel
                    lbNodes.items = items

                    if sel > items.count then lbNodes.selection = items.count
                    else lbNodes.selection = sel
                )
            )
        )
        
        fn Reload scope: = (            
            local items = #()
            for obj in scope.nodes do (
                local name = 
                    if isValidNode obj then obj.name
                    else "<deleted>"
                append items name
            )
            scope.rltTarget.lbNodes.items = items
        )

        on rltTarget open do (
            Reload scope:this
            
            local events = ::Max4ds_Events
            events.AddHandler #sceneUndo Reload scope:this
            events.AddHandler #sceneRedo Reload scope:this
        )
        
        on rltTarget close do (
            local events = ::Max4ds_Events
            events.RemoveHandler #sceneUndo Reload
            events.RemoveHandler #sceneRedo Reload
        )
    )
    
    rollout rltViewport "Viewport"
    (
        spinner spnSize "Viewport size: " type:#float range:[0, 3.4e38, 0]
    )
    
    tool create
    (
        on mousePoint click do
        (
            nodeTM.translation = gridPoint;#stop
        )
    )
    
    local afterCreate = false
    
    on attachedToNode node do (
        if afterCreate then (
            node.wirecolor = color 28 122 210
        )
        afterCreate = false
    )

    on create do (
        afterCreate = true
        
        delegate.size = viewportSize
        delegate.centermarker = true
        delegate.axistripod  = false
        delegate.cross = false
        delegate.box = true
    )
)
