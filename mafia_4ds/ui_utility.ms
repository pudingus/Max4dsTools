
if MafiaTools != undefined and MafiaTools.open then closeUtility MafiaTools
utility MafiaTools "Mafia 4ds Import/Export"
(
	button       btnImportExport   "Import/Export..." align:#left
	button       btnParamEditor    "Parameter editor..." align:#left
	--button       btnBitmapPaths   "Texture paths..." align:#left
	button 		btnSettings "Settings..." align:#left

	label        bout              "by pudingus" offset:[0,20]
	label        version              "v0.5.0-preview"

	on btnImportExport pressed do
	(		
		filein "ui_imp_exp.ms"		
	)

	on btnParamEditor pressed do
	(		
		filein "ui_param_editor.ms"		
	)
	
	-- on btnBitmapPaths pressed do
	-- (		
	-- 	configureBitmapPaths()		
	-- )

	
	
)
openUtility MafiaTools
