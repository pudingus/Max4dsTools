fn GetModByClass obj mclass = (    --to support versions prior 2013
	local found = false	
	local foundMod
	for modd in obj.modifiers while not found do (
		if classof modd == mclass then (
			found = true
			foundMod = modd
		)
	)
	foundMod
)

fn IsGeometry obj = (
	Superclassof obj == GeometryClass and ClassOf obj != TargetObject
)

fn containsItem array value = (
	(findItem array value) > 0
)

fn PrintArray arr = (
	local ss = stringstream ""
	format "count: %\n" arr.count to:ss
	for item in arr do (
		format "%\n" item to:ss
	)
	format (ss as string)
)

fn GetNodeType obj = (
	
	if (isKindOf obj BoneGeometry) or (obj.boneEnable) then (
		#bone
	)
	else if IsGeometry obj then (
		local gp = custAttributes.get obj MafParams_def baseObject:false
		
		if matchPattern obj.name pattern:"$portal*" then (
			#portal
		)		
		else if matchPattern obj.name pattern:"$lod*" then (
			#lod
		)
		else if matchPattern obj.name pattern:"sector*" then (					
			#sector
		)		
		else if matchPattern obj.name pattern:"$morph*" then (					
			#morph
		)		
		else if (gp != undefined) and (stricmp gp.objectType "billboard" == 0) then (					
			#billboard
		)
		else if GetModByClass obj Skin != undefined then (
			#singlemesh
		)
		else (
			#mesh
		)				
	)	
	else if isKindOf obj Dummy then (
		#dummy
	)
	else if isKindOf obj TargetObject then (
		#target
	)		
	else #unsupported
)