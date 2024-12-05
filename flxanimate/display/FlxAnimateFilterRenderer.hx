package flxanimate.display;

import openfl.utils.ByteArray;
import flxanimate.filters.MaskShader;
import openfl.filters.ShaderFilter;
import flixel.FlxCamera;
import openfl.display.BlendMode;
import openfl.display3D.Context3DClearMask;
import openfl.display3D.Context3D;
import flixel.math.FlxPoint;
import lime.graphics.cairo.Cairo;
import openfl.display.DisplayObjectRenderer;
import openfl.filters.BlurFilter;
import openfl.display.Graphics;
import openfl.display.Shape;
import flixel.FlxG;
import flixel.graphics.tile.FlxGraphicsShader;
import openfl.display.OpenGLRenderer;
import openfl.geom.Rectangle;
import openfl.display.BitmapData;
import openfl.display.Shader;
import openfl.filters.BitmapFilter;
import openfl.geom.Matrix;
import openfl.geom.ColorTransform;
import openfl.geom.Point;

import openfl.display._internal.Context3DGraphics;
#if (js && html5)
import openfl.display.CanvasRenderer;
import openfl.display._internal.CanvasGraphics as GfxRenderer;
import lime._internal.graphics.ImageCanvasUtil;
#else
import openfl.display.CairoRenderer;
import openfl.display._internal.CairoGraphics as GfxRenderer;
#end


@:access(openfl.display.OpenGLRenderer)
@:access(openfl.filters.BitmapFilter)
@:access(openfl.geom.Rectangle)
@:access(openfl.display.Stage)
@:access(openfl.display.Graphics)
@:access(openfl.display.Shader)
@:access(openfl.display.BitmapData)
@:access(openfl.geom.ColorTransform)
@:access(openfl.display.DisplayObject)
@:access(openfl.display3D.Context3D)
@:access(openfl.display.CanvasRenderer)
@:access(openfl.display.CairoRenderer)
@:access(openfl.display3D.Context3D)
class FlxAnimateFilterRenderer
{
	var renderer:OpenGLRenderer;
	var context:Context3D;
	@:privateAccess
	var maskShader:flxanimate.filters.MaskShader;

	var maskFilter:ShaderFilter;

	public function new()
	{
		// context = new openfl.display3D.Context3D(null);
		renderer = new OpenGLRenderer(FlxG.game.stage.context3D);
		renderer.__worldTransform = new Matrix();
		renderer.__worldColorTransform = new ColorTransform();
		maskShader = new MaskShader();
		maskFilter = new ShaderFilter(maskShader);
	}


	public function applyFilter(bmp:BitmapData, target:BitmapData, target1:BitmapData, target2:BitmapData, filters:Array<flxanimate.filters.FlxAnimateFilter>, ?rect:Rectangle = null, ?mask:BitmapData, ?maskPos:FlxPoint)
	{
		var shape = new Shape();

		// if (mask != null)
		// {
		// 	maskShader.relativePos.value[0] = 0;
		// 	maskShader.relativePos.value[1] = 0;
		// 	maskShader.mainPalette.input = mask;
		// 	maskFilter.invalidate();
		// 	if (filters == null)
		// 		filters = [maskFilter];
		// 	else
		// 		filters.push(maskFilter);
		// }

    if (filters != null)
		{
      for (filter in filters)
      {
				var shadersPasses:Array<openfl.display.GraphicsShader> = [];
        for (i in 0...filter.__numShaderPasses)
        {
					shadersPasses.push(filter.initShaderGraphic(i, bmp));
        }

				shape.graphics.beginShaderFill(new Shader(shadersPasses));
				shape.graphics.drawQuads(getRectVector(bmp.rect));
				shape.graphics.overrideBlendMode(filter.__shaderBlendMode);

        filter.__renderDirty = false;
      }

			shape.graphics.endFill();

      if (mask != null)
          filters.pop();

			if (rect != null)
				bmp.__renderTransform.translate(Math.abs(rect.x), Math.abs(rect.y));
			target.draw(shape, bmp.__renderTransform);
			bmp.__renderTransform.identity();
    }
	}

	public function graphicstoBitmapData(gfx:Graphics, ?target:BitmapData = null, ?point:FlxPoint = null) // TODO!: Support for CPU based games (Cairo/Canvas only renderers)
	{
		if (gfx.__bounds == null) return null;

		// var cacheRTT = renderer.__context3D.__state.renderToTexture;
		// var cacheRTTDepthStencil = renderer.__context3D.__state.renderToTextureDepthStencil;
		// var cacheRTTAntiAlias = renderer.__context3D.__state.renderToTextureAntiAlias;
		// var cacheRTTSurfaceSelector = renderer.__context3D.__state.renderToTextureSurfaceSelector;

		var bounds = gfx.__owner.getBounds(null);


		var bmp = (target == null) ? new BitmapData(Math.ceil(bounds.width), Math.ceil(bounds.height), true, 0) : target;

		renderer.__worldTransform.translate(-bounds.x, -bounds.y);

		if (point != null)
		{
			renderer.__worldTransform.translate(point.x, point.y);
		}

		// GfxRenderer.render(gfx, cast renderer.__softwareRenderer);
		// var bmp = gfx.__bitmap;

		var context = renderer.__context3D;

		// renderer.__setRenderTarget(bmp);
		// context.setRenderToTexture(bmp.getTexture(context));

		// Context3DGraphics.render(gfx, renderer);

		renderer.__worldTransform.identity();

		var shape = new Shape();
		@:privateAccess
		shape.__graphics = gfx;
		var matrix = new Matrix();
		matrix.translate(-bounds.x, -bounds.y);
		if (point != null)
			matrix.translate(point.x, point.y);
		bmp.draw(shape, matrix);


		// var gl = renderer.__gl;
		// var renderBuffer = bmp.getTexture(context);

		// @:privateAccess
		// gl.readPixels(0, 0, Math.round(bmp.width), Math.round(bmp.height), renderBuffer.__format, gl.UNSIGNED_BYTE, bmp.image.data);


		// if (cacheRTT != null)
		// {
		// 	renderer.__context3D.setRenderToTexture(cacheRTT, cacheRTTDepthStencil, cacheRTTAntiAlias, cacheRTTSurfaceSelector);
		// }
		// else
		// {
		// 	renderer.__context3D.setRenderToBackBuffer();
		// }

		return bmp;
	}

	function bitmapShaderGraphic(bitmap:BitmapData, smooth:Bool = true):FlxGraphicsShader
	{
		final shader = new FlxGraphicsShader();
		shader.bitmap.input = bitmap;
		shader.bitmap.filter = smooth ? LINEAR : NEAREST;
		shader.alpha.value = [];
		for (i in #if (openfl >= "8.5.0") 0...4 #else 0...6 #end)
			shader.alpha.value.push(1.0);

		return shader;
	}

	function getRectVector(rect:Rectangle):openfl.Vector<Float>
	{
		var vector = new openfl.Vector<Float>();

		vector.push(rect.x);
		vector.push(rect.y);
		vector.push(rect.width);
		vector.push(rect.height);

		return vector;
	}

	function getMatrixVector(matrix:Matrix)
	{
		var vector = new openfl.Vector<Float>();

		vector.push(matrix.a);
		vector.push(matrix.b);
		vector.push(matrix.c);
		vector.push(matrix.d);
		vector.push(matrix.tx);
		vector.push(matrix.ty);

		return vector;
	}
}
