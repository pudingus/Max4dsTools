#include "nspec.h"
#include "util.h"
#include <MeshNormalSpec.h>

//----------------------------------
//-------------GUP------------------
//----------------------------------

class Nspec : public GUP
{
public:
    Nspec() {}
    ~Nspec() {}

    DWORD Start() override {
        #pragma message(TODO("Do plugin initialization here"))
        #pragma message(TODO("Return if you want remain loaded or not"))
        return GUPRESULT_KEEP;
    }
    void Stop() override {
        #pragma message(TODO("Do plugin un-initialization here"))
    }

    DWORD_PTR Control(DWORD parameter) override { return 0; }
    void DeleteThis() override { delete this; }

    IOResult Save(ISave* isave) override { return IO_OK; }
    IOResult Load(ILoad* iload) override { return IO_OK; }
};

//------------------------------------------
//-------------class description------------
//------------------------------------------

#define NSPEC_CLASS_ID Class_ID(0x66e360e4, 0x1fa47789)

class NspecClassDesc : public ClassDesc2 
{
public:
    int           IsPublic() override                       { return TRUE; }
    void*         Create(BOOL /*loading = FALSE*/) override { return new Nspec(); }
    const TCHAR * ClassName() override                      { return GetString(IDS_CLASS_NAME); }
    const TCHAR * NonLocalizedClassName()                   { return GetString(IDS_CLASS_NAME); }
    SClass_ID     SuperClassID() override                   { return GUP_CLASS_ID; }
    Class_ID      ClassID() override                        { return NSPEC_CLASS_ID; }
    const TCHAR*  Category() override                       { return GetString(IDS_CATEGORY); }

    const TCHAR*  InternalName() override                   { return _T("nspec"); } // name of the variable that holds the class instance
    HINSTANCE     HInstance() override                      { return hInstance; } // Returns owning module handle
};

ClassDesc2* GetNspecDesc()
{
    static NspecClassDesc nspecDesc;
    return &nspecDesc; 
}

//----------------------------------
//-------------interface------------
//----------------------------------
#define NSPEC_INTERFACE_ID Interface_ID(0x610667a1, 0x414e70f8)


class IFP_Basic : public FPStaticInterface
{
public:
    virtual int GetNumNormals(Mesh& mesh) = 0;
    virtual int GetNumFaces(Mesh& mesh) = 0;
    virtual Point3& GetNormal(Mesh& mesh, int normID) = 0;
    virtual int GetNormalId(Mesh& mesh, int face, int corner) = 0;


    virtual bool SetNumNormals(Mesh& mesh, int numNormals) = 0;
    virtual bool SetNumFaces(Mesh& mesh, int numFaces) = 0;

    virtual void SetNormal(Mesh& mesh, int normID, Point3& normal) = 0;
    virtual void SetNormalId(Mesh& mesh, int face, int corner, int normID) = 0;

    virtual void SetNormalExplicit(Mesh& mesh, int normID, bool value) = 0;

    virtual bool GetNormalExplicit(Mesh& mesh, int normID) = 0;



    enum {
        em_GetNumNormals,
        em_GetNumFaces,
        em_GetNormal,
        em_GetNormalId,

        em_SetNumNormals,
        em_SetNumFaces,

        em_SetNormal,
        em_SetNormalId,

        em_SetNormalExplicit,
        em_GetNormalExplicit
    };
};


class FP_Basic : public IFP_Basic
{
public:
    int GetNumNormals(Mesh& mesh) {
        MeshNormalSpec* nspec = mesh.GetSpecifiedNormals();	

        return nspec->GetNumNormals();
    }

    int GetNumFaces(Mesh& mesh) {
        MeshNormalSpec* nspec = mesh.GetSpecifiedNormals();

        return nspec->GetNumFaces();
    }

    Point3& GetNormal(Mesh& mesh, int normID) {
        MeshNormalSpec* nspec = mesh.GetSpecifiedNormals();	
        int numNormals = nspec->GetNumNormals();
        if (normID > numNormals || normID < 1) throw MAXException(L"normID out of valid range");


        return nspec->Normal(normID - 1);
    }



    int GetNormalId(Mesh& mesh, int face, int corner) {
        MeshNormalSpec* nspec = mesh.GetSpecifiedNormals();
        int numFaces = nspec->GetNumFaces();
        if (face > numFaces || face < 1) throw MAXException(L"face out of valid range");
        if (corner > 3 || corner < 1) throw MAXException(L"corner out of valid range");

        return nspec->GetNormalIndex(face - 1, corner - 1) + 1;
    }

    bool SetNumNormals(Mesh& mesh, int numNormals) {
        if (numNormals < 0) throw MAXException(L"numNormals out of valid range");

        mesh.SpecifyNormals();    //needed in 'Set...' functions or Max crashes, when setting it on new TriMeshes
        MeshNormalSpec* nspec = mesh.GetSpecifiedNormals();

        return nspec->SetNumNormals(numNormals);
    }

    bool SetNumFaces(Mesh& mesh, int numFaces) {
        if (numFaces < 0) throw MAXException(L"numFaces out of valid range");

        mesh.SpecifyNormals();
        MeshNormalSpec* nspec = mesh.GetSpecifiedNormals();

        return nspec->SetNumFaces(numFaces);
    }

    void SetNormal(Mesh& mesh, int normID, Point3& normal) {
        mesh.SpecifyNormals();
        MeshNormalSpec* nspec = mesh.GetSpecifiedNormals();
        int numNormals = nspec->GetNumNormals();
        if (normID > numNormals || normID < 1) throw MAXException(L"normID out of valid range");

        nspec->Normal(normID - 1) = normal;
    }

    void SetNormalId(Mesh& mesh, int face, int corner, int normID) {
        mesh.SpecifyNormals();
        MeshNormalSpec* nspec = mesh.GetSpecifiedNormals();
        int numFaces = nspec->GetNumFaces();
        if (face > numFaces || face < 1) throw MAXException(L"face out of valid range");
        if (corner > 3 || corner < 1) throw MAXException(L"corner out of valid range");
        int numNormals = nspec->GetNumNormals();
        if (normID > numNormals || normID < 1) throw MAXException(L"normID out of valid range");

        nspec->SetNormalIndex(face - 1, corner - 1, normID - 1);
    }

    void SetNormalExplicit(Mesh& mesh, int normID, bool value) {
        mesh.SpecifyNormals();
        MeshNormalSpec* nspec = mesh.GetSpecifiedNormals();    
        int numNormals = nspec->GetNumNormals();
        if (normID > numNormals || normID < 1) throw MAXException(L"normID out of valid range");

        nspec->SetNormalExplicit(normID - 1, value);
    }

    bool GetNormalExplicit(Mesh& mesh, int normID) {
        MeshNormalSpec* nspec = mesh.GetSpecifiedNormals();    
        int numNormals = nspec->GetNumNormals();
        if (normID > numNormals || normID < 1) throw MAXException(L"normID out of valid range");

        return nspec->GetNormalExplicit(normID - 1);
    }

    #pragma warning(push)
    #pragma warning(disable:4238)
    DECLARE_DESCRIPTOR_INIT(FP_Basic)
    BEGIN_FUNCTION_MAP

        //	 function id, return type, fn pointer, param1 type
        FN_1(IFP_Basic::em_GetNumNormals, TYPE_INT, GetNumNormals, TYPE_MESH_BR)
        FN_1(IFP_Basic::em_GetNumFaces, TYPE_INT, GetNumFaces, TYPE_MESH_BR)
        FN_2(IFP_Basic::em_GetNormal, TYPE_POINT3_BR, GetNormal, TYPE_MESH_BR, TYPE_INT)
        FN_3(IFP_Basic::em_GetNormalId, TYPE_INT, GetNormalId, TYPE_MESH_BR, TYPE_INT, TYPE_INT)

        FN_2(IFP_Basic::em_SetNumNormals, TYPE_BOOL, SetNumNormals, TYPE_MESH_BR, TYPE_INT)
        FN_2(IFP_Basic::em_SetNumFaces, TYPE_BOOL, SetNumFaces, TYPE_MESH_BR, TYPE_INT)

        VFN_3(IFP_Basic::em_SetNormal, SetNormal, TYPE_MESH_BR, TYPE_INT, TYPE_POINT3_BR)
        VFN_4(IFP_Basic::em_SetNormalId, SetNormalId, TYPE_MESH_BR, TYPE_INT, TYPE_INT, TYPE_INT)

        VFN_3(IFP_Basic::em_SetNormalExplicit, SetNormalExplicit, TYPE_MESH_BR, TYPE_INT, TYPE_BOOL)
        FN_2(IFP_Basic::em_GetNormalExplicit, TYPE_BOOL, GetNormalExplicit, TYPE_MESH_BR, TYPE_INT)

    END_FUNCTION_MAP
    #pragma warning (pop)
};

FP_Basic fp_basic_desc(
    NSPEC_INTERFACE_ID, //Interface_ID
    L"inspec",		    //Internal Fixed Name
    IDS_CLASS_NAME,		//localized string resource ID
    GetNspecDesc(),		//owning class descriptor
    FP_CORE,			//Flags

        IFP_Basic::em_GetNumNormals, L"GetNumNormals", 0, TYPE_INT, 0, 1,
            L"mesh", 0, TYPE_MESH_BR,

        IFP_Basic::em_GetNumFaces, L"GetNumFaces", 0, TYPE_INT, 0, 1,
            L"mesh", 0, TYPE_MESH_BR,

        IFP_Basic::em_GetNormal, L"GetNormal", 0, TYPE_POINT3_BR, 0, 2,
            L"mesh", 0, TYPE_MESH_BR,
            L"normID", 0, TYPE_INT,

        IFP_Basic::em_GetNormalId, L"GetNormalId", 0, TYPE_INT, 0, 3,
            L"mesh", 0, TYPE_MESH_BR,
            L"face", 0, TYPE_INT,
            L"corner", 0, TYPE_INT,



        IFP_Basic::em_SetNumNormals, L"SetNumNormals", 0, TYPE_BOOL, 0, 2,
            L"mesh", 0, TYPE_MESH_BR,
            L"numNormals", 0, TYPE_INT,

        IFP_Basic::em_SetNumFaces, L"SetNumFaces", 0, TYPE_BOOL, 0, 2,
            L"mesh", 0, TYPE_MESH_BR,
            L"numFaces", 0, TYPE_INT,

        IFP_Basic::em_SetNormal, L"SetNormal", 0, TYPE_VOID, 0, 3,
            L"mesh", 0, TYPE_MESH_BR,
            L"normID", 0, TYPE_INT,
            L"normal", 0, TYPE_POINT3_BR,

        IFP_Basic::em_SetNormalId, L"SetNormalId", 0, TYPE_VOID, 0, 4,
            L"mesh", 0, TYPE_MESH_BR,
            L"face", 0, TYPE_INT,
            L"corner", 0, TYPE_INT,
            L"normId", 0, TYPE_INT,

        IFP_Basic::em_SetNormalExplicit, L"SetNormalExplicit", 0, TYPE_VOID, 0, 3,
            L"mesh", 0, TYPE_MESH_BR,
            L"normID", 0, TYPE_INT,
            L"value", 0, TYPE_BOOL,

        IFP_Basic::em_GetNormalExplicit, L"GetNormalExplicit", 0, TYPE_BOOL, 0, 2,
            L"mesh", 0, TYPE_MESH_BR,
            L"normID", 0, TYPE_INT,

    p_end
);


// Custom initialization Method called when FP_Basic is constructed
void FP_Basic::init() {
    // Do something here
}
