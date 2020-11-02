callbacks.removeScripts #sceneUndo id:#Max4ds_Events
callbacks.addScript #sceneUndo "Max4ds_Events.Handle Max4ds_Events.SceneUndo" id:#Max4ds_Events

callbacks.removeScripts #sceneRedo id:#Max4ds_Events
callbacks.addScript #sceneRedo "Max4ds_Events.Handle Max4ds_Events.SceneRedo" id:#Max4ds_Events

rollout Max4ds_Events "" (   --module
    fn Handle event = (
        for i = 1 to event.listeners.count do (
            event.listeners[i] event.args[i]
        )
    )
    
    rollout SceneUndo "" (
        local listeners = #()
        local args = #()
    )
    
    rollout SceneRedo "" (
        local listeners = #()
        local args = #()
    )

    fn AddListener event listener arg1 = (
        ::Max4ds_Events.RemoveListener event listener
        if listener != undefined then (
            append event.listeners listener
            append event.args arg1
            --format "Add listener (%) \n" event
        )
        else (
            --format "failed to add listener\n"
        )
    )

    fn RemoveListener event listener = (
        local id = findItem event.listeners listener
        
        if id != 0 then (
            deleteItem event.listeners id
            deleteItem event.args id
            --format "Remove listener (%)\n" event     
        )
        else (
            --format "failed to remove listener\n"
        )
    )
)