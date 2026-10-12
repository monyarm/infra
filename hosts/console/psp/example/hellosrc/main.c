#include <pspkernel.h>
#include <pspmoduleinfo.h>

PSP_MODULE_INFO("hello", 0, 1, 0);

int main(void)
{
    while (1) {
        sceKernelDelayThread(1000000);
    }
    return 0;
}