// Automatically generated by makemoduledefs.py.

extern const struct _mp_obj_module_t mp_module_array;
#undef MODULE_DEF_ARRAY
#define MODULE_DEF_ARRAY { MP_ROM_QSTR(MP_QSTR_array), MP_ROM_PTR(&mp_module_array) },

extern const struct _mp_obj_module_t mp_module_binascii;
#undef MODULE_DEF_BINASCII
#define MODULE_DEF_BINASCII { MP_ROM_QSTR(MP_QSTR_binascii), MP_ROM_PTR(&mp_module_binascii) },

extern const struct _mp_obj_module_t mp_module_collections;
#undef MODULE_DEF_COLLECTIONS
#define MODULE_DEF_COLLECTIONS { MP_ROM_QSTR(MP_QSTR_collections), MP_ROM_PTR(&mp_module_collections) },

extern const struct _mp_obj_module_t mp_module_errno;
#undef MODULE_DEF_ERRNO
#define MODULE_DEF_ERRNO { MP_ROM_QSTR(MP_QSTR_errno), MP_ROM_PTR(&mp_module_errno) },

extern const struct _mp_obj_module_t mp_module_hashlib;
#undef MODULE_DEF_HASHLIB
#define MODULE_DEF_HASHLIB { MP_ROM_QSTR(MP_QSTR_hashlib), MP_ROM_PTR(&mp_module_hashlib) },

extern const struct _mp_obj_module_t mp_module_heapq;
#undef MODULE_DEF_HEAPQ
#define MODULE_DEF_HEAPQ { MP_ROM_QSTR(MP_QSTR_heapq), MP_ROM_PTR(&mp_module_heapq) },

extern const struct _mp_obj_module_t mp_module_io;
#undef MODULE_DEF_IO
#define MODULE_DEF_IO { MP_ROM_QSTR(MP_QSTR_io), MP_ROM_PTR(&mp_module_io) },

extern const struct _mp_obj_module_t mp_module_json;
#undef MODULE_DEF_JSON
#define MODULE_DEF_JSON { MP_ROM_QSTR(MP_QSTR_json), MP_ROM_PTR(&mp_module_json) },

extern const struct _mp_obj_module_t mp_module_os;
#undef MODULE_DEF_OS
#define MODULE_DEF_OS { MP_ROM_QSTR(MP_QSTR_os), MP_ROM_PTR(&mp_module_os) },

extern const struct _mp_obj_module_t mp_module_random;
#undef MODULE_DEF_RANDOM
#define MODULE_DEF_RANDOM { MP_ROM_QSTR(MP_QSTR_random), MP_ROM_PTR(&mp_module_random) },

extern const struct _mp_obj_module_t mp_module_re;
#undef MODULE_DEF_RE
#define MODULE_DEF_RE { MP_ROM_QSTR(MP_QSTR_re), MP_ROM_PTR(&mp_module_re) },

extern const struct _mp_obj_module_t mp_module_select;
#undef MODULE_DEF_SELECT
#define MODULE_DEF_SELECT { MP_ROM_QSTR(MP_QSTR_select), MP_ROM_PTR(&mp_module_select) },

extern const struct _mp_obj_module_t mp_module_struct;
#undef MODULE_DEF_STRUCT
#define MODULE_DEF_STRUCT { MP_ROM_QSTR(MP_QSTR_struct), MP_ROM_PTR(&mp_module_struct) },

extern const struct _mp_obj_module_t mp_module_time;
#undef MODULE_DEF_TIME
#define MODULE_DEF_TIME { MP_ROM_QSTR(MP_QSTR_time), MP_ROM_PTR(&mp_module_time) },

extern const struct _mp_obj_module_t mp_module_zlib;
#undef MODULE_DEF_ZLIB
#define MODULE_DEF_ZLIB { MP_ROM_QSTR(MP_QSTR_zlib), MP_ROM_PTR(&mp_module_zlib) },

extern const struct _mp_obj_module_t mp_module___main__;
#undef MODULE_DEF___MAIN__
#define MODULE_DEF___MAIN__ { MP_ROM_QSTR(MP_QSTR___main__), MP_ROM_PTR(&mp_module___main__) },

extern const struct _mp_obj_module_t mp_module_asyncio;
#undef MODULE_DEF__ASYNCIO
#define MODULE_DEF__ASYNCIO { MP_ROM_QSTR(MP_QSTR__asyncio), MP_ROM_PTR(&mp_module_asyncio) },

extern const struct _mp_obj_module_t mp_module_builtins;
#undef MODULE_DEF_BUILTINS
#define MODULE_DEF_BUILTINS { MP_ROM_QSTR(MP_QSTR_builtins), MP_ROM_PTR(&mp_module_builtins) },

extern const struct _mp_obj_module_t mp_module_cmath;
#undef MODULE_DEF_CMATH
#define MODULE_DEF_CMATH { MP_ROM_QSTR(MP_QSTR_cmath), MP_ROM_PTR(&mp_module_cmath) },

extern const struct _mp_obj_module_t mp_module_framebuf;
#undef MODULE_DEF_FRAMEBUF
#define MODULE_DEF_FRAMEBUF { MP_ROM_QSTR(MP_QSTR_framebuf), MP_ROM_PTR(&mp_module_framebuf) },

extern const struct _mp_obj_module_t mp_module_gc;
#undef MODULE_DEF_GC
#define MODULE_DEF_GC { MP_ROM_QSTR(MP_QSTR_gc), MP_ROM_PTR(&mp_module_gc) },

extern const struct _mp_obj_module_t mp_module_math;
#undef MODULE_DEF_MATH
#define MODULE_DEF_MATH { MP_ROM_QSTR(MP_QSTR_math), MP_ROM_PTR(&mp_module_math) },

extern const struct _mp_obj_module_t mp_module_micropython;
#undef MODULE_DEF_MICROPYTHON
#define MODULE_DEF_MICROPYTHON { MP_ROM_QSTR(MP_QSTR_micropython), MP_ROM_PTR(&mp_module_micropython) },

extern const struct _mp_obj_module_t mp_module_sys;
#undef MODULE_DEF_SYS
#define MODULE_DEF_SYS { MP_ROM_QSTR(MP_QSTR_sys), MP_ROM_PTR(&mp_module_sys) },

extern const struct _mp_obj_module_t mp_module_uctypes;
#undef MODULE_DEF_UCTYPES
#define MODULE_DEF_UCTYPES { MP_ROM_QSTR(MP_QSTR_uctypes), MP_ROM_PTR(&mp_module_uctypes) },

extern const struct _mp_obj_module_t ulab_user_cmodule;
#undef MODULE_DEF_ULAB
#define MODULE_DEF_ULAB { MP_ROM_QSTR(MP_QSTR_ulab), MP_ROM_PTR(&ulab_user_cmodule) },


#define MICROPY_REGISTERED_MODULES \
    MODULE_DEF_BUILTINS \
    MODULE_DEF_CMATH \
    MODULE_DEF_FRAMEBUF \
    MODULE_DEF_GC \
    MODULE_DEF_MATH \
    MODULE_DEF_MICROPYTHON \
    MODULE_DEF_SYS \
    MODULE_DEF_UCTYPES \
    MODULE_DEF_ULAB \
    MODULE_DEF__ASYNCIO \
    MODULE_DEF___MAIN__ \
// MICROPY_REGISTERED_MODULES

#define MICROPY_REGISTERED_EXTENSIBLE_MODULES \
    MODULE_DEF_ARRAY \
    MODULE_DEF_BINASCII \
    MODULE_DEF_COLLECTIONS \
    MODULE_DEF_ERRNO \
    MODULE_DEF_HASHLIB \
    MODULE_DEF_HEAPQ \
    MODULE_DEF_IO \
    MODULE_DEF_JSON \
    MODULE_DEF_OS \
    MODULE_DEF_RANDOM \
    MODULE_DEF_RE \
    MODULE_DEF_SELECT \
    MODULE_DEF_STRUCT \
    MODULE_DEF_TIME \
    MODULE_DEF_ZLIB \
// MICROPY_REGISTERED_EXTENSIBLE_MODULES

extern void mp_module_sys_attr(mp_obj_t self_in, qstr attr, mp_obj_t *dest);
#define MICROPY_MODULE_DELEGATIONS \
    { MP_ROM_PTR(&mp_module_sys), mp_module_sys_attr }, \
// MICROPY_MODULE_DELEGATIONS
