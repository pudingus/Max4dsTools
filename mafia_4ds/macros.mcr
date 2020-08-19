macroScript M4dsImportExport
category:"4dsTools"
buttonText:"4ds Imp/Exp"
toolTip:"4ds Import Export"
autoUndoEnabled:false
(
    on execute do (
        filein (::MafiaTools_scriptsPath+"ui_imp_exp.ms")
    )
)

macroScript M4dsParamEditor
category:"4dsTools"
buttonText:"4ds Params"
toolTip:"4ds Object Parameters"
autoUndoEnabled:false
(
    on execute do (
        filein (::MafiaTools_scriptsPath+"ui_param_editor.ms")
    )
)

macroScript M4dsFindWeights
category:"4dsTools"
buttonText:"4ds Weights"
toolTip:"Find distant weights"
autoUndoEnabled:false
(
    on execute do (
        filein (::MafiaTools_scriptsPath+"ui_find_weights.ms")
    )
)