package core;

import kha.Shaders;
import kha.graphics4.BlendingFactor;
import kha.graphics4.FragmentShader;
import kha.graphics4.PipelineState;
import kha.graphics4.VertexData;
import kha.graphics4.VertexShader;
import kha.graphics4.VertexStructure;

class ImageShader {
    public var pipeline:PipelineState;

    public function new (vertShader:VertexShader, fragShader:FragmentShader) {
        final structure = new VertexStructure();
        structure.add('vertexPosition', VertexData.Float32_3X);
        structure.add('vertexUV', VertexData.Float32_2X);
        structure.add('vertexColor', VertexData.UInt8_4X_Normalized);
        pipeline = new PipelineState();
        pipeline.inputLayout = [structure];
        pipeline.vertexShader = vertShader;
        pipeline.fragmentShader = fragShader;
        pipeline.blendSource = BlendingFactor.BlendOne;
        pipeline.blendDestination = BlendingFactor.InverseSourceAlpha;
        pipeline.alphaBlendSource = BlendingFactor.BlendOne;
        pipeline.alphaBlendDestination = BlendingFactor.InverseSourceAlpha;
        pipeline.compile();
    }
}

function makeBasePipelineShader () {
    return new ImageShader(Shaders.painter_image_vert, Shaders.painter_image_frag);
}
