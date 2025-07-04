#ifndef __DEVICE_DEVICE_CONFIG__
#define __DEVICE_DEVICE_CONFIG__

/**
 * Parameters and options for device backends
 */

/**
 * Floating point precision in device kernels
 * @note Set to the same C/C++ equivalent type as @a rp
 */
typedef double real;

extern void *glb_ctx;
extern void *glb_cmd_queue;
extern void *glb_device_id;

#endif // __DEVICE_DEVICE_CONFIG__
