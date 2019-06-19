plugin material MafMat4
name:"4DS Material v4"
classID:#(0x61cbf531, 0x2197994)
extends:Standard
(
	parameters main rollout:params
	(
		--19 - Diffuse Map
		useColoring 	type:#boolean 	default:false 	ui:ui_useColoring		--28
		useMips 		type:#boolean 	default:true 	ui:ui_useMips 			--24
		--is2Sided type:#boolean default:false ui:ui_is2Sided		--29
		isAnimatedM 	type:#boolean 	default:false 	ui:ui_isAnimated	--27  --animovaná textura difuze
		animFrames 		type:#integer 	default:1 		ui:ui_animFrames
		animPeriod 		type:#integer 	default:1 		ui:ui_animPeriod

		--20 - Environment Map
		--envRatio type:#float default:1.0 ui:ui_envRatio
		envOverlay type:#boolean default:false ui:ui_envOverlay		--9
		envMultiply type:#boolean default:false ui:ui_envMultiply	--10
		envAdditive type:#boolean default:false ui:ui_envAdditive	--11
		YProj type:#boolean default:false ui:ui_YProj				--13
		YDetail type:#boolean default:false ui:ui_YDetail			--14
		ZDetail type:#boolean default:false ui:ui_ZDetail			--15

		--16 - Additional Effect
		addEffect type:#boolean default:false ui:ui_addEffect		--16
		--useAlphaMap type:#boolean default:false ui:ui_useAlphaMap	--31
		useColorKey type:#boolean default:false ui:ui_useColorKey	--30
		useAddBlend type:#boolean default:false ui:ui_useAddBlend	--32
	)
	rollout params "4DS Params"
	(
		label ui_diffuseMap			"Diffuse Map"
		checkbox ui_useColoring 	"Coloring" 			align:#left fieldwidth:48
		checkbox ui_useMips 		"Mip Mapping" 		align:#left fieldwidth:48
		--checkbox ui_is2Sided 		"2 Sided" 			align:#left fieldwidth:48
		checkbox ui_isAnimated 		"Animated" 			align:#left fieldwidth:48
		spinner ui_animFrames 		"Frame Count" 		range:[0,1000,1] align:#left fieldwidth:40
		spinner ui_animPeriod 		"Frame Period" 		range:[0,3600000,1] align:#left fieldwidth:40
		label ui_environmentMap		"Environment Map"
		--spinner ui_envRatio 		"Ratio" 			range:[0,1,1] align:#left fieldwidth:40
		checkbox ui_envOverlay 		"Overlay" 			align:#left fieldwidth:48
		checkbox ui_envMultiply 	"Multiply" 			align:#left fieldwidth:48
		checkbox ui_envAdditive  	"Additive" 			align:#left fieldwidth:48
		checkbox ui_YProj 			"Y Projection" 		align:#left fieldwidth:48
		checkbox ui_YDetail			"Y Detail" 			align:#left fieldwidth:48
		checkbox ui_ZDetail			"Z Detail" 			align:#left fieldwidth:48

		label ui_addEffect_label	"Add Effect"
		checkbox ui_addEffect		"Add Effect" 		align:#left fieldwidth:48
		--checkbox ui_useAlphaMap	"Alpha Map" 		align:#left fieldwidth:48
		checkbox ui_useColorKey		"Color Key" 		align:#left fieldwidth:48
		checkbox ui_useAddBlend		"Additive Blend"	align:#left fieldwidth:48
	)
)