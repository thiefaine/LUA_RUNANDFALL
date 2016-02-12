//extern float distance;
extern vec2 ePos;

vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords ){
	vec4 pixel = Texel(texture, texture_coords ); // current pixel
	if(pow(screen_coords.x - ePos.x, 2) + pow(screen_coords.y - ePos.y, 2) >= 5000)
	{
		number average = (pixel.r+pixel.b+pixel.g)/3.0;
		pixel.r = average;
		pixel.g = average;
		pixel.b = average;
	}
	return pixel;
}
