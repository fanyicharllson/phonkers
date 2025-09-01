// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/material.dart';
// import 'package:phonkers/data/model/phonk.dart';
// import 'package:phonkers/data/service/audio_player_service.dart';

// class MiniPlayer extends StatelessWidget {
//   const MiniPlayer({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder<Phonk?>(
//       stream: AudioPlayerService.currentPhonkStream,
//       builder: (context, snapshot) {
//         final currentPhonk = snapshot.data;

//         if (currentPhonk == null) {
//           return const SizedBox.shrink();
//         }

//         return Container(
//           height: 70,
//           margin: const EdgeInsets.only(bottom: 80), // Above bottom nav
//           padding: const EdgeInsets.symmetric(horizontal: 20),
//           child: Container(
//             decoration: BoxDecoration(
//               gradient: const LinearGradient(
//                 colors: [Color(0xFF1A0B2E), Color(0xFF2D1B3D)],
//               ),
//               borderRadius: BorderRadius.circular(16),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withValues(alpha: 0.3),
//                   blurRadius: 10,
//                   offset: const Offset(0, -2),
//                 ),
//               ],
//             ),
//             child: Row(
//               children: [
//                 // Album art
//                 Container(
//                   width: 50,
//                   height: 50,
//                   margin: const EdgeInsets.all(10),
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: ClipRRect(
//                     borderRadius: BorderRadius.circular(8),
//                     child: CachedNetworkImage(
//                       imageUrl: currentPhonk.albumArt ?? '',
//                       fit: BoxFit.cover,
//                       placeholder: (context, url) => Container(
//                         color: Colors.purple[700],
//                         child: const Icon(
//                           Icons.music_note,
//                           color: Colors.white,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),

//                 // Song info
//                 Expanded(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         currentPhonk.title,
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 14,
//                           fontWeight: FontWeight.w600,
//                         ),
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                       Text(
//                         currentPhonk.artist,
//                         style: TextStyle(
//                           color: Colors.white.withValues(alpha: 0.7),
//                           fontSize: 12,
//                         ),
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ],
//                   ),
//                 ),

//                 // Play/Pause button
//                 StreamBuilder<bool>(
//                   stream: AudioPlayerService.isPlayingStream,
//                   builder: (context, isPlayingSnapshot) {
//                     final isPlaying = isPlayingSnapshot.data ?? false;

//                     return IconButton(
//                       onPressed: () async {
//                         if (isPlaying) {
//                           await AudioPlayerService.pause();
//                         } else {
//                           await AudioPlayerService.resume();
//                         }
//                       },
//                       icon: Icon(
//                         isPlaying ? Icons.pause : Icons.play_arrow,
//                         color: Colors.white,
//                         size: 24,
//                       ),
//                     );
//                   },
//                 ),

//                 // Close button
//                 IconButton(
//                   onPressed: () async {
//                     await AudioPlayerService.stop();
//                   },
//                   icon: Icon(
//                     Icons.close,
//                     color: Colors.white.withValues(alpha: 0.7),
//                     size: 20,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
