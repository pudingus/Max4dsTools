macroScript Max4ds_ImportExport
category:"4ds Max Tools"
internalCategory:"Max4ds"
buttonText:"4ds Imp/Exp"
toolTip:"4ds Import Export"
--autoUndoEnabled:false
(
    on execute do (
        filein (::MafiaTools_scriptsPath + "ui_imp_exp.ms")
    )
)

macroScript Max4ds_ParamEditor
category:"4ds Max Tools"
internalCategory:"Max4ds"
buttonText:"4ds Params"
toolTip:"4ds Object Parameters"
--autoUndoEnabled:false
(
    on execute do (
        filein (::MafiaTools_scriptsPath + "ui_param_editor.ms")
    )
)

macroScript Max4ds_FindWeights
category:"4ds Max Tools"
internalCategory:"Max4ds"
buttonText:"4ds Weights"
toolTip:"Find weight conflicts"
--autoUndoEnabled:false
(
    on execute do (
        filein (::MafiaTools_scriptsPath + "ui_find_weights.ms")
    )
)