plugin modifier CachedNormals
name:"Cached Normals"
classID:#(0x580d250, 0x35f8095)
replaceUI:true version:1 invisible:true
(
	parameters main rollout:params 
	(
		normals type:#point3Tab tabsizevariable:true
		normalFaces type:#point3Tab tabsizevariable:true
	)
	
	rollout params "Parameters"
	(
		button btnEditNormals "View & Edit Normals"
		
		on btnEditNormals pressed do (	

			try (	
				undo "Edit cached normals" on (				
					local index = modPanel.getModifierIndex $ this
					
					local norm = EditNormals()
					norm.displayLength = 0.1
					addModifier $ norm before:(index-1)
					modPanel.setCurrentObject norm
					
					disableRefMsgs()				
						
					for i = 1 to $.numverts do (						
						local vertSel = #{i}
						local normalSel = #{}
						norm.ConvertVertexSelection &vertSel &normalSel
						local normalId = (normalSel as array)[1]
						
						--local normal = meshop.getMapVert $ 2 i	
						local normal = normals[i]
						
						norm.SetNormal normalId normal
					)
					
					norm.MakeExplicit selection:#{1..$.numverts}
			
					enableRefMsgs()
			
					norm.RebuildNormals()
					
					deleteModifier $ this
					modPanel.setCurrentObject norm
				)
			)
			catch (
				local ex = getCurrentException()
				enableRefMsgs()
				messageBox ("Error occured\n" + ex) icon:#critical
			)


			
		)
	)
)
