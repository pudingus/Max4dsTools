(
    local set_heapsize = 64 * 1024 * 1024  --64 MiB
    if heapsize < set_heapsize then heapsize = set_heapsize
   
    global MafiaTools_version = "v0.7.0-preview"
    global MafiaTools_scriptsPath = getFilenamePath (getThisScriptFilename())    

    global MafiaTools_ImpExpSettings
    (
        struct settings (
            importPath,
            exportPath,
            exportFilename,
            position,
            editNorm,
            cachedNorm,
            unitsSel = 4,
            useImportedFilename = false,
            allow5ds,
            versionSel = 1
        )
        ::MafiaTools_ImpExpSettings = settings()
    )
    
    fn DisableScript file = (
        if doesFileExist file then (
            local path = getFilenamePath file
            local name = filenameFromPath file
            local success = renameFile file (path + "\\" + name + "__off")            
        )
    )
    
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
    
    filein "ui_utility.ms"    


    format "Max 4ds Tools % loaded\n" MafiaTools_version
)
callbacks.removeScripts #systemPostNew id:#MafiaTools
callbacks.removeScripts #systemPostReset id:#MafiaTools
callbacks.addScript #systemPostNew "PostReset()" id:#MafiaTools
callbacks.addScript #systemPostReset "PostReset()" id:#MafiaTools

fn PostReset = (
    ::MafiaTools_ImpExpSettings.useImportedFilename = false
    ::MafiaTools_ImpExpSettings.allow5ds = false
    if ::ImpExp != undefined then ::ImpExp.cbAllow5ds.checked = false
)
