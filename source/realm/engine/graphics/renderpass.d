 module realm.engine.graphics.renderpass;

private
{
	import realm.engine.graphics.core : ImageFormat;
}

struct UseRenderpass
{
	string name;
	int order;
}

class Renderpass(ImageFormat[string] passInputs,ImageFormat[string] passOutputs)
{
	private
	{
		import realm.engine.graphics.core;
	}
	@("Inputs")
	{
		struct Inputs
		{
			static foreach(attachment ; passInputs.keys)
			{
				mixin("FrameBufferAttachment* " ~ attachment ~ ";");
				
			}
		}
	}
	@("Outputs")
	{
		struct Outputs
		{
			static foreach(attachment; passOutputs.keys)
			{
				mixin("FrameBufferAttachment* " ~ attachment ~ ";");
				
				
			}
		}
	}
	private FrameBuffer framebuffer;
	public Inputs inputs;
	private Outputs outputs;
	

	public ref FrameBuffer getFramebuffer()
	{
		return framebuffer;
	}

	
	public ref Outputs getOutputs()
	{
		return outputs;
	}
	this(int width, int height, bool multisampled = false)
	out
	{
		import realm.engine.logging;
		Logger.Assert(framebuffer.isComplete,"Framebuffer is not complete");
	}
	do
	{
		
		framebuffer.create(width,height);
		int numColorAttachments = 0;
		static foreach(member; __traits(allMembers,Outputs))
		{
			{

				FrameBufferAttachmentType type;
				ImageFormat format = passOutputs[member];
				if(format == ImageFormat.DEPTH)
				{
					type = FrameBufferAttachmentType.DEPTH_ATTACHMENT;
				}
				else
				{
					type = FrameBufferAttachmentType.COLOR_ATTACHMENT;
					numColorAttachments++;
				}

				
				__traits(getMember,outputs,member) = framebuffer.addAttachment(type,format,multisampled);



			}
		}
		
	}



	void bindAttachments(StandardShaderModel program)
	{
		int numFramebuffers = 0;

		void bindTexture(alias member)(SamplerObject!(TextureType.TEXTURE2D)* texture)
		{
			int loc = program.uniformLocation(member);
			if(loc >= 0)
			{
				

				texture.setActive(loc);
				program.setUniformInt(loc,loc);
				numFramebuffers++;
			}

		}

		static foreach(member; __traits(allMembers,Inputs))
		{
			{
				SamplerObject!(TextureType.TEXTURE2D)* texture = &(__traits(getMember,inputs,member).texture);
				bindTexture!(member)(texture);
				
			}
		}
		static foreach(member; __traits(allMembers,Outputs))
		{
			{
				SamplerObject!(TextureType.TEXTURE2D)* texture = &(__traits(getMember,outputs,member).texture);
				bindTexture!(member)(texture);
			}
		}
		
	}

	void startPass()
	{
		import realm.engine.graphics.graphicssubsystem;
		setViewport(0,0,framebuffer.width,framebuffer.height);
		framebuffer.bind(FrameBufferTarget.FRAMEBUFFER);
		GraphicsSubsystem.clearScreen();
		int numFramebuffers = 0;
		

	}

	void endPass()
	{
		
	}

	void bindOutputs()
	{
		static foreach(member; __traits(allMembers,Outputs))
		{

		}
	}





	
}
