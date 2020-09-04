macroScript M4dsImportExport
category:"4ds Max"
buttonText:"4ds Imp/Exp"
toolTip:"4ds Import Export"
autoUndoEnabled:false
(
    on execute do (
        filein (::MafiaTools_scriptsPath + "ui_imp_exp.ms")
    )
)

macroScript M4dsParamEditor
category:"4ds Max"
buttonText:"4ds Params"
toolTip:"4ds Object Parameters"
autoUndoEnabled:false
(
    on execute do (
        filein (::MafiaTools_scriptsPath + "ui_param_editor.ms")
    )
)

macroScript M4dsFindWeights
category:"4ds Max"
buttonText:"4ds Weights"
toolTip:"Find weight conflicts"
autoUndoEnabled:false
(
    on execute do (
        filein (::MafiaTools_scriptsPath + "ui_find_weights.ms")
    )
)