import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  const movieId = 496243; // Parasite
  const token = 'eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI4OGZlMjZkZGQ3ODFiNGUwZmQ0MGE4MThiZjAzYzQ1NSIsIm5iZiI6MTc3OTE1NTgzOS4zNjMwMDAyLCJzdWIiOiI2YTBiYzM3ZjgyMjFhM2VkM2Y0NjZkYzAiLCJzY29wZXMiOlsiYXBpX3JlYWQiXSwidmVyc2lvbiI6MX0.v3Us_FntbthPkZxWT10tya4_Lfmb_bg2-QwWc17TzwE';

  final uri = Uri.parse('https://api.themoviedb.org/3/movie/$movieId?language=id-ID&append_to_response=credits,videos&include_image_language=id,en,null&include_video_language=id,en,null');
  
  final res = await http.get(uri, headers: {
    'Authorization': 'Bearer $token',
    'accept': 'application/json',
  });

  print(res.body);
}
