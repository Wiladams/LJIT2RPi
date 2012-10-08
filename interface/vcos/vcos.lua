
package.path = package.path..";pthreads/?.lua;"
--[[
=============================================================================
VideoCore OS Abstraction Layer - public header file
=============================================================================*/
--]]


--[[
   \file vcos.h
  
   This is the top level header file. Clients include this. It pulls in the platform-specific
   header file (vcos_platform.h) together with header files defining the expected APIs, such
   as vcos_mutex.h, vcos_semaphore.h, etc. It is also possible to include these header files
   directly.

--]]


--require "vcos_assert"
require "vcos_types"
--[[
require "vcos_platform.h"
require "vcos_init.h"
require "vcos_semaphore.h"
require "vcos_thread.h"
require "vcos_mutex.h"
require "vcos_mem.h"
require "vcos_logging.h"
require "vcos_string.h"
require "vcos_event.h"
require "vcos_thread_attr.h"
require "vcos_tls.h"
require "vcos_reentrant_mutex.h"
require "vcos_named_semaphore.h"
require "vcos_quickslow_mutex.h"
--]]

--[[
-- Headers with predicates
require "../vcos/vcos_event_flags.h"
require "../vcos/vcos_queue.h"
require "../vcos/vcos_legacy_isr.h"
require "../vcos/vcos_timer.h"
require "../vcos/vcos_mempool.h"
require "../vcos/vcos_isr.h"
require "../vcos/vcos_atomic_flags.h"
require "../vcos/vcos_once.h"
require "../vcos/vcos_blockpool.h"
require "../vcos/vcos_file.h"
require "../vcos/vcos_cfg.h"
require "../vcos/vcos_cmd.h"
--]]



