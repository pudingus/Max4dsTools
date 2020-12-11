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

    label       lblAuthor         "by pudingus" offset:[0,20]
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