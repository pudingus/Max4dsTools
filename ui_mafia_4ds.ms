global MafiaTools
utility MafiaTools "Mafia 4DS Tools v4"
(
	checkbox    importNormals       "Normals to modifier (slow)" 	default:true
	button      btnImport           "Import..." align:#left
	checkbox    exportNormals       "Normals from modifier (slow)" offset:[0,20]
	button      btnExport           "Export All..." align:#left
	label       bout                "by pudingus" offset:[0,20]


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
