module realm.engine.graphics.pipeline;
import realm.engine.logging;
import realm.engine.graphics.core;
struct GraphicsContext
{
    float[16] viewMatrix;
    float[16] projectionMatrix;


}

struct PipelineInitDesc
{
    GraphicsContext initialContext;
    float[4] clearColor;
    UpdateGraphicsContext updateContext;
}

alias InitPipelineFunc = PipelineInitDesc function();
alias UpdateGraphicsContext = GraphicsContext function(GraphicsContext);

private UpdateGraphicsContext updateContext;
private ShaderStorage!(GraphicsContext,BufferStorageMode.Immutable) graphicsContextBlock;
private GraphicsContext currentCtx;

void init(PipelineInitDesc desc)
{
    Logger.LogInfo("Init pipeline!");
    float[4] clearColor = desc.clearColor;
    setClearColor(clearColor);
    updateContext = desc.updateContext;
    currentCtx = desc.initialContext;
    initContextBlock();
    enableDebugging();
    endFrame();
}

void initContextBlock()
{
    graphicsContextBlock.create();
    graphicsContextBlock.bind();
    
    graphicsContextBlock.store(1);
    graphicsContextBlock.bindBase(0);
    graphicsContextBlock.unbind();

}

void updateContextBlock(GraphicsContext ctx)
{
    graphicsContextBlock.bind();
    graphicsContextBlock.bindBase(0);
    graphicsContextBlock[0] = (ctx);
    graphicsContextBlock.unbind();
    currentCtx = ctx;
}

void startFrame()
{
    GraphicsContext ctx = updateContext(currentCtx);
    updateContextBlock(ctx);

}

void endFrame()
{
    clear(FrameMask.COLOR);
}   




