shader_type canvas_item;

uniform vec4 team_color: source_color = vec4(0);
uniform vec4 contested_color: source_color = vec4(0);
uniform float percent_fill: hint_range(0.0, 1.0, 0.01) = .5;
//hacky, because the repeated texture means i don't know how to get objext width
//or i'm handling the Polygon2d wrong
uniform float conn_length = 512;

void vertex() 
{
	// Called for every vertex the material is visible on.
}

void fragment() 
{
	vec4 invert_team_color = vec4(1,1,1,1) - team_color;
	vec4 invert_contested_color = vec4(1,1,1,1) - contested_color;
	vec4 current_color = texture(TEXTURE, UV);
	float width = conn_length / float(textureSize(TEXTURE, 0).x);
	if(UV.x < (percent_fill * width))
	{
		COLOR = current_color - invert_team_color;
	}
	else
	{
		COLOR = current_color - invert_contested_color;
	}
	//if (current_color.r > 0.0 && current_color.g > 0.0 && current_color.b > 0.0)
	//{
		//COLOR = team_color;
	//}
}

void light() 
{
	// Called for every pixel for every light affecting the CanvasItem.
}
