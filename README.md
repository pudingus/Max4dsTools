Work in progress. Based on the plugin by Mr F, but almost everything has been rewritten.



What is supported:
- Sectors
- Portals
- Meshes
- LODs
- Dummies
- Material flags
- Culling and rendering flags
- Vertex normals

What is not supported (yet?):
- Skinned meshes, morphs, bones, billboards, mirrors, targets, glows


Sectors have to be prefixed with "sector" (no dollar sign)  
Portals have to be prefixed with "$portal" and have a sector parent  
Lods have to be prefixed with "$lod" and have a mesh parent

You can apply optional modifiers to control culling flags, lod fade distance, portal range...

Current limitations: Materials you wish to export have to be under single Multimaterial with a name "$MAFIA_MATERIALS". This single Multimaterial has to be applied to every object.

If you move pivot for an object, you have to reset it before exporting.