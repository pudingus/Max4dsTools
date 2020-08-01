global MafiaTools
utility MafiaTools "Mafia 4ds Import/Export"
(
	checkbox     importNormals     "Import normals (slow)"
	button       btnImport         "Import..." align:#left
	
	radiobuttons exportNormals     "Export normals:" labels:#("Smoothing groups", "Edit_Normals (slow)") align:#left offset:[0,20] 
	edittext     editName           align:#left offset:[0,10]  text:""
	button       btnExport         "Export all..." align:#left
	button       btnParamEditor    "Parameter editor..." align:#left
	--button       btnBitmapPaths   "Texture paths..." align:#left

	label        bout              "by pudingus" offset:[0,20]
	label        version              "v0.5.0-preview"

	on btnImport pressed do
	(		
		filein "import_mafia_4ds.ms"		
	)

	on btnExport pressed do
	(		
		filein "export_mafia_4ds.ms"		
	)

	on btnParamEditor pressed do
	(		
		filein "param_editor.ms"		
	)
	
	-- on btnBitmapPaths pressed do
	-- (		
	-- 	configureBitmapPaths()		
	-- )

	
	
)
openUtility MafiaTools
