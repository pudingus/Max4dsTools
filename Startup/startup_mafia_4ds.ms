(
    local set_heapsize = 64 * 1024 * 1024  --64 MiB
    if heapsize < set_heapsize then heapsize = set_heapsize
)

filein "mafia_4ds\\MafLod4.ms"
filein "mafia_4ds\\MafMat4.ms"
filein "mafia_4ds\\MafObject4.ms"
filein "mafia_4ds\\MafPortal4.ms"

filein "mafia_4ds\\ui_mafia_4ds.ms"

print "Mafia 4DS Tools loaded"