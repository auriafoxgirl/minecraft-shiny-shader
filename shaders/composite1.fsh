#version 430 compatibility

uniform sampler2D colortex0;

#include "/lib/shaders_properties.glsl"

#include "/lib/settings.glsl"

in vec2 texcoord;

uniform float viewWidth;
uniform float viewHeight;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor;

uniform float randUvOffset;

uniform sampler2D colortex2; // reflections add composite mode
#ifdef REFLECTION_32F_PRECISION
layout (rgba32f) uniform image2D allReflectionsDataImage;
#else
layout (rgba16f) uniform image2D allReflectionsDataImage;
#endif

float rand4(vec4 co){
    return fract(sin(dot(co, vec4(12.9898, 78.233, 19.943, 8.814))) * 43758.5453);
}

vec2 generateReflectionsDataUv(vec4 id) {
	return vec2(rand4(id + randUvOffset), rand4(id + vec4(3.0, 0.0, 0.0, 0.0) + randUvOffset));
}

ivec2 generateReflectionsDataUvTexel(vec4 id) {
	return ivec2(generateReflectionsDataUv(id) * REFLECTIONS_DATA_SIZE);
}

#if REFLECTION_PIORITY >= 2
const float REFLECTION_PIORITY_FLOAT = int(REFLECTION_PIORITY);
#endif

void main() {
	outColor = texture2D(colortex0, texcoord);
	#ifdef ADD_REFLECTION_MODE == 2

	vec3 data = texture2D(colortex2, texcoord).xyz;
	if (data.x <= 0.5) {
		return;
	}
	data.x -= 2.0;
	bool flipZ = false;
	if (data.y > 1.5) {
		flipZ = true;
		data.y -= 4.0;
	}
	vec3 normal = vec3(
		data.x,
		data.y,
		sqrt(max(1.0 - dot(data.xy, data.xy), 0.0))
	);
	if (flipZ) {
		normal.z = -normal.z;
	}
	normal = normalize(normal);
	vec4 id = vec4(normal, data.z);
	#if REFLECTION_PIORITY >= 2
	id.yz += floor(texcoord.xy * REFLECTION_PIORITY_FLOAT);
	#endif
	imageStore(
		allReflectionsDataImage,
		generateReflectionsDataUvTexel(id),
		vec4(normal + 2.0, data.z)
	);

	#endif
}