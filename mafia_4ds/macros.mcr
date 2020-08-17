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
buttonText:"4ds Prm.Ed."
toolTip:"4ds Parameter Editor"
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
        filein (::MafiaTools_scriptsPath+"find_weights.ms")		
    )		
)