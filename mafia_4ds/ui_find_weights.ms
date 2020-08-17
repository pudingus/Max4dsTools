(
	rollout FindWeights "Find distant weights"
	(
		button find "Find" 
		listbox lbFound "" height:8
		label numSel ""
		listbox lbSel "" height:5
		label lblTransfer "Transfer weights:"
		button transfer1 "back3  ->  r_shoulder"
		button transfer2 "r_arm  ->  r_shoulder"
		
		local groups = #()
		local groupsExtra = #()
		
		fn isNodeDescendantOf node1 node2 = (
			while node1.parent != undefined and node1.parent != node2 do (
				node1 = node1.parent
			)
			node1.parent == node2 
		)
		
		fn traverseUp lowNode highNode = (
			local nodes = #()
			while lowNode.parent != highNode do (
				lowNode = lowNode.parent
				append nodes lownode
			)
			nodes
		)
		
		local boneNodes
		
		struct WeightGroup (
			boneid1,
			boneid2,
			verts = #{},
			weightSum1 = 0.0,
			weightSum2 = 0.0
		)
		
		fn FindGroup groups boneid1 boneid2 = (
			local foundGrp
			for grp in groups while foundGrp == undefined do (
				if (grp.boneid1 == boneid1 and grp.boneid2 == boneid2) or (grp.boneid1 == boneid2 and grp.boneid2 == boneid1) then (
					foundGrp = grp
				)
			)
			foundGrp
		)
		
		fn directlyRelated node1 node2 = (
			node1.parent == node2 or node2.parent == node1
		)
		
		fn GetBoneVertexWeight skinMod vertid boneid = (
			local weight
			local count = skinOps.GetVertexWeightCount skinMod vertid		
			local nth
			for i = 1 to count while nth == undefined do (
				id = skinOps.GetVertexWeightBoneID skinMod vertid i
				if id == boneid then nth = i
			)
			if nth != undefined then (
				weight = skinOps.GetVertexWeight skinMod vertid nth
			)
			weight
		)
		
		fn TransferWeight skinMod vertid oldId newId = (
			local weight = GetBoneVertexWeight skinMod vertid oldid
			
			if weight != undefined then (
				skinOps.SetVertexWeights skinMod vertid oldid 0.0
				skinOps.SetVertexWeights skinMod vertid newid weight	
			)
		)	
		
		struct GroupExtra (
			avg1,
			avg2,
			upnodes = #(),
			upBoneIds = #()
		)
		
		
		fn ReverseArray arr = (
			local newArr = #()
			for i = 1 to arr.count do (
				append newArr arr[arr.count-i+1]
			)
			newArr
		)
	
		on find pressed do (
			boneNodes = for k in (refs.dependsOn $.skin) where (isKindOf k node) collect k			
			groups = #()	
			groupsExtra = #()
			local numverts = skinOps.GetNumberVertices $.skin
			
			for i = 1 to numverts do (
				local count = skinOps.GetVertexWeightCount $.skin i
				
				if count > 1 then (
					local boneid1 = skinOps.GetVertexWeightBoneID $.skin i 1
					local boneid2 = skinOps.GetVertexWeightBoneID $.skin i 2											
					local boneNode1 = boneNodes[boneid1]
					local boneNode2 = boneNodes[boneid2]						
					
					
					if not directlyRelated bonenode1 bonenode2 then (
						local weight1 = skinOps.GetVertexWeight $.skin i 1
						local weight2 = skinOps.GetVertexWeight $.skin i 2
						
						if isNodeDescendantOf boneNode2 boneNode1 then (
							swap boneid1 boneid2
							swap weight1 weight2
							swap boneNode1 boneNode2
						)						
					
						local grp = FindGroup groups boneid1 boneid2
					
						if grp == undefined then (
							grp = WeightGroup()
							grp.boneid1 = boneid1
							grp.boneid2 = boneid2
							append groups grp
						)
						
						grp.verts[i] = true	
						grp.weightSum1 += weight1
						grp.weightSum2 += weight2				
					)	
				)		
			)
			
			local items = #()
			for grp in groups do (
				local bonename1 = boneNodes[grp.boneid1].name
				local bonename2 = boneNodes[grp.boneid2].name
				
				local item = bonename2 + " ... [ " + bonename1 + " ]    " + (grp.verts.numberset as string) + " verts"	
				append items item				
			)	
			lbFound.items = items
			
			for i = 1 to groups.count do (
				local grp = groups[i]
				grpE = GroupExtra()
				
				grpE.avg1 = grp.weightSum1 / grp.verts.numberset
				grpE.avg2 = grp.weightSum2 / grp.verts.numberset
				
				local bonenode1 = bonenodes[grp.boneid1]
				local bonenode2 = bonenodes[grp.boneid2]	
				local upnodes = traverseUp bonenode1 bonenode2			--in order from lowest to highest, 1-lowest  N-highest
				upnodes = ReverseArray upnodes
				
				grpE.upnodes = upnodes
				
				for i = 1 to upnodes.count do (
					grpE.upBoneIds[i] = findItem bonenodes upnodes[i]
				)
				
				append groupsExtra grpE
			)
		)
		
		
		local lbSelItemBoneId = #()
		on lbFound selected val do (
			local grp = groups[val]
			local grpE = groupsExtra[val]
			subObjectLevel = 1
			skinOps.SelectVertices $.skin grp.verts
			skinOps.SelectBone $.skin grp.boneid1
			
			
			local bonenode1 = bonenodes[grp.boneid1]
			local bonenode2 = bonenodes[grp.boneid2]					
			
			local items = #()
			
			items[1] = bonenode2.name		
			for i = 1 to grpE.upnodes.count do (
				items[i+1] = grpE.upnodes[i].name
			)
			append items bonenode1.name
				
			items[1] = items[1] + "    avg.weight: " + (formattedPrint grpE.avg2 format:".3f")
			items[items.count] = items[items.count] + "    avg.weight: " + (formattedPrint grpE.avg1 format:".3f")			
			
			
			--indent--
			local totalIndent = "  "
			local indent = "  "
			for i = 2 to items.count do (
				items[i] = totalIndent + items[i]
				totalIndent += indent
			)
			----------
			
			lbSel.items = items
			lbSel.selection = items.count			
		
			lbSelItemBoneId[1] = grp.boneid2			
			for i = 1 to grpE.upnodes.count do (
				lbSelItemBoneId[i+1] = grpE.upBoneIds[i]
			)			
			append lbSelItemBoneId grp.boneid1
			
			transfer1.text = bonenode2.name + "  ->  " + grpE.upnodes[1].name			
			transfer2.text = bonenode1.name + "  ->  " + grpE.upnodes[grpE.upnodes.count].name
			
 			local sk = $.skin
			
			sk.wt_activeVertexSet = 2
			sk.wt_activeVertexSet = 1
		)
		
		on lbSel selected val do (
			skinOps.SelectBone $.skin lbSelItemBoneId[val]
		)
		
		on transfer1 pressed do (
			local sel = lbFound.selection
			local grp = groups[sel]
			local grpE = groupsExtra[sel]
			
			local bonenode1 = bonenodes[grp.boneid1]
			local bonenode2 = bonenodes[grp.boneid2]
			
			local oldId = grp.boneid2
			local newId = grpE.upBoneIds[1]
			
			for vertId in grp.verts do (				
				TransferWeight $.skin vertId oldid newId
			)		
		)
		
		on transfer2 pressed do (
			local sel = lbFound.selection
			local grp = groups[sel]
			local grpE = groupsExtra[sel]
			
			local bonenode1 = bonenodes[grp.boneid1]
			local bonenode2 = bonenodes[grp.boneid2]			
			
			local oldId = grp.boneid1
			local newId = grpE.upBoneIds[grpE.upBoneIds.count]
			
			for vertId in grp.verts do (				
				TransferWeight $.skin vertId oldid newId
			)
		)
	)
	CreateDialog FindWeights width:240 height:350 style:#(#style_resizing, #style_titlebar, #style_sysmenu)	
)