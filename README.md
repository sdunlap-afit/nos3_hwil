# nos3_hwil


## Setup

```bash
git submodule update --init --recursive
```





## Config

Docker in Windows will not work with setschedparam so FSW will fail. To stop it from enforcing this feature, set `OSAL_CONFIG_DEBUG_PERMISSIVE_MODE = TRUE` in `nos3/fsw/osal/default_config.cmake`.

```cmake
set(OSAL_CONFIG_DEBUG_PERMISSIVE_MODE           TRUE
    CACHE BOOL "Disable enforcement of privileged operations"
)
```
