#version 430 compatibility

out vec2 lmcoord;
out vec2 texcoord;
out vec4 glcolor;

out float skipPixel;

uniform mat4 shadowProjectionInverse;
uniform mat4 shadowModelViewInverse;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform vec3 cameraPositionDiff;

uniform int renderStage;

#include "/lib/settings.glsl"

#ifdef REFLECTION_32F_PRECISION
layout (rgba32f) uniform image2D reflectionDataImage;
#else
layout (rgba16f) uniform image2D reflectionDataImage;
#endif

in vec2 mc_Entity;

void main() {
	vec4 reflectionData = imageLoad(reflectionDataImage, ivec2(0, 0));
	vec3 reflectionNormal = reflectionData.xyz;
	vec3 offset = reflectionNormal * reflectionData.w;

	vec3 shadowViewPos = (shadowProjectionInverse * ftransform()).xyz;
	vec3 feetPlayerPos = (shadowModelViewInverse * vec4(shadowViewPos, 1.0)).xyz;
	
	offset += gbufferModelViewInverse[3].xyz;
	offset += cameraPositionDiff;

	feetPlayerPos -= offset;
	skipPixel = clamp(-dot(feetPlayerPos, reflectionNormal), -10.0, 10.0);
	feetPlayerPos = reflect(feetPlayerPos, reflectionNormal);
	feetPlayerPos += offset;
	feetPlayerPos -= reflectionNormal * max(skipPixel, 0.0) * 0.99;

	vec3 viewPos = (gbufferModelView * vec4(feetPlayerPos, 1.0)).xyz;
	vec4 clipPos = gbufferProjection * vec4(viewPos, 1.0);
	gl_Position = clipPos;
	gl_Position.x = -gl_Position.x; // flip x to flip backface culling
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	glcolor = gl_Color;

	// if (int(mc_Entity.x + 0.25) == 5) {
		// glcolor.a = 0.0;
	// }
	vec3 normal = mat3(shadowModelViewInverse) * (gl_NormalMatrix * gl_Normal);
	if (dot(normal, reflectionNormal) > 0.95) {
		skipPixel += 0.2;
	} else if (renderStage == MC_RENDER_STAGE_ENTITIES) {
		skipPixel -= 0.5;
	}
}