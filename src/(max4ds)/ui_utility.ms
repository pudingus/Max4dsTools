MafiaTools_reopen = false
if MafiaTools != undefined and MafiaTools.isDisplayed do (
    setCommandPanelTaskMode #utility   --this is to prevent utility from not closing
    closeUtility MafiaTools
    MafiaTools_reopen = true
)

utility MafiaTools "4ds Max Tools"
(
    button      btnImportExport   "Import/Export..." align:#left
    button      btnParamEditor    "Object parameters..." align:#left
    button      btnFindWeights    "Find weight conflicts..." align:#left
    button      btnConvertSkeleton "Convert old skeleton..." align:#left

    label       lblAuthor         "by pudingus" offset:[0,20]
    label       lblVersion        "v0.5.0-preview"

    on btnImportExport pressed do
    (
        filein (::MafiaTools_scriptsPath + "ui_imp_exp.ms")
    )

    on btnParamEditor pressed do
    (
        filein (::MafiaTools_scriptsPath + "ui_param_editor.ms")
    )

    on btnFindWeights pressed do (
        filein (::MafiaTools_scriptsPath + "ui_find_weights.ms")
    )
    
    on btnConvertSkeleton pressed do (
        filein (::MafiaTools_scriptsPath + "ui_convert_skeleton.ms")
    )
)
if MafiaTools_reopen do openUtility MafiaTools