#include <maxtypes.h>
#include "util.h"

HINSTANCE hInstance;

wchar_t *GetString(int id)
{
    static wchar_t buf[256];

    if (hInstance)
    {
        return LoadString(hInstance, id, buf, _countof(buf)) ? buf : NULL;
    }

    return NULL;
}
