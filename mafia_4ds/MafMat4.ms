plugin material MafMat4
name:"4ds Material v4"
classID:#(0x61cbf531, 0x2197994)
extends:Standard
replaceUI:true
version:2 
remap:#(#(#isAnimatedM,#useMips,#useColoring,#useColorKey,#useAddBlend),#(#animatedDiffuse,#mipMapping,#colored,#colorKey,#additiveMixing))
(
	parameters main rollout:params
	(		
		ambient 		type:#color 		ui:ambient 			default:[25,25,25]		
		diffuse 		type:#color 		ui:diffuse 			default:[127,127,127]
		emission 		type:#color 		ui:emission		
		opacity 		type:#integer 		ui:opacity 			default:100		
		diffuseMapEnable type:#boolean 		ui:diffuseMapEnable				
		'Diffuse Map'	type:#texturemap 	ui:diffuseMap		
		envMapEnable 	type:#boolean 		ui:envMapEnable
		envMapAmount 	type:#integer 		ui:envMapAmount 	default:100
		'Env Map' 		type:#texturemap 	ui:envMap
		alphaMapEnable 	type:#boolean 		ui:alphaMapEnable		
		'Alpha Map' 	type:#texturemap 	ui:alphaMap
		twoSided 		type:#boolean 		ui:twoSided

		--19 - Diffuse Map
		colored 		type:#boolean 		ui:colored			default:false 	--28
		mipMapping 		type:#boolean 		ui:mipMapping 		default:true 	--24
		animatedDiffuse	type:#boolean 		ui:animatedDiffuse	default:false 	--27  --animovaná textura difuze
		animFrames 		type:#integer 		ui:animFrames		default:1 		
		animPeriod 		type:#integer 		ui:animPeriod		default:1 		

		--20 - Environment Map
		envOverlay 		type:#boolean 		ui:envOverlay		default:true 	--9
		envMultiply 	type:#boolean 		ui:envMultiply		default:false 	--10
		envAdditive 	type:#boolean 		ui:envAdditive		default:false 	--11
		YProj 			type:#boolean 		ui:YProj			default:true 	--13
		YDetail 		type:#boolean 		ui:YDetail			default:false 	--14
		ZDetail 		type:#boolean 		ui:ZDetail			default:false 	--15

		--16 - Additional Effect
		addEffect 		type:#boolean  		ui:addEffect		default:false	--16
		colorKey 		type:#boolean  		ui:colorKey			default:false	--30
		additiveMixing 	type:#boolean  		ui:additiveMixing	default:false	--32
		animatedAlpha 	type:#boolean  		ui:animatedAlpha	default:false
		
		
		on ambient set val do delegate.ambient = val
		on diffuse set val do delegate.diffuse = val
		on emission set val do delegate.selfIllumColor = val		
		on opacity set val do delegate.opacity = val
		on diffuseMapEnable set val do delegate.diffuseMapEnable = val
		on 'Diffuse Map' set val do (
			delegate.diffuseMap = val		
			if val != undefined then diffuseMapEnable = true
			else diffuseMapEnable = false
		)
		on envMapEnable set val do delegate.reflectionMapEnable = val
		on envMapAmount set val do delegate.reflectionMapAmount = val
		on 'Env Map' set val do (
			delegate.reflectionMap = val
			if val != undefined then envMapEnable = true
			else envMapEnable = false
		)				
		on alphaMapEnable set val do delegate.opacityMapEnable = val
		on 'Alpha Map' set val do (
			delegate.opacityMap = val
			if val != undefined then alphaMapEnable = true
			else alphaMapEnable = false
		)
		on twoSided set val do delegate.twoSided = val
	)
	rollout params "4DS Params"
	(		
		colorpicker ambient "Ambient" across:2
		colorpicker emission "Emission"
		colorpicker diffuse "Diffuse" across:2	 offset:[5,0]	
		spinner opacity "Opacity  " type:#integer align:#left fieldwidth:30 type:#integer
		
		--label ui_diffuseMap			"Diffuse Map"
		label a ""
		
		group "Diffuse Map" (
			checkbox diffuseMapEnable "Enable diffuse map " across:2
			mapbutton diffuseMap	"diff" tooltip:"kek" width:165 height:17 align:#right
			--label aa ""
			
			label bb ""
			checkbox twoSided 			"2-Sided" 		align:#left across:2
			checkbox animatedDiffuse 	"Animated" 		align:#left 	
			
			checkbox colored 			"Colored" 		across:2
			spinner animFrames 			"Frames" 		range:[0,1000,1] align:#left fieldwidth:40 type:#integer	offset:[3,2]

			
			checkbox mipMapping 		"Mip mapping" 	align:#left across:2	
			spinner animPeriod 			"Period " 		range:[0,3600000,1] align:#left fieldwidth:40 type:#integer offset:[5,0]
			label afasfa ""
		)
		
		label b ""
		group "Environment Map" (
			checkbox envMapEnable "Enable env. map" across:3
			spinner envMapAmount "" fieldwidth:30 type:#integer align:#left
			mapbutton envMap 	"Environment map" width:165 height:17 align:#right 
			
			label bbc ""			

			checkbox envOverlay		"Overlay" 		across:2
			checkbox YProj 			"Y proj" 
			
			checkbox envMultiply 	"Multiply" 		across:2
			checkbox YDetail		"Y detail" 	
			
			checkbox envAdditive  	"Additive" 		across:2
			checkbox ZDetail		"Z detail" 				
		)
		
		label c ""
		group "Add Effect" (
			checkbox addEffect		"Add effect" 		align:#left fieldwidth:48
			checkbox alphaMapEnable "Enable alpha map" 	across:2
			mapbutton alphaMap 		"Alpha map"    		width:165 height:17 align:#right
			checkbox animatedAlpha	"Animated alpha map" aligh:#left
			checkbox colorKey		"Color key" 		align:#left fieldwidth:48
			checkbox additiveMixing	"Additive mixing"	align:#left fieldwidth:48
		)
		label d ""
		groupBox group1 "" pos:[160,124] width:120 height:75 
	)
	
	on create do (
		delegate.adLock = false
	)

	on update do (
		--format "update lol version: % \n" version

		if version == 1 then (
			delegate.adLock = false

			ambient = delegate.ambient
			diffuse = delegate.diffuse
			emission = delegate.selfIllumColor
			
			opacity = delegate.opacity

			diffuseMapEnable = delegate.diffuseMapEnable
			'Diffuse Map' = delegate.diffuseMap

			envMapEnable = delegate.reflectionMapEnable
			envMapAmount = delegate.reflectionMapAmount
			'Env Map' = delegate.reflectionMap

			alphaMapEnable = delegate.opacityMapEnable
			'Alpha Map' = delegate.opacityMap

			twoSided = delegate.twoSided

		)
	)
)