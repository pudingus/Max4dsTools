macroScript ImportExport
category:"4ds Tools"
internalCategory:"Max4ds"
buttonText:"4ds Imp/Exp"
toolTip:"4ds Import Export..."
(
    on execute do (
        filein (::MafiaTools_scriptsPath + "ui_imp_exp.ms")
    )
)

macroScript ParamEditor
category:"4ds Tools"
internalCategory:"Max4ds"
buttonText:"4ds Params"
toolTip:"4ds Object Parameters..."
(
    on execute do (
        filein (::MafiaTools_scriptsPath + "ui_param_editor.ms")
    )
)

macroScript FindWeights
category:"4ds Tools"
internalCategory:"Max4ds"
buttonText:"4ds Weights"
toolTip:"Find weight conflicts..."
(
    on execute do (
        filein (::MafiaTools_scriptsPath + "ui_find_weights.ms")
    )
)

macroScript ConvertSkeleton
category:"4ds Tools"
internalCategory:"Max4ds"
buttonText:"4ds Conv.Skel"
toolTip:"Convert old skeleton..."
(
    on execute do (
        filein (::MafiaTools_scriptsPath + "ui_convert_skeleton.ms")
    )
)