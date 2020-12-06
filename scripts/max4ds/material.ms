plugin material Mat4ds
name:"4ds Material (p)"
classID:#(0x61cbf531, 0x2197994)
extends:Standard
replaceUI:true
version:3
remap:#(
    #(#isAnimatedM,#useMips,#useColoring,#useColorKey,#useAddBlend),
    #(#animatedDiffuse,#mipMapping,#colored,#colorKey,#additiveMixing)
)
(
    local RefreshAlpha
    local rltParams
    local preview1
    local imageAlphaMap
    
    fn SetMapTile map tileU tileV = (
        if map != undefined and ClassOf map == Bitmaptexture then (
            map.coords.U_Tile = tileU
            map.coords.V_Tile = tileV
        )
    )

    parameters main rollout:rltParams
    (
        ambient         type:#color         ui:cpAmbient            default:[25,25,25]
        diffuse         type:#color         ui:cpDiffuse            default:[127,127,127]
        emission        type:#color         ui:cpEmissive
        specular        type:#color         ui:cpSpecular           default:black
        glossiness      type:#integer       ui:spnGlossiness        default:25
        opacity         type:#integer       ui:spnOpacity           default:100
        diffuseMapEnable type:#boolean      ui:chkDiffuseMapEnable --3
        'Diffuse Map'   type:#texturemap    ui:btnDiffuseMap
        envMapEnable    type:#boolean       ui:chkEnvMapEnable     --4
        envMapAmount    type:#integer       ui:spnEnvMapAmount      default:100
        'Env Map'       type:#texturemap    ui:btnEnvMap
        alphaMapEnable  type:#boolean       ui:chkAlphaMapEnable   --15
        'Alpha Map'     type:#texturemap    ui:btnAlphaMap         
        twoSided        type:#boolean       ui:chkTwoSided         --13

        --Diffuse
        colored         type:#boolean       ui:chkColored           default:false   --12
        mipMapping      type:#boolean       ui:chkMipMapping        default:true    --8
        animatedDiffuse type:#boolean       ui:chkAnimatedDiffuse   default:false   --11
        animFrames      type:#integer       ui:spnFrameCount        default:0
        animPeriod      type:#integer       ui:spnFrameDelay        default:50
        
        tileU           type:#boolean       ui:chkTileU             default:true   --1
        tileV           type:#boolean       ui:chkTileV             default:true   --2
        unknown5        type:#boolean       ui:chkUnknown5          default:false   --5
        unknown6        type:#boolean       ui:chkUnknown6          default:false   --6
        unknown7        type:#boolean       ui:chkUnknown7          default:false   --7
        
        
        --Env
        envTile         type:#integer       ui:spnEnvTile           default:1
        envMode         type:#integer       ui:ddlEnvMode           default:2
        envType         type:#integer       ui:ddlEnvType           default:1

        --Legacy, for compatibility
        envOverlay      type:#boolean  animatable:false
        envMultiply     type:#boolean  animatable:false
        envAdditive     type:#boolean  animatable:false
        YProj           type:#boolean  animatable:false
        YDetail         type:#boolean  animatable:false
        ZDetail         type:#boolean  animatable:false
        addEffect       type:#boolean  animatable:false

        --Alpha
        imageAlpha      type:#boolean       ui:chkImageAlpha       default:false   --9
        colorKey        type:#boolean       ui:chkColorKey         default:false   --14
        additiveMixing  type:#boolean       ui:chkAdditiveMixing   default:false   --16
        animatedAlpha   type:#boolean       ui:chkAnimatedAlpha    default:false   --10

        on ambient set val do (            
            if ::mat4ds_disable_set != true do (   --the condition is like this because 'mat4ds_disable_set' could be undefined
                delegate.ambient = val
            )
        )
        on diffuse set val do (
            if ::mat4ds_disable_set != true do (
                delegate.diffuse = val
            )            
        )
        on diffuse get val do (
            --format "diffuse get \n"
            delegate.diffuse     --this is here so that multimaterial can update the color          
        )
        on emission set val do (
            if ::mat4ds_disable_set != true do (
                delegate.selfIllumColor = val
            )
        )
        on specular set val do (
            if ::mat4ds_disable_set != true do (
                delegate.specular = val
            )
        )
        on opacity set val do (
            if ::mat4ds_disable_set != true do (
                delegate.opacity = val
            )
        )
        on glossiness set val do (
            if ::mat4ds_disable_set != true do (
                delegate.glossiness = val
            )
        )
        on diffuseMapEnable set val do (
            if ::mat4ds_disable_set != true do (                
                delegate.diffuseMapEnable = val
                RefreshAlpha()
            )
        )
        on 'Diffuse Map' set map do (
            if ::mat4ds_disable_set != true do (
                -- no need to call RefreshAlpha here, because it's called after setting 'diffuseMapEnable'
                
                SetMapTile map tileU tileV
                
                delegate.diffuseMap = map
                if map != undefined then diffuseMapEnable = true
                else diffuseMapEnable = false
            )
        )
        on envMapEnable set val do (
            if ::mat4ds_disable_set != true do (
                delegate.reflectionMapEnable = val
            )
        )
        on envMapAmount set val do (
            if ::mat4ds_disable_set != true do (
                delegate.reflectionMapAmount = val
            )
        )
        on 'Env Map' set map do (
            if ::mat4ds_disable_set != true do (
                delegate.reflectionMap = map
                if map != undefined then envMapEnable = true
                else envMapEnable = false
            )
        )
        on alphaMapEnable set val do (
            if ::mat4ds_disable_set != true do (
                RefreshAlpha()
                
                addEffect = colorKey or alphaMapEnable or additiveMixing
            )
        )
        on 'Alpha Map' set map do (
            if ::mat4ds_disable_set != true do (
                SetMapTile map tileU tileV
                
                if not (colorKey or imageAlpha or additiveMixing) then (
                    if map != undefined then alphaMapEnable = true
                    else alphaMapEnable = false
                )
            )
        )
        on twoSided set val do (
            if ::mat4ds_disable_set != true do (
                delegate.twoSided = val
            )
        )
        
        on imageAlpha set val do (
            if ::mat4ds_disable_set != true do (
                RefreshAlpha()
                
                rltParams.btnAlphaMap.enabled = not (imageAlpha or colorKey or additiveMixing)
            )
        )

        on colorKey set val do (
            if ::mat4ds_disable_set != true do (
                RefreshAlpha()

                rltParams.btnGenPreview.enabled = val
                
                addEffect = colorKey or alphaMapEnable or additiveMixing
                
                rltParams.btnAlphaMap.enabled = not (imageAlpha or colorKey or additiveMixing)
            )
        )

        on additiveMixing set val do (
            if ::mat4ds_disable_set != true do (
                RefreshAlpha()
                
                addEffect = colorKey or alphaMapEnable or additiveMixing
                
                rltParams.btnAlphaMap.enabled = not (imageAlpha or colorKey or additiveMixing)
            )
        )
        
        on addEffect get val do (
            colorKey or alphaMapEnable or additiveMixing
        )
        
        on envMode set val do (
            if ::mat4ds_disable_set != true do (
                --for forwards compatibility
                local mode = val - 1
                envOverlay = bit.get mode 1
                envMultiply = bit.get mode 2
                envAdditive = bit.get mode 3
                -------------------
                
                rltParams.lblAmount.enabled = val == 1 or val == 2
                rltParams.spnEnvMapAmount.enabled = val == 1 or val == 2
            )
        )
        
        on envType set val do (
            if ::mat4ds_disable_set != true do (
                --for forwards compatibility
                local type = val - 1
                YProj = bit.get type 1
                YDetail = bit.get type 2
                ZDetail = bit.get type 3
            )
        )
        
        on animatedDiffuse set val do (
            if ::mat4ds_disable_set != true do (
                rltParams.lblFrameCount.enabled = animatedDiffuse
                rltParams.spnFrameCount.enabled = animatedDiffuse
                rltParams.lblFrameDelay.enabled = animatedDiffuse
                rltParams.spnFrameDelay.enabled = animatedDiffuse
                
                rltParams.chkAnimatedAlpha.enabled = animatedDiffuse
            )
        )
        
        on tileU set val do (
            if ::mat4ds_disable_set != true do (
                local maps = #('Diffuse Map', 'Alpha Map', preview1)
                for map in maps do (
                    SetMapTile map tileU tileV
                )
            )
        )
        
        on tileV set val do (
            if ::mat4ds_disable_set != true do (
                local maps = #('Diffuse Map', 'Alpha Map', preview1)
                for map in maps do (
                    SetMapTile map tileU tileV
                )
            )
        )
        
    )


    fn KeyBitmap bt = (
        local width = bt.width
        local height = bt.height

        local newbt = bitmap width height

        local keycolor = black
        local palette = bt.palette
        if palette != undefined then (
            keycolor = palette[1]
        )

        for y = 1 to height do (
            local pixels = getPixels bt [0, y-1] width

            for x = 1 to pixels.count do (
                if pixels[x] == keyColor then pixels[x] = black
                else pixels[x] = white
            )
            setPixels newbt [0, y-1] pixels
        )
        newbt
    )
    
    fn SavePng bt = (
        local png = pngio.ipngio
        local pngType = png.getType()
        local pngInterlaced = png.getInterlaced()
        local pngAlpha = png.getAlpha()
        png.setType #gray8
        png.setInterlaced false
        png.setAlpha false
        save bt
        png.setType pngType
        png.setInterlaced pngInterlaced
        png.setAlpha pngAlpha
    )

    fn GeneratePreview map = (
        local result
        if (map != undefined) and (ClassOf map == Bitmaptexture) then (
            local vbitmap
            try (
                vbitmap = map.bitmap
            ) catch ()
            
            if vbitmap != undefined then (
                local tempDir = (GetDir #temp) + "\\max4ds\\"
                local tempExists = makeDir tempDir
                if tempExists then (
                    local bt = KeyBitmap vbitmap
                    local filename = tempDir + (getFilenameFile map.filename) + "_key.png"
                    bt.filename = filename
                    SavePng bt
                    close bt
                    free bt

                    if preview1 == undefined then (
                        preview1 = bitmaptex()
                    )
                    preview1.filename = filename
                )
            )
        )
    )

    fn RefreshAlpha = (
        if diffuseMapEnable and 'Diffuse Map' != undefined then (
            if imageAlpha then (
                if imageAlphaMap == undefined then (
                    imageAlphaMap = Bitmaptexture()
                    imageAlphaMap.monoOutput = 1
                    imageAlphaMap.RGBOutput = 1
                )
                
                imageAlphaMap.filename = 'Diffuse Map'.filename
                
                delegate.opacityMapEnable = true
                delegate.opacityMap = imageAlphaMap
            )
            else if colorKey == true then (
                if preview1 == undefined then (
                    GeneratePreview 'Diffuse Map'
                )

                delegate.opacityMapEnable = true
                delegate.opacityMap = preview1
            )
            else if additiveMixing == true then (
                delegate.opacityMapEnable = true
                delegate.opacityMap = 'Diffuse Map'
            )            
            else if alphaMapEnable == true then (
                delegate.opacityMapEnable = true
                delegate.opacityMap = 'Alpha Map'
            )
            else (
                delegate.opacityMapEnable = false
            )
        )
        else (
            delegate.opacityMapEnable = false
        )
    )



    rollout rltParams "4ds Material Parameters" width:348 height:603
    (
    	label 'lblAmbient' "Ambient" pos:[16,8] width:48 height:16 align:#left
    	colorPicker 'cpAmbient' "" pos:[64,8] width:40 height:20 align:#left
    	label 'lblEmissive' "Emissive" pos:[128,8] width:48 height:16 align:#left
    	colorPicker 'cpEmissive' "" pos:[184,8] width:40 height:20 align:#left
    	label 'lblDiffuse' "Diffuse" pos:[16,32] width:48 height:16 align:#left
    	colorPicker 'cpDiffuse' "" pos:[64,32] width:40 height:20 align:#left
    	label 'lblSpecular' "Specular" pos:[128,32] width:56 height:16 toolTip:"Not supported in Mafia" align:#left
    	colorPicker 'cpSpecular' "" pos:[184,30] width:40 height:20 toolTip:"Not supported in Mafia" align:#left
    	label 'lblGlossiness' "Glossiness" pos:[128,56] width:48 height:16 toolTip:"Not supported in Mafia" align:#left
    	label 'lblOpacity' "Opacity" pos:[16,56] width:48 height:16 align:#left
    	spinner 'spnOpacity' "" pos:[64,56] width:40 height:16 type:#integer align:#left
    	spinner 'spnGlossiness' "" pos:[184,56] width:40 height:16 type:#integer toolTip:"Not supported in Mafia" align:#left
    	checkbox 'chkDiffuseMapEnable' "Enable" pos:[16,112] width:56 height:16 align:#left
    	mapButton 'btnDiffuseMap' "Diffuse map" pos:[128,109] width:206 height:22 align:#left
    	checkbox 'chkMipMapping' "Mip mapping" pos:[128,168] width:83 height:16 align:#left
    	checkbox 'chkColored' "Colored" pos:[16,168] width:61 height:16 toolTip:"Tint the diffuse and env map with 'Ambient' and 'Diffuse' color" align:#left
    	checkbox 'chkTwoSided' "2-Sided" pos:[240,168] width:60 height:16 align:#left
    	checkbox 'chkTileU' "Tile U" pos:[16,144] width:48 height:16 align:#left
    	checkbox 'chkTileV' "Tile V" pos:[128,144] width:48 height:16 align:#left
    	checkbox 'chkUnknown5' "Unknown 5" pos:[16,192] width:77 height:16 align:#left
    	checkbox 'chkUnknown6' "Unknown 6" pos:[128,192] width:77 height:16 align:#left
    	checkbox 'chkUnknown7' "Unknown 7" pos:[240,192] width:77 height:16 align:#left
    	checkbox 'chkEnvMapEnable' "Enable" pos:[16,256] width:56 height:16 align:#left
    	label 'lblAmount' "Amount" pos:[16,336] width:40 height:16 align:#left
    	spinner 'spnEnvMapAmount' "" pos:[56,336] width:40 height:16 type:#integer align:#left
    	mapButton 'btnEnvMap' "Environment map" pos:[128,253] width:206 height:22 align:#left
        label 'lblTile' "Tile" pos:[136,336] width:16 height:16 tooltip:"Has effect only in Mafia" align:#left
    	spinner 'spnEnvTile' "" pos:[157,336] width:40 height:16 range:[0,255,0] type:#integer tooltip:"Has effect only in Mafia" align:#left
    	dropdownList 'ddlEnvMode' "Blending Mode" pos:[16,288] width:184 height:40 items:#("[broken] ", "Normal [adjustable]", "Normal [full strength, no tint]", "Multiply", "Overlay", "Add", "Mode 7", "Mode 8") align:#left
    	dropdownList 'ddlEnvType' "Type" pos:[208,288] width:128 height:40 items:#("X projection", "Y projection", "Mirror X", "Mirror Y", "Mirror XY", "Type 6", "Type 7", "Type 8") align:#left
    	checkbox 'chkAlphaMapEnable' "Enable" pos:[16,392] width:56 height:16 align:#left
    	mapButton 'btnAlphaMap' "Alpha map" pos:[128,388] width:206 height:22 align:#left
    	checkbox 'chkImageAlpha' "Image alpha" pos:[16,416] width:83 height:16 toolTip:"Use the alpha channel from diffuse map for transparency" align:#left
    	checkbox 'chkColorKey' "Color key" pos:[16,440] width:69 height:16 toolTip:"Use the first color in the palette (for 8bit BMPs)\nor black (for 24bit BMPs or TGAs)\nfor transparency" align:#left
    	button 'btnGenPreview' "Update preview" pos:[128,440] width:92 height:22 align:#left
    	checkbox 'chkAdditiveMixing' "Additive mixing" pos:[16,464] width:96 height:16 align:#left
    	GroupBox 'grpDiffuse' "Diffuse Map" pos:[8,88] width:336 height:135 align:#left
    	GroupBox 'grpEnv' "Environment Map" pos:[8,232] width:336 height:128 align:#left
    	GroupBox 'grpAlpha' "Alpha Map" pos:[8,368] width:336 height:120 align:#left
    	GroupBox 'grpAnim' "Animation" pos:[8,496] width:336 height:96 align:#left
    	checkbox 'chkAnimatedDiffuse' "Animated diffuse" pos:[16,520] width:104 height:16 align:#left
    	checkbox 'chkAnimatedAlpha' "Animated alpha" pos:[128,520] width:96 height:16 aligh:#left align:#left
    	label 'lblFrameCount' "Frames" pos:[18,544] width:54 height:16 toolTip:"Total number of frames" align:#left
    	label 'lblFrameDelay' "Delay (ms)" pos:[18,568] width:54 height:16 toolTip:"Delay between frames in milliseconds" align:#left
    	spinner 'spnFrameCount' "" pos:[72,544] width:48 height:16 range:[0,100,0] type:#integer toolTip:"Total number of frames" align:#left
    	spinner 'spnFrameDelay' "" pos:[72,568] width:48 height:16 range:[0,3.6e+06,0] type:#integer toolTip:"Delay between frames in milliseconds" align:#left

    	on rltParams open do
    	(
            ::mat4ds_disable_set = undefined
            --format "on open\n"
    	    btnGenPreview.enabled = chkColorKey.checked
    	    
    	    lblFrameCount.enabled = animatedDiffuse
    	    spnFrameCount.enabled = animatedDiffuse
    	    lblFrameDelay.enabled = animatedDiffuse
            spnFrameDelay.enabled = animatedDiffuse
            
            chkAnimatedAlpha.enabled = animatedDiffuse
    	    
    	    btnAlphaMap.enabled = not (imageAlpha or colorKey or additiveMixing)
    	    
    	    lblAmount.enabled = envMode == 1 or envMode == 2
    	    spnEnvMapAmount.enabled = envMode == 1 or envMode == 2
        )
        
    	on btnGenPreview pressed do
    	(
    	    if 'Diffuse Map' != undefined then (
    	        GeneratePreview 'Diffuse Map'
    	        delegate.opacityMap = preview1
    	    )
    	)
    )

    on update do (
        --format "material update, version: %\n" version        
        --showProperties this

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
        
        if version == 1 or version == 2 then (
            local mode = 0
            mode = bit.set mode 1 envOverlay
            mode = bit.set mode 2 envMultiply
            mode = bit.set mode 3 envAdditive
            
            envMode = mode + 1
            
            local type = 0
            type = bit.set type 1 YProj
            type = bit.set type 2 YDetail
            type = bit.set type 3 ZDetail
            
            envType = type + 1
        )        
    )
    
    on create do (
        delegate.adLock = false
        delegate.specularlevel = 70.0
        
        --format "on create \n"
    )
    
    on postCreate do (        
        ::mat4ds_disable_set = undefined
        --format "post create \n"
    )
    
    on load do (
        ::mat4ds_disable_set = true
        --format "on load \n"
    )
    
    on postLoad do (
        ::mat4ds_disable_set = undefined
        --format "post load \n"
    )
)