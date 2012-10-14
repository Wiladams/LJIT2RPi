local ffi = require "ffi"

require "gl"

local gl   = ffi.load( "GLESv2" )





OglMan={
	Lib = gl;
}




--[[
	Convenience aliases
--]]

-- Available only in Common profile 
glAlphaFunc = gl.glAlphaFunc ;
glClearColor = gl.glClearColor;
glClearDepthf = gl.glClearDepthf;
glClipPlanef = gl.glClipPlanef;
glColor4f = gl.glColor4f;
glDepthRangef = gl.glDepthRangef;
glFogf = gl.glFogf;
glFogfv = gl.glFogfv;
glFrustumf = gl.glFrustumf;
glGetClipPlanef = gl.glGetClipPlanef;
glGetFloatv = gl.glGetFloatv;
glGetLightfv = gl.glGetLightfv;
glGetMaterialfv = gl.glGetMaterialfv;
glGetTexEnvfv = gl.glGetTexEnvfv;
glGetTexParameterfv = gl.glGetTexParameterfv;
glLightModelf = gl.glLightModelf;
glLightModelfv = gl.glLightModelfv;
glLightf = gl.glLightf;
glLightfv = gl.glLightfv;
glLineWidth = gl.glLineWidth;
glLoadMatrixf = gl.glLoadMatrixf;
glMaterialf = gl.glMaterialf;
glMaterialfv = gl.glMaterialfv;
glMultMatrixf = gl.glMultMatrixf ;
glMultiTexCoord4f = gl.glMultiTexCoord4f;
glNormal3f = gl.glNormal3f;
glOrthof = gl.glOrthof;
glPointParameterf = gl.glPointParameterf;
glPointParameterfv = gl.glPointParameterfv;
glPointSize = gl.glPointSize;
glPolygonOffset = gl.glPolygonOffset;
glRotatef = gl.glRotatef;
glScalef = gl.glScalef;
glTexEnvf = gl.glTexEnvf;
glTexEnvfv = gl.glTexEnvfv;
glTexParameterf = gl.glTexParameterf;
glTexParameterfv = gl.glTexParameterfv;
glTranslatef = gl.glTranslatef;


-- Available in both Common and Common-Lite profiles 
glActiveTexture = gl.glActiveTexture; -- (GLenum texture);
glAlphaFuncx = gl.glAlphaFuncx; -- (GLenum func, GLclampx ref);
glBindBuffer = gl.glBindBuffer; -- (GLenum target, GLuint buffer);
glBindTexture = gl.glBindTexture; -- (GLenum target, GLuint texture);
glBlendFunc = gl.glBlendFunc; -- (GLenum sfactor, GLenum dfactor);
glBufferData = gl.glBufferData; -- (GLenum target, GLsizeiptr size, const GL*data, GLenum usage);
glBufferSubData = gl.glBufferSubData; -- (GLenum target, GLintptr offset, GLsizeiptr size, const GL*data);
glClear = gl.glClear; -- (GLbitfield mask);
glClearColorx = gl.glClearColorx; -- (GLclampx red, GLclampx green, GLclampx blue, GLclampx alpha);
glClearDepthx = gl.glClearDepthx; -- (GLclampx depth);
glClearStencil = gl.glClearStencil; -- (GLint s);
glClientActiveTexture = gl.glClientActiveTexture; -- (GLenum texture);
glClipPlanex = gl.glClipPlanex; -- (GLenum plane, const GLfixed *equation);
glColor4ub = gl.glColor4ub; -- (GLubyte red, GLubyte green, GLubyte blue, GLubyte alpha);
glColor4x = gl.glColor4x; -- (GLfixed red, GLfixed green, GLfixed blue, GLfixed alpha);
glColorMask = gl.glColorMask; -- (GLboolean red, GLboolean green, GLboolean blue, GLboolean alpha);
glColorPointer = gl.glColorPointer; -- (GLint size, GLenum type, GLsizei stride, const GL*pointer);
glCompressedTexImage2D = gl.glCompressedTexImage2D; -- (GLenum target, GLint level, GLenum internalformat, GLsizei width, GLsizei height, GLint border, GLsizei imageSize, const GL*data);
glCompressedTexSubImage2D= gl.glCompressedTexSubImage2D; -- (GLenum target, GLint level, GLint xoffset, GLint yoffset, GLsizei width, GLsizei height, GLenum format, GLsizei imageSize, const GL*data);
glCopyTexImage2D = gl.glCopyTexImage2D; -- (GLenum target, GLint level, GLenum internalformat, GLint x, GLint y, GLsizei width, GLsizei height, GLint border);
glCopyTexSubImage2D = gl.glCopyTexSubImage2D; -- (GLenum target, GLint level, GLint xoffset, GLint yoffset, GLint x, GLint y, GLsizei width, GLsizei height);
glCullFace = gl.glCullFace; -- (GLenum mode);
glDeleteBuffers = gl.glDeleteBuffers; -- (GLsizei n, const GLuint *buffers);
glDeleteTextures = gl.glDeleteTextures; -- (GLsizei n, const GLuint *textures);
glDepthFunc = gl.glDepthFunc; -- (GLenum func);
glDepthMask = gl.glDepthMask; -- (GLboolean flag);
glDepthRangex = gl.glDepthRangex; -- (GLclampx zNear, GLclampx zFar);
glDisable = gl.glDisable; -- (GLenum cap);
glDisableClientState = gl.glDisableClientState; -- (GLenum array);
glDrawArrays = gl.glDrawArrays; -- (GLenum mode, GLint first, GLsizei count);
glDrawElements = gl.glDrawElements; -- (GLenum mode, GLsizei count, GLenum type, const GL*indices);
glEnable = gl.glEnable; -- (GLenum cap);
glEnableClientState = gl.glEnableClientState; -- (GLenum array);
glFinish = gl.glFinish; -- (void);
glFlush = gl.glFlush; -- (void);
glFogx = gl.glFogx; -- (GLenum pname, GLfixed param);
glFogxv = gl.glFogxv; -- (GLenum pname, const GLfixed *params);
glFrontFace = gl.glFrontFace; -- (GLenum mode);
glFrustumx = gl.glFrustumx; -- (GLfixed left, GLfixed right, GLfixed bottom, GLfixed top, GLfixed zNear, GLfixed zFar);
glGetBooleanv = gl.glGetBooleanv; -- (GLenum pname, GLboolean *params);
glGetBufferParameteriv = gl.glGetBufferParameteriv; -- (GLenum target, GLenum pname, GLint *params);
glGetClipPlanex = gl.glGetClipPlanex; -- (GLenum pname, GLfixed eqn[4]);
glGenBuffers = gl.glGenBuffers; -- (GLsizei n, GLuint *buffers);
glGenTextures = gl.glGenTextures; -- (GLsizei n, GLuint *textures);
glGetError = gl.glGetError; -- (void);
glGetFixedv = gl.glGetFixedv; -- (GLenum pname, GLfixed *params);
glGetIntegerv = gl.glGetIntegerv; -- (GLenum pname, GLint *params);
glGetLightxv = gl.glGetLightxv; -- (GLenum light, GLenum pname, GLfixed *params);
glGetMaterialxv = gl.glGetMaterialxv; -- (GLenum face, GLenum pname, GLfixed *params);
glGetPointerv = gl.glGetPointerv; -- (GLenum pname, GL**params);
glGetString = gl.glGetString; -- (GLenum name);
glGetTexEnviv = gl.glGetTexEnviv; -- (GLenum env, GLenum pname, GLint *params);
glGetTexEnvxv = gl.glGetTexEnvxv; -- (GLenum env, GLenum pname, GLfixed *params);
glGetTexParameteriv = gl.glGetTexParameteriv; -- (GLenum target, GLenum pname, GLint *params);
glGetTexParameterxv = gl.glGetTexParameterxv; -- (GLenum target, GLenum pname, GLfixed *params);
glHint = gl.glHint; -- (GLenum target, GLenum mode);
glIsBuffer = gl.glIsBuffer; -- (GLuint buffer);
glIsEnabled = gl.glIsEnabled; -- (GLenum cap);
glIsTexture = gl.glIsTexture; -- (GLuint texture);
glLightModelx = gl.glLightModelx; -- (GLenum pname, GLfixed param);
glLightModelxv = gl.glLightModelxv; -- (GLenum pname, const GLfixed *params);
glLightx = gl.glLightx; -- (GLenum light, GLenum pname, GLfixed param);
glLightxv = gl.glLightxv; -- (GLenum light, GLenum pname, const GLfixed *params);
glLineWidthx = gl.glLineWidthx; -- (GLfixed width);
glLoadIdentity = gl.glLoadIdentity; -- (void);
glLoadMatrixx = gl.glLoadMatrixx; -- (const GLfixed *m);
glLogicOp = gl.glLogicOp; -- (GLenum opcode);
glMaterialx = gl.glMaterialx; -- (GLenum face, GLenum pname, GLfixed param);
glMaterialxv = gl.glMaterialxv; -- (GLenum face, GLenum pname, const GLfixed *params);
glMatrixMode = gl.glMatrixMode; -- (GLenum mode);
glMultMatrixx = gl.glMultMatrixx; -- (const GLfixed *m);
glMultiTexCoord = gl.glMultiTexCoord4x; -- (GLenum target, GLfixed s, GLfixed t, GLfixed r, GLfixed q);
glNormal = gl.glNormal3x; -- (GLfixed nx, GLfixed ny, GLfixed nz);
glNormalPointer = gl.glNormalPointer; -- (GLenum type, GLsizei stride, const GL*pointer);
glOrthox = gl.glOrthox; -- (GLfixed left, GLfixed right, GLfixed bottom, GLfixed top, GLfixed zNear, GLfixed zFar);
glPixelStorei = gl.glPixelStorei; -- (GLenum pname, GLint param);
glPointParameterx = gl.glPointParameterx; -- (GLenum pname, GLfixed param);
glPointParameterxv = gl.glPointParameterxv; -- (GLenum pname, const GLfixed *params);
glPointSizex = gl.glPointSizex; -- (GLfixed size);
glPolygonOffsetx = gl.glPolygonOffsetx; -- (GLfixed factor, GLfixed units);
glPopMatrix = gl.glPopMatrix; -- (void);
glPushMatrix = gl.glPushMatrix; -- (void);
glReadPixels = gl.glReadPixels; -- (GLint x, GLint y, GLsizei width, GLsizei height, GLenum format, GLenum type, GL*pixels);
glRotatex = gl.glRotatex; -- (GLfixed angle, GLfixed x, GLfixed y, GLfixed z);
glSampleCoverage = gl.glSampleCoverage; -- (GLclampf value, GLboolean invert);
glSampleCoveragex = gl.glSampleCoveragex; -- (GLclampx value, GLboolean invert);
glScalex = gl.glScalex; -- (GLfixed x, GLfixed y, GLfixed z);
glScissor = gl.glScissor; -- (GLint x, GLint y, GLsizei width, GLsizei height);
glShadeModel = gl.glShadeModel; -- (GLenum mode);
glStencilFunc = gl.glStencilFunc; -- (GLenum func, GLint ref, GLuint mask);
glStencilMask = gl.glStencilMask; -- (GLuint mask);
glStencilOp = gl.glStencilOp; -- (GLenum fail, GLenum zfail, GLenum zpass);
glTexCoordPointer = gl.glTexCoordPointer; -- (GLint size, GLenum type, GLsizei stride, const GL*pointer);
glTexEnvi = gl.glTexEnvi; -- (GLenum target, GLenum pname, GLint param);
glTexEnvx = gl.glTexEnvx; -- (GLenum target, GLenum pname, GLfixed param);
glTexEnviv = gl.glTexEnviv; -- (GLenum target, GLenum pname, const GLint *params);
glTexEnvxv = gl.glTexEnvxv; -- (GLenum target, GLenum pname, const GLfixed *params);
glTexImage2D = gl.glTexImage2D; -- (GLenum target, GLint level, GLint internalformat, GLsizei width, GLsizei height, GLint border, GLenum format, GLenum type, const GL*pixels);
glTexParameteri = gl.glTexParameteri; -- (GLenum target, GLenum pname, GLint param);
glTexParameterx = gl.glTexParameterx; -- (GLenum target, GLenum pname, GLfixed param);
glTexParameteriv = gl.glTexParameteriv; -- (GLenum target, GLenum pname, const GLint *params);
glTexParameterxv = gl.glTexParameterxv; -- (GLenum target, GLenum pname, const GLfixed *params);
glTexSubImage2D = gl.glTexSubImage2D; -- (GLenum target, GLint level, GLint xoffset, GLint yoffset, GLsizei width, GLsizei height, GLenum format, GLenum type, const GL*pixels);
glTranslatex = gl.glTranslatex; -- (GLfixed x, GLfixed y, GLfixed z);
glVertexPointer = gl.glVertexPointer; -- (GLint size, GLenum type, GLsizei stride, const GL*pointer);
glViewport = gl.glViewport; -- (GLint x, GLint y, GLsizei width, GLsizei height);







return OglMan;
