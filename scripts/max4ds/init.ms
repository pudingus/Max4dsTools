(
    local set_heapsize = 48 * 1024 * 1024  --48 MiB
    if heapsize < set_heapsize then heapsize = set_heapsize
   
    global MafiaTools_version = "v0.5.0-preview"
    global MafiaTools_scriptsPath = getFilenamePath (getThisScriptFilename()) 
    

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

-- callbacks.addScript #systemPostNew "PostNew()" id:#MafiaTools
-- callbacks.addScript #systemPostReset "PostNew()" id:#MafiaTools

-- callbacks.addScript #filePostOpen "PostOpen()" id:#MafiaTools
-- callbacks.addScript #filePostSave "PostSave()" id:#MafiaTools

-- fn PostNew = (
--  MafiaTools.editName.text = ""
-- )

-- fn PostOpen = (
--  MafiaTools.editName.text = getFilenameFile maxFileName
-- )

-- fn PostSave = (
--  if MafiaTools.editName.text == "" then (
--      MafiaTools.editName.text = getFilenameFile maxFileName
--  )
-- )

--format "Mafia 4ds Import/Export plugin % loaded\n" MafiaTools.version.caption