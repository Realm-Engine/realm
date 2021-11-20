module realm.engine.internal.glutils;

import derelict.opengl3.gl3;



void bufferDataUtil(T)(GLenum type ,const T[] data,GLenum usage)
{
	glBufferData(type,data.length * T.sizeof,data.ptr,usage);
}


void clearBufferUtil(GLenum type, GLenum usage)
{
	glBufferData(type,0,null,usage);
}

