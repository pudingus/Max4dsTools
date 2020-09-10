(
    local set_heapsize = 48 * 1024 * 1024  --48 MiB
    if heapsize < set_heapsize then heapsize = set_heapsize
   
    global MafiaTools_version = "v0.5.0-preview"
    global MafiaTools_scriptsPath = getFilenamePath (getThisScriptFilename()) 
    
    ::MafiaTools_ImpExpSettings = undefined        
        
    --scriptedPlugins
    filein "material.ms"
    filein "MafParams.ms"
    filein "cached_normals.ms"
    filein "target.ms"
    filein "glow.ms"

    --
    filein "util.ms"
    filein "layers.ms"
    filein "stopwatch.ms"
    filein "4ds_parser.ms"
    filein "4ds_import.ms"
    filein "4ds_export.ms"

    filein "ui_utility.ms"


    format "4ds Max Tools % loaded\n" MafiaTools_version
)

callbacks.removeScripts #systemPostNew id:#MafiaTools
callbacks.removeScripts #systemPostReset id:#MafiaTools
callbacks.addScript #systemPostNew "PostReset()" id:#MafiaTools
callbacks.addScript #systemPostReset "PostReset()" id:#MafiaTools

fn PostReset = (
    if ::MafiaTools_ImpExpSettings != undefined then (
        ::MafiaTools_ImpExpSettings.filenameForExport = undefined
    )
)
