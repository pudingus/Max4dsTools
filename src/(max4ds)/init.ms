(
    local set_heapsize = 48 * 1024 * 1024  --48 MiB
    if heapsize < set_heapsize then heapsize = set_heapsize
   
    global MafiaTools_version = "v0.5.0-preview"
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
            filenameForExport
        )
        ::MafiaTools_ImpExpSettings = settings()
    )
    
    
    local src = MafiaTools_scriptsPath + "\\max4ds_macros.mcr"
    local dst = (getdir #usermacros) + "\\max4ds_macros.mcr"
    deleteFile dst
    copyFile src dst

    macros.load MafiaTools_scriptsPath
        
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

    format "4ds Max Tools % loaded\n" MafiaTools_version
)
callbacks.removeScripts #systemPostNew id:#MafiaTools
callbacks.removeScripts #systemPostReset id:#MafiaTools
callbacks.removeScripts #postSystemStartup id:#MafiaTools
callbacks.addScript #systemPostNew "PostReset()" id:#MafiaTools
callbacks.addScript #systemPostReset "PostReset()" id:#MafiaTools
callbacks.addScript #postSystemStartup "PostStartup()" id:#MafiaTools


fn PostReset = (
    ::MafiaTools_ImpExpSettings.filenameForExport = undefined    
)

fn PostStartup = (
    openUtility ::MafiaTools    
	callbacks.removeScripts #postSystemStartup id:#MafiaTools
)
