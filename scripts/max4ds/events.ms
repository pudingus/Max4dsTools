callbacks.removeScripts id:#Max4ds_Events

rollout Max4ds_Events "" (   --module    
    local eventIds = #()
    local eventNames = #()
    local eventHandlers = #()   --array of array
    local eventScopes = #()    --array of array
  
    fn Fire eventId = (
        local param = callbacks.notificationParam()
        for i = 1 to eventHandlers[eventId].count do (
            local handler = eventHandlers[eventId][i]
            local scope = eventScopes[eventId][i]            
            handler scope:scope param:param
        )
    )
    
    fn AddHandler eventName handler scope: = (
        if classof handler == MAXScriptFunction then (
            local nameid = findItem eventNames eventName
            
            local id
            if nameid == 0 then (
                id = eventHandlers.count + 1
                eventHandlers[id] = #()
                eventScopes[id] = #()
                append eventNames eventName
                append eventIds id
                
                callbacks.addScript eventName ("Max4ds_Events.Fire " + id as string) id:#Max4ds_Events
            )
            else (
                id = eventIds[nameid]
            )
            
            append eventHandlers[id] handler
            append eventScopes[id] scope
        )
    )
    
    fn RemoveHandler eventName handler = (
        local nameid = findItem eventNames eventName
        
        if nameId != 0 then (
            local id = eventIds[nameId]
            local handlerId = findItem eventHandlers[id] handler
            
            if handlerId != 0 then (
                deleteItem eventHandlers[id] handlerId
                deleteItem eventScopes[id] handlerId
                
                if eventHandlers[id].count == 0 then (
                    deleteItem eventNames nameid
                    deleteItem eventIds nameId
                    
                    callbacks.removeScripts eventName id:#Max4ds_Events
                )
                
                --cleanup
                
                local done = false
                
                for i = eventHandlers.count to 1 by -1 while not done do (
                    if eventHandlers[i].count == 0 then deleteItem eventHandlers i
                    else done = true
                )
            )
        )
    )

    fn ListHandlers = (
        for eventId = 1 to eventHandlers.count do (
            format "%: " eventId
            for handler in eventHandlers[eventId] do (
                format "%, " handler
            )
            format "\n"
        )
    )

)