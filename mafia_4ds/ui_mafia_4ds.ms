global MafiaTools
utility MafiaTools "Mafia 4DS Tools v4"
(
	checkbox     importNormals     "Import normals (slow)"
	button       btnImport         "Import..." align:#left

	radiobuttons exportNormals     "Export normals:" labels:#("Smoothing groups", "Edit_Normals (slow)") align:#left offset:[0,20] 
	button       btnExport         "Export all..." align:#left
	label        bout              "by pudingus" offset:[0,20]

	on btnImport pressed do
	(		
		filein "import_mafia_4ds.ms"		
	)

	on btnExport pressed do
	(		
		filein "export_mafia_4ds.ms"		
	)
)
openUtility MafiaTools
