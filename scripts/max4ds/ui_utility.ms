if Max4dsTools != undefined and Max4dsTools.isDisplayed do (
    setCommandPanelTaskMode #utility   --this is to prevent utility from not closing
    closeUtility Max4dsTools
)

utility Max4dsTools "Max 4ds Tools"
(
    button      btnImportExport   "Import/Export..." align:#left
    button      btnParamEditor    "Object parameters..." align:#left
    button      btnFindWeights    "Find weight conflicts..." align:#left
    button      btnConvertSkeleton "Convert old skeleton..." align:#left
    hyperLink   hprHelp           "Help" address:"https://github.com/pudingus/Max4dsTools/wiki" offset:[0,10] align:#center color:[3, 173, 252] hoverColor:[3, 173, 252] visitedColor:[3, 173, 252]

    label       lblAuthor         "by pudingus" offset:[0,3]
    label       lblVersion        "version"
    
    on Max4dsTools open do (
        lblVersion.text = ::Max4ds_version
    )

    on btnImportExport pressed do (
        ::Max4ds_ImpExp.Toggle()
    )

    on btnParamEditor pressed do (
        ::Max4ds_ParamEditor.Toggle()
    )

    on btnFindWeights pressed do (
        ::Max4ds_FindWeights.Toggle()
    )
    
    on btnConvertSkeleton pressed do (
        ::Max4ds_ConvertSkeleton.Toggle()
    )
)
openUtility Max4dsTools