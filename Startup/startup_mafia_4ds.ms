(
	local set_heapsize = 64 * 1024 * 1024  --64 MiB
	if heapsize < set_heapsize then heapsize = set_heapsize
	

	filein "mafia_4ds\\MafMat4.ms"

	filein "mafia_4ds\\MafParams.ms"

	filein "mafia_4ds\\ui_mafia_4ds.ms"	
)

callbacks.addScript #systemPostNew "PostNew()" id:#MafiaTools
callbacks.addScript #systemPostReset "PostNew()" id:#MafiaTools

callbacks.addScript #filePostOpen "PostOpen()" id:#MafiaTools
callbacks.addScript #filePostSave "PostSave()" id:#MafiaTools

fn PostNew = (
	MafiaTools.editName.text = ""
)

fn PostOpen = (
	MafiaTools.editName.text = getFilenameFile maxFileName
)

fn PostSave = (
	if MafiaTools.editName.text == "" then (
		MafiaTools.editName.text = getFilenameFile maxFileName
	)	
)

format "Mafia 4DS Tools % loaded\n" MafiaTools.version.caption
