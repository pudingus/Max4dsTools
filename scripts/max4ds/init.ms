(
    local set_heapsize = 64 * 1024 * 1024  --64 MiB
    if heapsize < set_heapsize then heapsize = set_heapsize
   
    global Max4ds_version = "v0.8.0"
    --global Max4ds_scriptsPath = getFilenamePath (getThisScriptFilename())
    
    fn DisableScript file = (
        if doesFileExist file then (
            local path = getFilenamePath file
            local name = filenameFromPath file
            local success = renameFile file (path + "\\" + name + "__off")
        )
    )
    
    --disable old 0.4.x scripts
    local name = "startup_mafia_4ds.ms"
    local file = (getdir #userStartupScripts) + "\\" + name
    local file2 = (getdir #startupScripts) + "\\" + name
    DisableScript file
    DisableScript file2
    
    filein "events.ms"
    
    --scriptedPlugins
    filein "material.ms"
    filein "MafParams.ms"
    filein "cached_normals.ms"
    filein "target.ms"
    filein "glow.ms"

    --
    filein "skin_compat.ms"
    filein "util.ms"
    filein "layers.ms"
    
    filein "4ds_parser.ms"
    filein "4ds_import.ms"
    filein "4ds_export.ms"
    
    filein "ui_imp_exp.ms"
    filein "ui_param_editor.ms"
    filein "ui_find_weights.ms"
    filein "ui_convert_skeleton.ms"
    
    filein "ui_utility.ms"
    
    
    fn PreSave = (
        --version of the scene, for potential future use
        setAppData rootNode 3298216 "1"
    )
    
    local events = ::Max4ds_Events
    events.removeHandler #filePreSave PreSave
    events.addHandler #filePreSave PreSave
    

    format "Max 4ds Tools % loaded\n" Max4ds_version
)
