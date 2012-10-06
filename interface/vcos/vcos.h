

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

#ifndef VCOS_H
#define VCOS_H

#include "interface/vcos/vcos_assert.h"
#include "vcos_types.h"
#include "vcos_platform.h"

#ifndef VCOS_INIT_H
#include "interface/vcos/vcos_init.h"
#endif

#ifndef VCOS_SEMAPHORE_H
#include "interface/vcos/vcos_semaphore.h"
#endif

#ifndef VCOS_THREAD_H
#include "interface/vcos/vcos_thread.h"
#endif

#ifndef VCOS_MUTEX_H
#include "interface/vcos/vcos_mutex.h"
#endif

#ifndef VCOS_MEM_H
#include "interface/vcos/vcos_mem.h"
#endif

#ifndef VCOS_LOGGING_H
#include "interface/vcos/vcos_logging.h"
#endif

#ifndef VCOS_STRING_H
#include "interface/vcos/vcos_string.h"
#endif

#ifndef VCOS_EVENT_H
#include "interface/vcos/vcos_event.h"
#endif

#ifndef VCOS_THREAD_ATTR_H
#include "interface/vcos/vcos_thread_attr.h"
#endif

#ifndef VCOS_TLS_H
#include "interface/vcos/vcos_tls.h"
#endif

#ifndef VCOS_REENTRANT_MUTEX_H
#include "interface/vcos/vcos_reentrant_mutex.h"
#endif

#ifndef VCOS_NAMED_SEMAPHORE_H
#include "interface/vcos/vcos_named_semaphore.h"
#endif

#ifndef VCOS_QUICKSLOW_MUTEX_H
#include "interface/vcos/vcos_quickslow_mutex.h"
#endif

/* Headers with predicates */

#if VCOS_HAVE_EVENT_FLAGS
#include "interface/vcos/vcos_event_flags.h"
#endif

#if VCOS_HAVE_QUEUE
#include "interface/vcos/vcos_queue.h"
#endif

#if VCOS_HAVE_LEGACY_ISR
#include "interface/vcos/vcos_legacy_isr.h"
#endif

#if VCOS_HAVE_TIMER
#include "interface/vcos/vcos_timer.h"
#endif

#if VCOS_HAVE_MEMPOOL
#include "interface/vcos/vcos_mempool.h"
#endif

#if VCOS_HAVE_ISR
#include "interface/vcos/vcos_isr.h"
#endif

#if VCOS_HAVE_ATOMIC_FLAGS
#include "interface/vcos/vcos_atomic_flags.h"
#endif

#if VCOS_HAVE_ONCE
#include "interface/vcos/vcos_once.h"
#endif

#if VCOS_HAVE_BLOCK_POOL
#include "interface/vcos/vcos_blockpool.h"
#endif

#if VCOS_HAVE_FILE
#include "interface/vcos/vcos_file.h"
#endif

#if VCOS_HAVE_CFG
#include "interface/vcos/vcos_cfg.h"
#endif

#if VCOS_HAVE_CMD
#include "interface/vcos/vcos_cmd.h"
#endif

#endif /* VCOS_H */

