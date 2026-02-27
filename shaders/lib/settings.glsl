const float REFLECTIONS_DATA_SIZE = 16.0;

const int shadowMapResolution = 1024; // [512 1024 2048 4096]

#define ADD_REFLECTION_MODE 2 // [0 1 2]

#define ENABLE_PBR // requires ADD_REFLECTION_MODE to NOT be vertex

#define ROUND_NORMALS

#define MIRROR_BLOCK 20 // [-1 20 21 22]

#define REFLECTION_PIORITY 8 // [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16]

#define SHARP_REPROJECTION

// #define REFLECTION_32F_PRECISION
#ifdef REFLECTION_32F_PRECISION
#endif

// #define HIDE_GUI_TO_PAUSE

#define ALL_REFLECTIONS_SCALE 1 // [1 2 3 4]
#ifdef ALL_REFLECTIONS_SCALE
#endif