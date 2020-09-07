struct Stopwatch (
    timeStart,
    
    fn StartNew = (
        Stopwatch()
    ),
    
    fn Elapsed = (
        local end = timeStamp()
        
        if end < timeStart then end += 86400000 --timing over midnight
        (end - timeStart)
    ),
    
    fn OnCreate = (
        timeStart = timeStamp()
    ),
    
    init = OnCreate()
)