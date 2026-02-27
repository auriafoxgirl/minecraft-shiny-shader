#version 430 compatibility

// 16 * 1 = 16
layout (local_size_x = 16) in;
const ivec3 workGroups = ivec3(16, 1, 1);

#include "/lib/settings.glsl"

#ifdef REFLECTION_32F_PRECISION
layout (rgba32f) uniform image2D allReflectionsDataImage;
#else
layout (rgba16f) uniform image2D allReflectionsDataImage;
#endif

const int REFLECTIONS_DATA_SIZE_INT = int(REFLECTIONS_DATA_SIZE);
const float REFLECTIONS_DATA_SIZE_SQUARE = REFLECTIONS_DATA_SIZE * REFLECTIONS_DATA_SIZE;

ivec2 posToUv(int p) {
	p = int(mod(float(p), REFLECTIONS_DATA_SIZE_SQUARE));
	int y = p / REFLECTIONS_DATA_SIZE_INT;
	int x = p - y * REFLECTIONS_DATA_SIZE_INT;
	return ivec2(x, y);
}

void main() {
   int pos = int(gl_GlobalInvocationID.x);
	ivec2 myUv = posToUv(pos);
	vec4 color = imageLoad(allReflectionsDataImage, myUv);
	if (color.r > 0.5) {
		return;
	}
	for (int i = 1; i <= 4; i++) {
		color = imageLoad(allReflectionsDataImage, posToUv(pos + i * 16));
		if (color.r > 0.5) {
			imageStore(allReflectionsDataImage, myUv, color);
			break;
		}
	}
}