if MafiaTools != undefined and MafiaTools.isDisplayed then (
    setCommandPanelTaskMode #utility   --this is to prevent utility from not closing
    closeUtility MafiaTools
)
utility MafiaTools "4ds Max Tools"
(
    button      btnImportExport   "Import/Export..." align:#left
    button      btnParamEditor    "Object parameters..." align:#left
    button      btnFindWeights    "Find distant weights..." align:#left
    button      btnConvertSkeleton "Convert old skeleton..." align:#left

    label       lblAuthor         "by pudingus" offset:[0,20]
    label       lblVersion        "v0.5.0-preview"

    on btnImportExport pressed do
    (
        filein "ui_imp_exp.ms"
    )

    on btnParamEditor pressed do
    (
        filein "ui_param_editor.ms"
    )

    on btnFindWeights pressed do (
        filein "ui_find_weights.ms"
    )
    
    on btnConvertSkeleton pressed do (
        filein "ui_convert_skeleton.ms"
    )
)
openUtility MafiaTools

ok