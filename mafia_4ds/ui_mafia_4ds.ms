global MafiaTools
utility MafiaTools "Mafia 4DS Tools v4"
(
	checkbox     importNormals     "Import normals (slow)"
	button       btnImport         "Import..." align:#left
	
	radiobuttons exportNormals     "Export normals:" labels:#("Smoothing groups", "Edit_Normals (slow)") align:#left offset:[0,20] 
	edittext     editName           align:#left offset:[0,10]  text:""
	button       btnExport         "Export all..." align:#left
	label        bout              "by pudingus" offset:[0,20]
	label        version              "v0.2.1"

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
