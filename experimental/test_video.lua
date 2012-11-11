
package.path = package.path..";../?.lua"

local ffi = require "ffi"
local C = ffi.C;
local bit = require "bit"
local bor = bit.bor
local band = bit.band
local lshift = bit.lshift


-- Video deocode demo using OpenMAX IL through the ilcient helper library


local rpiui = require "rpiui"
require "ilclient"

OMX = require "OMX"


funcion video_decode_test(filename)

   OMX_VIDEO_PARAM_PORTFORMATTYPE format;
   OMX_TIME_CONFIG_CLOCKSTATETYPE cstate;
   COMPONENT_T *video_decode = NULL, *video_scheduler = NULL, *video_render = NULL, *clock = NULL;
   COMPONENT_T *list[5];
   TUNNEL_T tunnel[4];
   ILCLIENT_T *client;
   local status = 0;
   unsigned char *data = NULL;
   unsigned int data_len = 0;
   local find_start_codes = false;
   local packet_size = lshift(16,10);   

   memset(list, 0, sizeof(list));
   memset(tunnel, 0, sizeof(tunnel));

   local in = io.open(filename, "rb");
   if not in then
      return -2;
   end

   client = ilclient_init()
   if(client == nil) then
      in:close();
      return -3;
   end

   if(OMX_Init() ~= ffi.C.OMX_ErrorNone) then
   
      ilclient_destroy(client);
      in:close();
      return -4;
   end

   if(find_start_codes and (data = malloc(packet_size+4)) == nil)
   {
      status = -16;
      if(OMX_Deinit() != OMX_ErrorNone)
         status = -17;
      ilclient_destroy(client);
      fclose(in);
      return status;
   }

   // create video_decode
   if(ilclient_create_component(client, &video_decode, "video_decode", ILCLIENT_DISABLE_ALL_PORTS | ILCLIENT_ENABLE_INPUT_BUFFERS) ~= 0) then
      status = -14;
   end

   list[0] = video_decode;

   // create video_render
   if(status == 0 and ilclient_create_component(client, &video_render, "video_render", ILCLIENT_DISABLE_ALL_PORTS) ~= 0) then
      status = -14;
   end

   list[1] = video_render;

   // create clock
   if(status == 0 and ilclient_create_component(client, &clock, "clock", ILCLIENT_DISABLE_ALL_PORTS) ~= 0) then
      status = -14;
   end

   list[2] = clock;

   ffi.set(cstate, 0, ffi.sizeof(cstate));
   cstate.nSize = ffi.sizeof(cstate);
   cstate.nVersion.nVersion = ffi.C.OMX_VERSION;
   cstate.eState = ffi.C.OMX_TIME_ClockStateWaitingForStartTime;
   cstate.nWaitMask = 1;
   if(clock ~= nil and OMX_SetParameter(ILC_GET_HANDLE(clock), OMX_IndexConfigTimeClockState, &cstate) ~= OMX_ErrorNone) then
      status = -13;
   end

   // create video_scheduler
   if(status == 0 and ilclient_create_component(client, &video_scheduler, "video_scheduler", ILCLIENT_DISABLE_ALL_PORTS) ~= 0) then
      status = -14;
   end

   list[3] = video_scheduler;

   set_tunnel(tunnel, video_decode, 131, video_scheduler, 10);
   set_tunnel(tunnel+1, video_scheduler, 11, video_render, 90);
   set_tunnel(tunnel+2, clock, 80, video_scheduler, 12);

   // setup clock tunnel first
   if(status == 0 and ilclient_setup_tunnel(tunnel+2, 0, 0) ~= 0) then
      status = -15;
   else
      ilclient_change_component_state(clock, OMX_StateExecuting);
   end

   if(status == 0) then
      ilclient_change_component_state(video_decode, OMX_StateIdle);
   end

   ffi.set(format, 0, ffi.sizeof(OMX_VIDEO_PARAM_PORTFORMATTYPE));
   format.nSize = ffi.sizeof(OMX_VIDEO_PARAM_PORTFORMATTYPE);
   format.nVersion.nVersion = OMX_VERSION;
   format.nPortIndex = 130;
   format.eCompressionFormat = OMX_VIDEO_CodingAVC;

   if(status == 0 and
      OMX_SetParameter(ILC_GET_HANDLE(video_decode), OMX_IndexParamVideoPortFormat, &format) == OMX_ErrorNone &&
      ilclient_enable_port_buffers(video_decode, 130, NULL, NULL, NULL) == 0) then
   
      OMX_BUFFERHEADERTYPE *buf;
      int port_settings_changed = 0;
      int first_packet = 1;

      ilclient_change_component_state(video_decode, OMX_StateExecuting);

      while((buf = ilclient_get_input_buffer(video_decode, 130, 1)) != NULL)
      {
         // feed data and wait until we get port settings changed
         unsigned char *dest = find_start_codes ? data + data_len : buf->pBuffer;

         data_len += fread(dest, 1, packet_size+(find_start_codes*4)-data_len, in);

         if(port_settings_changed == 0 &&
            ((data_len > 0 && ilclient_remove_event(video_decode, OMX_EventPortSettingsChanged, 131, 0, 0, 1) == 0) ||
             (data_len == 0 && ilclient_wait_for_event(video_decode, OMX_EventPortSettingsChanged, 131, 0, 0, 1,
                                                       ILCLIENT_EVENT_ERROR | ILCLIENT_PARAMETER_CHANGED, 10000) == 0)))
         {
            port_settings_changed = 1;

            if(ilclient_setup_tunnel(tunnel, 0, 0) != 0)
            {
               status = -7;
               break;
            }

            ilclient_change_component_state(video_scheduler, OMX_StateExecuting);

            // now setup tunnel to video_render
            if(ilclient_setup_tunnel(tunnel+1, 0, 1000) != 0)
            {
               status = -12;
               break;
            }
            
            ilclient_change_component_state(video_render, OMX_StateExecuting);
         }
         if(!data_len)
            break;

         if(find_start_codes)
         {
            int i, start = -1, len = 0;
            int max_len = data_len > packet_size ? packet_size : data_len;
            for(i=2; i<max_len; i++)
            {
               if(data[i-2] == 0 && data[i-1] == 0 && data[i] == 1)
               {
                  len = 3;
                  start = i-2;

                  // check for 4 byte start code
                  if(i > 2 && data[i-3] == 0)
                  {
                     len++;
                     start--;
                  }

                  break;
               }
            }

            if(start == 0)
            {
               // start code is next, so just send that
               buf->nFilledLen = len;
            }
            else if(start == -1)
            {
               // no start codes seen, send the first block
               buf->nFilledLen = max_len;
            }
            else
            {
               // start code in the middle of the buffer, send up to the code
               buf->nFilledLen = start;
            }

            memcpy(buf->pBuffer, data, buf->nFilledLen);
            memmove(data, data + buf->nFilledLen, data_len - buf->nFilledLen);
            data_len -= buf->nFilledLen;
         }
         else
         {
            buf->nFilledLen = data_len;
            data_len = 0;
         }

         buf->nOffset = 0;
         if(first_packet)
         {
            buf->nFlags = OMX_BUFFERFLAG_STARTTIME;
            first_packet = 0;
         }
         else
            buf->nFlags = OMX_BUFFERFLAG_TIME_UNKNOWN;

         if(OMX_EmptyThisBuffer(ILC_GET_HANDLE(video_decode), buf) != OMX_ErrorNone)
         {
            status = -6;
            break;
         }
         
      }

      buf->nFilledLen = 0;
      buf->nFlags = OMX_BUFFERFLAG_TIME_UNKNOWN | OMX_BUFFERFLAG_EOS;
      
      if(OMX_EmptyThisBuffer(ILC_GET_HANDLE(video_decode), buf) != OMX_ErrorNone)
         status = -20;
      
      // wait for EOS from render
      ilclient_wait_for_event(video_render, OMX_EventBufferFlag, 90, 0, OMX_BUFFERFLAG_EOS, 0,
                              ILCLIENT_BUFFER_FLAG_EOS, 10000);
      
      // need to flush the renderer to allow video_decode to disable its input port
      ilclient_flush_tunnels(tunnel, 0);

      ilclient_disable_port_buffers(video_decode, 130, NULL, NULL, NULL);
   end

   in:close();

   ilclient_disable_tunnel(tunnel);
   ilclient_disable_tunnel(tunnel+1);
   ilclient_disable_tunnel(tunnel+2);
   ilclient_teardown_tunnels(tunnel);

   ilclient_state_transition(list, OMX_StateIdle);
   ilclient_state_transition(list, OMX_StateLoaded);

   ilclient_cleanup_components(list);

   OMX_Deinit();

   ilclient_destroy(client);
   
   return status;
end

function main (filename)
	return video_decode_test(filename);
end

if not arg[1] then
	printf("Usage: luajit test_video.lua <filename>");
	return false
end

main(arg[1]);



--[[
/*
Copyright (c) 2012, Broadcom Europe Ltd
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the copyright holder nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
--]]
