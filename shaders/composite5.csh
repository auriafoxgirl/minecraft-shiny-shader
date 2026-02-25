#version 430 compatibility

layout (local_size_x = 1, local_size_y = 1, local_size_z = 1) in;
const ivec3 workGroups = ivec3(1, 1, 1);

layout (rgba16f) uniform image2D allReflectionsDataImage;
layout (rgba16f) uniform image2D reflectionDataImage;

uniform int currentReflectionPos;

#include "/lib/settings.glsl"

const int REFLECTIONS_DATA_SIZE_INT = int(REFLECTIONS_DATA_SIZE);
const float REFLECTIONS_DATA_SIZE_SQUARE = REFLECTIONS_DATA_SIZE * REFLECTIONS_DATA_SIZE;

ivec2 posToUv(int p) {
	p = int(mod(float(p), REFLECTIONS_DATA_SIZE_SQUARE));
	int y = p / REFLECTIONS_DATA_SIZE_INT;
	int x = p - y * REFLECTIONS_DATA_SIZE_INT;
	return ivec2(x, y);
}

void main() {
	ivec2 uv = posToUv(currentReflectionPos);
	vec4 color = imageLoad(allReflectionsDataImage, uv);
	if (color.r < 0.5) {
		imageStore(reflectionDataImage, ivec2(0, 0), vec4(0.0, 1.0, 0.0, 1.0));
		return;
	}
	color.xyz -= 2.0;
	#ifdef ROUND_NORMALS
	color.xyz = floor(color.xyz * 100.0 + 0.25) * 0.01;
	#endif
	imageStore(reflectionDataImage, ivec2(0, 0), vec4(color.xyz, color.w));
}