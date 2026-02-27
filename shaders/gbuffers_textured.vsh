#version 430 compatibility

out vec2 lmcoord;
out vec2 texcoord;
out vec4 glcolor;

out float isCurrentReflection;
out float isReflective;

out float blockIdFloat;

in vec2 mc_Entity;

#include "/lib/settings.glsl"

#ifdef REFLECTION_32F_PRECISION
layout (rgba32f) uniform image2D allReflectionsDataImage;
layout (rgba32f) uniform image2D reflectionDataImage;
#else
layout (rgba16f) uniform image2D allReflectionsDataImage;
layout (rgba16f) uniform image2D reflectionDataImage;
#endif

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;

uniform float randUvOffset;

float rand3(vec3 co) {
    return fract(sin(dot(co, vec3(12.9898, 78.233, 19.943))) * 43758.5453);
}

float rand4(vec4 co) {
    return fract(sin(dot(co, vec4(12.9898, 78.233, 19.943, 8.814))) * 43758.5453);
}

vec2 generateReflectionsDataUv(vec4 id) {
	return vec2(rand4(id + randUvOffset), rand4(id + 3.0 + randUvOffset));
}

ivec2 generateReflectionsDataUvTexel(vec4 id) {
	return ivec2(generateReflectionsDataUv(id) * REFLECTIONS_DATA_SIZE);
}

#if ADD_REFLECTION_MODE >= 1
out vec4 myReflectData;
#endif
#if ADD_REFLECTION_MODE == 1
out vec2 reflectDataUv;
#endif

#ifdef HIDE_GUI_TO_PAUSE
uniform bool hideGUI;
#endif

void main() {
	gl_Position = ftransform();

	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	glcolor = gl_Color;

	isCurrentReflection = 0.0;
	isReflective = 0.0;
	#if ADD_REFLECTION_MODE >= 1
	myReflectData = vec4(-2.0);
	#endif
	#if ADD_REFLECTION_MODE == 1
	reflectDataUv = vec2(0.0);
	#endif

	blockIdFloat = mc_Entity.x;
	#ifdef ENABLE_PBR
	if (true) {
	#else
	int blockId = int(mc_Entity.x + 0.25);
	if (blockId == MIRROR_BLOCK) {
	#endif
		isReflective = 1.0;

		vec3 viewPos = (gbufferProjectionInverse * gl_Position).xyz;
		vec3 eyePlayerPos = mat3(gbufferModelViewInverse) * viewPos;
		vec3 normal = mat3(gbufferModelViewInverse) * (gl_NormalMatrix * gl_Normal);
		float dist = dot(eyePlayerPos, normal);
		#if ADD_REFLECTION_MODE == 1
		reflectDataUv = generateReflectionsDataUv(vec4(normal, dist));
		#endif
		#if ADD_REFLECTION_MODE >= 1
		myReflectData = vec4(normal, dist);
		#else
		imageStore(allReflectionsDataImage, generateReflectionsDataUvTexel(vec4(normal, dist)), vec4(normal + 2.0, dist));
		#endif

		vec4 currentReflectionData = imageLoad(reflectionDataImage, ivec2(0, 0));
		if (dot(currentReflectionData.xyz, normal) > 0.99 && abs(currentReflectionData.w - dist) < 0.1) {
			#ifdef HIDE_GUI_TO_PAUSE
			if (!hideGUI) {
			#endif
			isCurrentReflection = 1.0;
			#ifdef HIDE_GUI_TO_PAUSE
			}
			#endif
		}
	}
}