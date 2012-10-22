
local ffi = require "ffi"
local bit = require "bit"
local bnot = bit.bnot
local band = bit.band
local bor = bit.bor
local lshift = bit.lshift
local rshift = bit.rshift

-- Contains the protypes for the vchi functions.

require "vcos"
require "vchi_cfg"
require "vchi_common"
require "connection"
require "vchi_mh"



VCHI_BULK_ROUND_UP = function(x)  
	return band((x+VCHI_BULK_ALIGN-1), bnot(VCHI_BULK_ALIGN-1))
end

VCHI_BULK_ROUND_DOWN = function(x)
	return band(x, bnot(VCHI_BULK_ALIGN-1))
end

VCHI_BULK_ALIGN_NBYTES = function(x) 
	if VCHI_BULK_ALIGNED(x) > 0 then
		return 0 
	end 
	
	return (VCHI_BULK_ALIGN - band(x, VCHI_BULK_ALIGN-1))
end

if USE_VCHIQ_ARM then
	VCHI_BULK_ALIGNED = function(x) return 1 end
else
	VCHI_BULK_ALIGNED = function(x) return      (band(x, VCHI_BULK_ALIGN-1) == 0) end
end

ffi.cdef[[
typedef struct 
{
   uint32_t version;
   uint32_t version_min;
} VCHI_VERSION_T;
]]

VCHI_VERSION = function(v_) return ffi.new("VCHI_VERSION_T", v_, v_ ); end
VCHI_VERSION_EX = function(v_,m_) return ffi.new("VCHI_VERSION_T", v_, m_); end

ffi.cdef[[
typedef enum
{
   VCHI_VEC_POINTER,
   VCHI_VEC_HANDLE,
   VCHI_VEC_LIST
} VCHI_MSG_VECTOR_TYPE_T;

typedef struct vchi_msg_vector_ex {

   VCHI_MSG_VECTOR_TYPE_T type;
   union
   {
      // a memory handle
      struct
      {
         VCHI_MEM_HANDLE_T handle;
         uint32_t offset;
         int32_t vec_len;
      } handle;

      // an ordinary data pointer
      struct
      {
         const void *vec_base;
         int32_t vec_len;
      } ptr;

      // a nested vector list
      struct
      {
         struct vchi_msg_vector_ex *vec;
         uint32_t vec_len;
      } list;
   } u;
} VCHI_MSG_VECTOR_EX_T;
]]

-- BUGBUG
--[[
// Construct an entry in a msg vector for a pointer (p) of length (l)
#define VCHI_VEC_POINTER(p,l)  VCHI_VEC_POINTER, { { (VCHI_MEM_HANDLE_T)(p), (l) } }

// Construct an entry in a msg vector for a message handle (h), starting at offset (o) of length (l)
#define VCHI_VEC_HANDLE(h,o,l) VCHI_VEC_HANDLE,  { { (h), (o), (l) } }
--]]

-- Macros to manipulate fourcc_t values
MAKE_FOURCC = function(x) 
	if type(x) == "string" then
		return (bor( lshift(string.byte(x,1), 24), lshift(string.byte(x,2), 16), lshift(string.byte(x,3), 8), string.byte(x,4) ))
	end

	return (bor( lshift(x[0], 24), lshift(x[1], 16), lshift(x[2], 8), x[3] ))
end

FOURCC_TO_CHAR = function(x) 
	return ffi.new("char[4]", 
		band(rshift(x, 24), 0xFF),
		band(rshift(x, 16), 0xFF),
		band(rshift(x, 8), 0xFF), 
		band(x, 0xFF));
end

ffi.cdef[[
// Opaque service information
struct opaque_vchi_service_t;

// Descriptor for a held message. Allocated by client, initialised by vchi_msg_hold,
// vchi_msg_iter_hold or vchi_msg_iter_hold_next. Fields are for internal VCHI use only.
typedef struct
{
   struct opaque_vchi_service_t *service;
   void *message;
} VCHI_HELD_MSG_T;



// structure used to provide the information needed to open a server or a client
typedef struct {
   VCHI_VERSION_T version;
   vcos_fourcc_t service_id;
   VCHI_CONNECTION_T *connection;
   uint32_t rx_fifo_size;
   uint32_t tx_fifo_size;
   VCHI_CALLBACK_T callback;
   void *callback_param;
   vcos_bool_t want_unaligned_bulk_rx;    // client intends to receive bulk transfers of odd lengths or into unaligned buffers
   vcos_bool_t want_unaligned_bulk_tx;    // client intends to transmit bulk transfers of odd lengths or out of unaligned buffers
   vcos_bool_t want_crc;                  // client wants to check CRCs on (bulk) transfers. Only needs to be set at 1 end - will do both directions.
} SERVICE_CREATION_T;

// Opaque handle for a VCHI instance
typedef struct opaque_vchi_instance_handle_t *VCHI_INSTANCE_T;

// Opaque handle for a server or client
typedef struct opaque_vchi_service_handle_t *VCHI_SERVICE_HANDLE_T;

// Service registration & startup
typedef void (*VCHI_SERVICE_INIT)(VCHI_INSTANCE_T initialise_instance, VCHI_CONNECTION_T **connections, uint32_t num_connections);

typedef struct service_info_tag {
   const char * const vll_filename; /* VLL to load to start this service. This is an empty string if VLL is "static" */
   VCHI_SERVICE_INIT init;          /* Service initialisation function */
   void *vll_handle;                /* VLL handle; NULL when unloaded or a "static VLL" in build */
} SERVICE_INFO_T;
]]

--[[
******************************************************************************
 Global funcs - implementation is specific to which side you are on (local / remote)
*****************************************************************************
--]]

ffi.cdef[[
VCHI_CONNECTION_T * vchi_create_connection( const VCHI_CONNECTION_API_T * function_table,
                                                   const VCHI_MESSAGE_DRIVER_T * low_level);


// Routine used to initialise the vchi on both local + remote connections
int32_t vchi_initialise( VCHI_INSTANCE_T *instance_handle );

int32_t vchi_exit( void );

int32_t vchi_connect( VCHI_CONNECTION_T **connections,
                             const uint32_t num_connections,
                             VCHI_INSTANCE_T instance_handle );

//When this is called, ensure that all services have no data pending.
//Bulk transfers can remain 'queued'
int32_t vchi_disconnect( VCHI_INSTANCE_T instance_handle );

// Global control over bulk CRC checking
int32_t vchi_crc_control( VCHI_CONNECTION_T *connection,
                                 VCHI_CRC_CONTROL_T control );

// helper functions
void * vchi_allocate_buffer(VCHI_SERVICE_HANDLE_T handle, uint32_t *length);
void vchi_free_buffer(VCHI_SERVICE_HANDLE_T handle, void *address);
uint32_t vchi_current_time(VCHI_INSTANCE_T instance_handle);
]]

ffi.cdef[[
/******************************************************************************
 Global service API
 *****************************************************************************/
// Routine to create a named service
extern int32_t vchi_service_create( VCHI_INSTANCE_T instance_handle,
                                    SERVICE_CREATION_T *setup,
                                    VCHI_SERVICE_HANDLE_T *handle );

// Routine to destory a service
extern int32_t vchi_service_destroy( const VCHI_SERVICE_HANDLE_T handle );

// Routine to open a named service
extern int32_t vchi_service_open( VCHI_INSTANCE_T instance_handle,
                                  SERVICE_CREATION_T *setup,
                                  VCHI_SERVICE_HANDLE_T *handle);

// Routine to close a named service
extern int32_t vchi_service_close( const VCHI_SERVICE_HANDLE_T handle );

// Routine to increment ref count on a named service
extern int32_t vchi_service_use( const VCHI_SERVICE_HANDLE_T handle );

// Routine to decrement ref count on a named service
extern int32_t vchi_service_release( const VCHI_SERVICE_HANDLE_T handle );

// Routine to send a message accross a service
extern int32_t vchi_msg_queue( VCHI_SERVICE_HANDLE_T handle,
                               const void *data,
                               uint32_t data_size,
                               VCHI_FLAGS_T flags,
                               void *msg_handle );

// scatter-gather (vector) and send message
int32_t vchi_msg_queuev_ex( VCHI_SERVICE_HANDLE_T handle,
                            VCHI_MSG_VECTOR_EX_T *vector,
                            uint32_t count,
                            VCHI_FLAGS_T flags,
                            void *msg_handle );

// legacy scatter-gather (vector) and send message, only handles pointers
int32_t vchi_msg_queuev( VCHI_SERVICE_HANDLE_T handle,
                         VCHI_MSG_VECTOR_T *vector,
                         uint32_t count,
                         VCHI_FLAGS_T flags,
                         void *msg_handle );

// Routine to receive a msg from a service
// Dequeue is equivalent to hold, copy into client buffer, release
extern int32_t vchi_msg_dequeue( VCHI_SERVICE_HANDLE_T handle,
                                 void *data,
                                 uint32_t max_data_size_to_read,
                                 uint32_t *actual_msg_size,
                                 VCHI_FLAGS_T flags );

// Routine to look at a message in place.
// The message is not dequeued, so a subsequent call to peek or dequeue
// will return the same message.
extern int32_t vchi_msg_peek( VCHI_SERVICE_HANDLE_T handle,
                              void **data,
                              uint32_t *msg_size,
                              VCHI_FLAGS_T flags );

// Routine to remove a message after it has been read in place with peek
// The first message on the queue is dequeued.
extern int32_t vchi_msg_remove( VCHI_SERVICE_HANDLE_T handle );

// Routine to look at a message in place.
// The message is dequeued, so the caller is left holding it; the descriptor is
// filled in and must be released when the user has finished with the message.
extern int32_t vchi_msg_hold( VCHI_SERVICE_HANDLE_T handle,
                              void **data,        // } may be NULL, as info can be
                              uint32_t *msg_size, // } obtained from HELD_MSG_T
                              VCHI_FLAGS_T flags,
                              VCHI_HELD_MSG_T *message_descriptor );

// Initialise an iterator to look through messages in place
extern int32_t vchi_msg_look_ahead( VCHI_SERVICE_HANDLE_T handle,
                                    VCHI_MSG_ITER_T *iter,
                                    VCHI_FLAGS_T flags );
]]

ffi.cdef[[
/******************************************************************************
 Global service support API - operations on held messages and message iterators
 *****************************************************************************/

// Routine to get the address of a held message
void *vchi_held_msg_ptr( const VCHI_HELD_MSG_T *message );

// Routine to get the size of a held message
int32_t vchi_held_msg_size( const VCHI_HELD_MSG_T *message );

// Routine to get the transmit timestamp as written into the header by the peer
uint32_t vchi_held_msg_tx_timestamp( const VCHI_HELD_MSG_T *message );

// Routine to get the reception timestamp, written as we parsed the header
uint32_t vchi_held_msg_rx_timestamp( const VCHI_HELD_MSG_T *message );

// Routine to release a held message after it has been processed
int32_t vchi_held_msg_release( VCHI_HELD_MSG_T *message );

// Indicates whether the iterator has a next message.
vcos_bool_t vchi_msg_iter_has_next( const VCHI_MSG_ITER_T *iter );

// Return the pointer and length for the next message and advance the iterator.
int32_t vchi_msg_iter_next( VCHI_MSG_ITER_T *iter,
                                   void **data,
                                   uint32_t *msg_size );

// Remove the last message returned by vchi_msg_iter_next.
// Can only be called once after each call to vchi_msg_iter_next.
int32_t vchi_msg_iter_remove( VCHI_MSG_ITER_T *iter );

// Hold the last message returned by vchi_msg_iter_next.
// Can only be called once after each call to vchi_msg_iter_next.
int32_t vchi_msg_iter_hold( VCHI_MSG_ITER_T *iter,
                                   VCHI_HELD_MSG_T *message );

// Return information for the next message, and hold it, advancing the iterator.
int32_t vchi_msg_iter_hold_next( VCHI_MSG_ITER_T *iter,
                                        void **data,        // } may be NULL
                                        uint32_t *msg_size, // }
                                        VCHI_HELD_MSG_T *message );
]]

ffi.cdef[[
/******************************************************************************
 Global bulk API
 *****************************************************************************/

// Routine to prepare interface for a transfer from the other side
int32_t vchi_bulk_queue_receive( VCHI_SERVICE_HANDLE_T handle,
                                        void *data_dst,
                                        uint32_t data_size,
                                        VCHI_FLAGS_T flags,
                                        void *transfer_handle );


// Prepare interface for a transfer from the other side into relocatable memory.
int32_t vchi_bulk_queue_receive_reloc( const VCHI_SERVICE_HANDLE_T handle,
                                       VCHI_MEM_HANDLE_T h_dst,
                                       uint32_t offset,
                                       uint32_t data_size,
                                       const VCHI_FLAGS_T flags,
                                       void * const bulk_handle );

// Routine to queue up data ready for transfer to the other (once they have signalled they are ready)
int32_t vchi_bulk_queue_transmit( VCHI_SERVICE_HANDLE_T handle,
                                         const void *data_src,
                                         uint32_t data_size,
                                         VCHI_FLAGS_T flags,
                                         void *transfer_handle );
]]

ffi.cdef[[
/******************************************************************************
 Configuration plumbing
 *****************************************************************************/

// function prototypes for the different mid layers (the state info gives the different physical connections)
const VCHI_CONNECTION_API_T *single_get_func_table( void );
//extern const VCHI_CONNECTION_API_T *local_server_get_func_table( void );
//extern const VCHI_CONNECTION_API_T *local_client_get_func_table( void );

// declare all message drivers here
const VCHI_MESSAGE_DRIVER_T *vchi_mphi_message_driver_func_table( void );
]]

ffi.cdef[[
int32_t vchi_bulk_queue_transmit_reloc( VCHI_SERVICE_HANDLE_T handle,
                                               VCHI_MEM_HANDLE_T h_src,
                                               uint32_t offset,
                                               uint32_t data_size,
                                               VCHI_FLAGS_T flags,
                                               void *transfer_handle );
]]


return {
	Lib = ffi.load("vchiq_arm"),
}
