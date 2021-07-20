macroScript ImportExport
category:"4ds Tools"
internalCategory:"Max4ds"
buttonText:"4ds Imp/Exp"
toolTip:"4ds Import Export..."
(
    on execute do (
        ::Max4ds_ImpExp.Toggle()
    )
)

macroScript ParamEditor
category:"4ds Tools"
internalCategory:"Max4ds"
buttonText:"4ds Params"
toolTip:"4ds Object Parameters..."
(
    on execute do (
        ::Max4ds_ParamEditor.Toggle()
    )
)

macroScript FindWeights
category:"4ds Tools"
internalCategory:"Max4ds"
buttonText:"4ds Weights"
toolTip:"Find weight conflicts..."
(
    on execute do (
        ::Max4ds_FindWeights.Toggle()
    )
)

macroScript ConvertSkeleton
category:"4ds Tools"
internalCategory:"Max4ds"
buttonText:"4ds Conv.Skel"
toolTip:"Convert old skeleton..."
(
    on execute do (
        ::Max4ds_ConvertSkeleton.Toggle()
    )
)