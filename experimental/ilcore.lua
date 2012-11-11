

--[[
 * \file
 *
 * \brief Host core implementation.
--]]


require "OMX_Component"
require "vcos"

require "interface/vmcs_host/vcilcs.h"
require "interface/vmcs_host/vchost.h"
require "interface/vmcs_host/vcilcs_common.h"

local coreInit = 0;
local nActiveHandles = 0;
local ILCS_SERVICE_T *ilcs_service = nil;
local VCOS_MUTEX_T lock;
local VCOS_ONCE_T once = VCOS_ONCE_INIT;

--[[ Atomic creation of lock protecting shared state --]]
void initOnce(void)
   local plock = ffi.new("VCOS_MUTEX_T[1]");

   local status = vcos_mutex_create(plock, VCOS_FUNCTION);
   vcos_demand(status == VCOS_SUCCESS);
   lock = plock[0];
end

--[[ OMX_Init --]]
function OMX_Init(void)

   local err = ffi.C.OMX_ErrorNone;

   local status = vcos_once(&once, initOnce);
   vcos_demand(status == VCOS_SUCCESS);

   vcos_mutex_lock(&lock);
   
   if(coreInit == 0) then
   
      // we need to connect via an ILCS connection to VideoCore
      VCHI_INSTANCE_T initialise_instance;
      VCHI_CONNECTION_T *connection;
      ILCS_CONFIG_T config;

      vc_host_get_vchi_state(&initialise_instance, &connection);

      vcilcs_config(&config);

      ilcs_service = ilcs_init((VCHIQ_INSTANCE_T) initialise_instance, (void **) &connection, &config, 0);

      if(ilcs_service == nil)
      {
         err = OMX_ErrorHardware;
         goto end;
      }

      coreInit = 1;
   
   else
      coreInit++;
   end

end:
   vcos_mutex_unlock(&lock);
   return err;
end

--[[ OMX_Deinit --]]
function OMX_Deinit()

   if(coreInit == 0) then -- || (coreInit == 1 && nActiveHandles > 0))
      return OMX_ErrorNotReady;
   end

   vcos_mutex_lock(&lock);

   coreInit--;

   if(coreInit == 0) then
   
      // we need to teardown the ILCS connection to VideoCore
      ilcs_deinit(ilcs_service);
      ilcs_service = nil;
   end

   vcos_mutex_unlock(&lock);
   
   return OMX_ErrorNone;
end


--[[ OMX_ComponentNameEnum --]]
function OMX_ComponentNameEnum(OMX_STRING cComponentName, OMX_U32 nNameLength, OMX_U32 nIndex)

   if(ilcs_service == nil)
      return OMX_ErrorBadParameter;

   return vcil_out_component_name_enum(ilcs_get_common(ilcs_service), cComponentName, nNameLength, nIndex);
end


--[[ OMX_GetHandle --]]
function OMX_GetHandle(OMX_HANDLETYPE* pHandle, OMX_STRING cComponentName, OMX_PTR pAppData, OMX_CALLBACKTYPE* pCallBacks)

   OMX_ERRORTYPE eError;
   OMX_COMPONENTTYPE *pComp;
   OMX_HANDLETYPE hHandle = 0;

   if (pHandle == nil or cComponentName == nil or pCallBacks == nil or ilcs_service == nil) then
   
      if(pHandle ~= nil) then
         pHandle[0] = nil;
      end

      return OMX_ErrorBadParameter;
   end

   {
      pComp = (OMX_COMPONENTTYPE *)malloc(sizeof(OMX_COMPONENTTYPE));
      if (!pComp)
      {
         vcos_assert(0);
         return OMX_ErrorInsufficientResources;
      }
      memset(pComp, 0, sizeof(OMX_COMPONENTTYPE));
      hHandle = (OMX_HANDLETYPE)pComp;
      pComp.nSize = sizeof(OMX_COMPONENTTYPE);
      pComp.nVersion.nVersion = OMX_VERSION;
      eError = vcil_out_create_component(ilcs_get_common(ilcs_service), hHandle, cComponentName);

      if (eError == OMX_ErrorNone) then
         // Check that all function pointers have been filled in.
         // All fields should be non-zero.
         int i;
         uint32_t *p = (uint32_t *) pComp;
         for(i=0; i<sizeof(OMX_COMPONENTTYPE)>>2; i++)
            if(*p++ == 0)
               eError = OMX_ErrorInvalidComponent;

         if(eError ~= OMX_ErrorNone && pComp.ComponentDeInit) then
            pComp.ComponentDeInit(hHandle);
         end
      end

      if (eError == OMX_ErrorNone) then
         eError = pComp.SetCallbacks(hHandle,pCallBacks,pAppData);
         if (eError ~= OMX_ErrorNone)
            pComp.ComponentDeInit(hHandle);
      end

      if (eError == OMX_ErrorNone) then
         pHandle[0] = hHandle;
      else 
         pHandle[0] = nil;
         free(pComp);
      end
   } 

   if (eError == OMX_ErrorNone) then
      vcos_mutex_lock(&lock);
      nActiveHandles = nActiveHandles + 1;
      vcos_mutex_unlock(&lock);
   end

   return eError;
end

--[[ OMX_FreeHandle --]]
OMX_ERRORTYPE OMX_FreeHandle(OMX_HANDLETYPE hComponent)

   OMX_ERRORTYPE eError = OMX_ErrorNone;
   OMX_COMPONENTTYPE *pComp;

   if (hComponent == nil || ilcs_service == nil)
      return OMX_ErrorBadParameter;

   pComp = (OMX_COMPONENTTYPE*)hComponent;

   if (ilcs_service == nil)
      return OMX_ErrorBadParameter;

   eError = (pComp.ComponentDeInit)(hComponent);
   if (eError == OMX_ErrorNone) {
      vcos_mutex_lock(&lock);
      --nActiveHandles;
      vcos_mutex_unlock(&lock);
      free(pComp);
   }

   vcos_assert(nActiveHandles >= 0);

   return eError;
end

--[[ OMX_SetupTunnel --]]
OMX_ERRORTYPE OMX_SetupTunnel(OMX_HANDLETYPE hOutput,OMX_U32 nPortOutput,OMX_HANDLETYPE hInput,OMX_U32 nPortInput)

   OMX_ERRORTYPE eError = OMX_ErrorNone;
   OMX_COMPONENTTYPE *pCompIn, *pCompOut;
   OMX_TUNNELSETUPTYPE oTunnelSetup;

   if ((hOutput == nil && hInput == nil) || ilcs_service == nil)
      return OMX_ErrorBadParameter;

   oTunnelSetup.nTunnelFlags = 0;
   oTunnelSetup.eSupplier = OMX_BufferSupplyUnspecified;

   pCompOut = (OMX_COMPONENTTYPE*)hOutput;

   if (hOutput){
      eError = pCompOut.ComponentTunnelRequest(hOutput, nPortOutput, hInput, nPortInput, &oTunnelSetup);
   }

   if (eError == OMX_ErrorNone && hInput) {
      pCompIn = (OMX_COMPONENTTYPE*)hInput;
      eError = pCompIn.ComponentTunnelRequest(hInput, nPortInput, hOutput, nPortOutput, &oTunnelSetup);

      if (eError ~= OMX_ErrorNone && hOutput) {
         --[[ cancel tunnel request on output port since input port failed --]]
         pCompOut.ComponentTunnelRequest(hOutput, nPortOutput, nil, 0, nil);
      }
   }
   return eError;
end

--[[ OMX_GetComponentsOfRole --]]
OMX_ERRORTYPE OMX_GetComponentsOfRole (OMX_STRING role, OMX_U32 *pNumComps, OMX_U8  **compNames)

   local eError = ffi.C.OMX_ErrorNone;

   *pNumComps = 0;
   return eError;
end

--[[ OMX_GetRolesOfComponent --]]
function OMX_GetRolesOfComponent (OMX_STRING compName, OMX_U32 *pNumRoles, OMX_U8 **roles)

   local eError = ffi.C.OMX_ErrorNone;

   *pNumRoles = 0;
   return eError;
end

--[[ OMX_GetDebugInformation --]]
function OMX_GetDebugInformation (OMX_STRING debugInfo, OMX_S32 *pLen)

   if(ilcs_service == nil) then
      return OMX_ErrorBadParameter;
   end

   return vcil_out_get_debug_information(ilcs_get_common(ilcs_service), debugInfo, pLen);
end


--[[
--[[
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
--]]
--]]
