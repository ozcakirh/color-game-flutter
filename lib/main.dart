//*** Gemini Başı */
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

enum GameStatus { playing, paused, finished }

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Boru Animasyon 36 Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const PipeAnimationScreen(),
    );
  }
}

class PipeAnimationScreen extends StatefulWidget {
  const PipeAnimationScreen({super.key});

  @override
  State<PipeAnimationScreen> createState() => _PipeAnimationScreenState();
}

class _PipeAnimationScreenState extends State<PipeAnimationScreen> {
  static const int cellCount = 36;
  static const Map<String, Color> colorMap = {
    'red': Color(0xFFFF0000),
    'green': Color(0xFF00FF00),
    'blue': Color(0xFF0000FF),
  };
  static const List<Color> randomColors = [
    Color(0xFFFF0000),
    Color(0xFF00FF00),
    Color(0xFF0000FF),
  ];

  late List<Color> cellColors;
  late Color currentColor;
  late int currentPosition;
  Timer? animationTimer;
  late List<Map<String, dynamic>> activeAnimations;
  late Map<String, DateTime> lastButtonPress;
  int userScore = 0;
  int computerScore = 0;
  GameStatus status =
      GameStatus.finished; // Başlangıçta oyun bitik/durmuş halde

  @override
  void initState() {
    super.initState();
    _resetGameState();
  }

  void _resetGameState() {
    cellColors = List.filled(cellCount, Colors.grey[800]!);
    _selectNewColor();
    currentPosition = -1;
    activeAnimations = [];
    lastButtonPress = {
      'red': DateTime(1970),
      'green': DateTime(1970),
      'blue': DateTime(1970),
    };
  }

  void _selectNewColor() {
    currentColor = randomColors[Random().nextInt(randomColors.length)];
  }

  // OYUNU BAŞLAT
  void _startGame() {
    if (status == GameStatus.playing) return;

    setState(() {
      status = GameStatus.playing;
    });

    animationTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (status != GameStatus.playing) {
        timer.cancel();
        return;
      }

      setState(() {
        currentPosition++;

        if (currentPosition >= cellCount) {
          computerScore++;
          _selectNewColor();
          currentPosition = 0;
          cellColors = List.filled(cellCount, Colors.grey[800]!);
          activeAnimations.clear();
          return;
        }

        List<Map<String, dynamic>> animationsToRemove = [];
        bool collisionOccurred = false;

        for (var userAnim in activeAnimations) {
          final userPos = userAnim['position'] as int;
          final userCol = userAnim['color'] as Color;

          if (currentPosition == userPos ||
              (currentPosition - 1 == userPos && currentPosition > 0)) {
            _areColorsEqual(currentColor, userCol)
                ? userScore++
                : computerScore++;
            collisionOccurred = true;
            cellColors[currentPosition] = Colors.grey[800]!;
            if (currentPosition > 0)
              cellColors[currentPosition - 1] = Colors.grey[800]!;
            userAnim['position'] = -1;
            animationsToRemove.add(userAnim);
          }
        }

        for (var anim in animationsToRemove) {
          activeAnimations.remove(anim);
        }

        if (collisionOccurred) {
          currentPosition = -1;
          _selectNewColor();
          return;
        }

        cellColors[currentPosition] = currentColor;
        if (currentPosition > 0) {
          bool isUserAnimThere = activeAnimations.any(
            (anim) => anim['position'] == currentPosition - 1,
          );
          if (!isUserAnimThere)
            cellColors[currentPosition - 1] = Colors.grey[800]!;
        }
      });
    });
  }

  // OYUNU DURDUR
  void _pauseGame() {
    setState(() {
      status = GameStatus.paused;
      animationTimer?.cancel();
    });
  }

  // OYUNU BİTİR / SIFIRLA
  void _stopGame() {
    setState(() {
      status = GameStatus.finished;
      animationTimer?.cancel();
      userScore = 0;
      computerScore = 0;
      _resetGameState();
    });
  }

  void _startButtonAnimation(Color color, String colorName) {
    if (status != GameStatus.playing) return; // Oyun çalışmıyorsa ateş etme

    final now = DateTime.now();
    final lastPress = lastButtonPress[colorName] ?? DateTime(1970);
    if (now.difference(lastPress).inMilliseconds < 800) return;

    lastButtonPress[colorName] = now;
    int buttonPosition = cellCount - 1;
    final animationData = {'color': color, 'position': buttonPosition};
    activeAnimations.add(animationData);

    Timer.periodic(const Duration(milliseconds: 150), (t) {
      if (status != GameStatus.playing || !mounted) {
        t.cancel();
        return;
      }

      setState(() {
        final position = animationData['position'] as int;
        final col = animationData['color'] as Color;

        if (position >= 0) {
          if (currentPosition == position ||
              (currentPosition == position - 1 && currentPosition != -1)) {
            _areColorsEqual(currentColor, col) ? userScore++ : computerScore++;
            cellColors[position] = Colors.grey[800]!;
            if (currentPosition != -1)
              cellColors[currentPosition] = Colors.grey[800]!;
            currentPosition = -1;
            _selectNewColor();
            animationData['position'] = -1;
            t.cancel();
            activeAnimations.remove(animationData);
            return;
          }

          cellColors[position] = col;
          if (position < cellCount - 1) {
            if (currentPosition != position + 1)
              cellColors[position + 1] = Colors.grey[800]!;
          }
          animationData['position'] = position - 1;
        } else {
          t.cancel();
          activeAnimations.remove(animationData);
        }
      });
    });
  }

  bool _areColorsEqual(Color color1, Color color2) =>
      color1.value == color2.value;

  @override
  void dispose() {
    animationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Kontrol ve Renk Butonları
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _actionButton(
                  "BAŞLA",
                  Colors.orange,
                  _startGame,
                  status != GameStatus.playing,
                ),
                const SizedBox(height: 10),
                _actionButton(
                  "DUR",
                  Colors.grey,
                  _pauseGame,
                  status == GameStatus.playing,
                ),
                const SizedBox(height: 10),
                _actionButton("BİTİR", Colors.red, _stopGame, true),
                const Divider(color: Colors.white24, height: 40),
                _colorBtn('red', 'Kırmızı'),
                const SizedBox(height: 10),
                _colorBtn('green', 'Yeşil'),
                const SizedBox(height: 10),
                _colorBtn('blue', 'Mavi'),
              ],
            ),
            // Boru
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white12),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  cellCount,
                  (index) => Container(
                    width: 45,
                    height: 16,
                    margin: const EdgeInsets.symmetric(vertical: 1),
                    decoration: BoxDecoration(
                      color: cellColors[index],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
            // Skor
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _scoreBox("PC", computerScore, Colors.blue),
                const SizedBox(height: 20),
                _scoreBox("SİZ", userScore, Colors.green),
                const SizedBox(height: 20),
                Text(
                  status == GameStatus.playing
                      ? "OYUN DEVAM EDİYOR"
                      : "BEKLİYOR...",
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(
    String label,
    Color color,
    VoidCallback onTap,
    bool enabled,
  ) {
    return ElevatedButton(
      onPressed: enabled ? onTap : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        minimumSize: const Size(100, 40),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _colorBtn(String key, String label) {
    return ElevatedButton(
      onPressed: status == GameStatus.playing
          ? () => _startButtonAnimation(colorMap[key]!, key)
          : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: colorMap[key],
        minimumSize: const Size(100, 45),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 11),
      ),
    );
  }

  Widget _scoreBox(String title, int val, Color col) {
    return Container(
      width: 80,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: col.withOpacity(0.1),
        border: Border.all(color: col),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
          Text(
            val.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
//** 36 LI bAŞI */
// import 'package:flutter/material.dart';
// import 'dart:async';
// import 'dart:math';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Boru Animasyon 36',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//         useMaterial3: true,
//       ),
//       home: const PipeAnimationScreen(),
//     );
//   }
// }

// class PipeAnimationScreen extends StatefulWidget {
//   const PipeAnimationScreen({super.key});

//   @override
//   State<PipeAnimationScreen> createState() => _PipeAnimationScreenState();
// }

// class _PipeAnimationScreenState extends State<PipeAnimationScreen> {
//   // HÜCRE SAYISI 36 OLARAK GÜNCELLENDİ
//   static const int cellCount = 36;

//   static const Map<String, Color> colorMap = {
//     'red': Color(0xFFFF0000),
//     'green': Color(0xFF00FF00),
//     'blue': Color(0xFF0000FF),
//   };
//   static const List<Color> randomColors = [
//     Color(0xFFFF0000),
//     Color(0xFF00FF00),
//     Color(0xFF0000FF),
//   ];

//   late List<Color> cellColors;
//   late Color currentColor;
//   late int currentPosition;
//   late Timer animationTimer;
//   late List<Map<String, dynamic>> activeAnimations;
//   late Map<String, DateTime> lastButtonPress;
//   late int userScore;
//   late int computerScore;
//   static const int cooldownSeconds =
//       1; // 36 hücrede oyun daha uzun sürdüğü için cooldown'ı 1 saniyeye düşürdüm

//   @override
//   void initState() {
//     super.initState();
//     _initializeAnimation();
//   }

//   void _initializeAnimation() {
//     cellColors = List.filled(cellCount, Colors.grey[800]!);
//     _selectNewColor();
//     currentPosition = -1;
//     activeAnimations = [];
//     lastButtonPress = {
//       'red': DateTime(1970),
//       'green': DateTime(1970),
//       'blue': DateTime(1970),
//     };
//     userScore = 0;
//     computerScore = 0;
//     _startAnimation();
//   }

//   void _selectNewColor() {
//     currentColor = randomColors[Random().nextInt(randomColors.length)];
//   }

//   void _startAnimation() {
//     animationTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
//       // Hız biraz artırıldı
//       setState(() {
//         currentPosition++;

//         if (currentPosition >= cellCount) {
//           computerScore++;
//           _selectNewColor();
//           currentPosition = 0;
//           cellColors = List.filled(cellCount, Colors.grey[800]!);
//           activeAnimations.clear();
//           return;
//         }

//         List<Map<String, dynamic>> animationsToRemove = [];
//         bool collisionOccurred = false;

//         for (var userAnim in activeAnimations) {
//           final userPos = userAnim['position'] as int;
//           final userCol = userAnim['color'] as Color;

//           if (currentPosition == userPos ||
//               (currentPosition - 1 == userPos && currentPosition > 0)) {
//             if (_areColorsEqual(currentColor, userCol)) {
//               userScore++;
//             } else {
//               computerScore++;
//             }

//             collisionOccurred = true;
//             cellColors[currentPosition] = Colors.grey[800]!;
//             if (currentPosition > 0) {
//               cellColors[currentPosition - 1] = Colors.grey[800]!;
//             }

//             userAnim['position'] = -1;
//             animationsToRemove.add(userAnim);
//           }
//         }

//         for (var anim in animationsToRemove) {
//           activeAnimations.remove(anim);
//         }

//         if (collisionOccurred) {
//           currentPosition = -1;
//           _selectNewColor();
//           return;
//         }

//         cellColors[currentPosition] = currentColor;

//         if (currentPosition > 0) {
//           bool isUserAnimThere = activeAnimations.any(
//             (anim) => anim['position'] == currentPosition - 1,
//           );
//           if (!isUserAnimThere) {
//             cellColors[currentPosition - 1] = Colors.grey[800]!;
//           }
//         }
//       });
//     });
//   }

//   void _startButtonAnimation(Color color, String colorName) {
//     final now = DateTime.now();
//     final lastPress = lastButtonPress[colorName] ?? DateTime(1970);

//     if (now.difference(lastPress).inSeconds < cooldownSeconds) return;

//     lastButtonPress[colorName] = now;
//     int buttonPosition = cellCount - 1;

//     final animationData = {'color': color, 'position': buttonPosition};
//     activeAnimations.add(animationData);

//     Timer.periodic(const Duration(milliseconds: 150), (t) {
//       if (!mounted) {
//         t.cancel();
//         return;
//       }

//       setState(() {
//         final position = animationData['position'] as int;
//         final col = animationData['color'] as Color;

//         if (position >= 0) {
//           if (currentPosition == position ||
//               (currentPosition == position - 1 && currentPosition != -1)) {
//             if (_areColorsEqual(currentColor, col)) {
//               userScore++;
//             } else {
//               computerScore++;
//             }

//             cellColors[position] = Colors.grey[800]!;
//             if (currentPosition != -1)
//               cellColors[currentPosition] = Colors.grey[800]!;

//             currentPosition = -1;
//             _selectNewColor();

//             animationData['position'] = -1;
//             t.cancel();
//             activeAnimations.remove(animationData);
//             return;
//           }

//           cellColors[position] = col;
//           if (position < cellCount - 1) {
//             bool isSystemColorThere = currentPosition == position + 1;
//             if (!isSystemColorThere) {
//               cellColors[position + 1] = Colors.grey[800]!;
//             }
//           }
//           animationData['position'] = position - 1;
//         } else {
//           t.cancel();
//           activeAnimations.remove(animationData);
//         }
//       });
//     });
//   }

//   bool _areColorsEqual(Color color1, Color color2) {
//     return color1.value == color2.value;
//   }

//   void _resetScores() {
//     setState(() {
//       userScore = 0;
//       computerScore = 0;
//       currentPosition = -1;
//       cellColors = List.filled(cellCount, Colors.grey[800]!);
//       activeAnimations.clear();
//       _selectNewColor();
//     });
//   }

//   bool _isButtonCooldown(String colorName) {
//     final now = DateTime.now();
//     final lastPress = lastButtonPress[colorName] ?? DateTime(1970);
//     return now.difference(lastPress).inSeconds < cooldownSeconds;
//   }

//   @override
//   void dispose() {
//     animationTimer.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           // Butonlar
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 20),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 _buildColorButton('red', 'Kırmızı', Colors.white),
//                 const SizedBox(height: 15),
//                 _buildColorButton('green', 'Yeşil', Colors.black),
//                 const SizedBox(height: 15),
//                 _buildColorButton('blue', 'Mavi', Colors.white),
//               ],
//             ),
//           ),
//           // Boru Tasarımı
//           SingleChildScrollView(
//             // Ekran küçükse kaydırılabilir olması için
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Container(
//                   decoration: BoxDecoration(
//                     border: Border.all(color: Colors.white24, width: 2),
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   padding: const EdgeInsets.all(4),
//                   child: Column(
//                     children: List.generate(cellCount, (index) {
//                       return Container(
//                         width: 50,
//                         height:
//                             18, // 36 hücrenin sığması için yükseklik düşürüldü
//                         margin: const EdgeInsets.symmetric(vertical: 1),
//                         decoration: BoxDecoration(
//                           color: cellColors[index],
//                           borderRadius: BorderRadius.circular(3),
//                         ),
//                       );
//                     }),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           // Skor Alanı
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 20),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 const Text(
//                   'Skor',
//                   style: TextStyle(color: Colors.white, fontSize: 20),
//                 ),
//                 const SizedBox(height: 20),
//                 _scoreCard('PC', computerScore, Colors.blue),
//                 const SizedBox(height: 10),
//                 _scoreCard('SİZ', userScore, Colors.green),
//                 const SizedBox(height: 20),
//                 ElevatedButton(
//                   onPressed: _resetScores,
//                   child: const Text('Sıfırla'),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildColorButton(String key, String label, Color textColor) {
//     bool isCooldown = _isButtonCooldown(key);
//     return ElevatedButton(
//       onPressed: isCooldown
//           ? null
//           : () => _startButtonAnimation(colorMap[key]!, key),
//       style: ElevatedButton.styleFrom(
//         backgroundColor: colorMap[key],
//         disabledBackgroundColor: colorMap[key]!.withOpacity(0.2),
//         minimumSize: const Size(100, 45),
//       ),
//       child: Text(
//         label,
//         style: TextStyle(
//           color: isCooldown ? Colors.white24 : textColor,
//           fontSize: 12,
//         ),
//       ),
//     );
//   }

//   Widget _scoreCard(String label, int score, Color color) {
//     return Container(
//       width: 90,
//       padding: const EdgeInsets.all(8),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: color.withOpacity(0.5)),
//       ),
//       child: Column(
//         children: [
//           Text(
//             label,
//             style: const TextStyle(color: Colors.white70, fontSize: 10),
//           ),
//           Text(
//             score.toString(),
//             style: const TextStyle(
//               color: Colors.white,
//               fontSize: 22,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
// 24 lü başı
// import 'package:flutter/material.dart';
// import 'dart:async';
// import 'dart:math';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Boru Animasyon',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//         useMaterial3: true,
//       ),
//       home: const PipeAnimationScreen(),
//     );
//   }
// }

// class PipeAnimationScreen extends StatefulWidget {
//   const PipeAnimationScreen({super.key});

//   @override
//   State<PipeAnimationScreen> createState() => _PipeAnimationScreenState();
// }

// class _PipeAnimationScreenState extends State<PipeAnimationScreen> {
//   static const int cellCount = 24;
//   static const Map<String, Color> colorMap = {
//     'red': Color(0xFFFF0000),
//     'green': Color(0xFF00FF00),
//     'blue': Color(0xFF0000FF),
//   };
//   static const List<Color> randomColors = [
//     Color(0xFFFF0000),
//     Color(0xFF00FF00),
//     Color(0xFF0000FF),
//   ];

//   late List<Color> cellColors;
//   late Color currentColor;
//   late int currentPosition;
//   late Timer animationTimer;
//   late List<Map<String, dynamic>> activeAnimations;
//   late Map<String, DateTime> lastButtonPress;
//   late int userScore;
//   late int computerScore;
//   static const int cooldownSeconds = 2;

//   @override
//   void initState() {
//     super.initState();
//     _initializeAnimation();
//   }

//   void _initializeAnimation() {
//     cellColors = List.filled(cellCount, Colors.grey[800]!);
//     _selectNewColor();
//     currentPosition = -1;
//     activeAnimations = [];
//     lastButtonPress = {
//       'red': DateTime(1970),
//       'green': DateTime(1970),
//       'blue': DateTime(1970),
//     };
//     userScore = 0;
//     computerScore = 0;
//     _startAnimation();
//   }

//   void _selectNewColor() {
//     currentColor = randomColors[Random().nextInt(randomColors.length)];
//   }

//   void _startAnimation() {
//     animationTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
//       setState(() {
//         currentPosition++;

//         if (currentPosition >= cellCount) {
//           computerScore++;
//           _selectNewColor();
//           currentPosition = 0;
//           cellColors = List.filled(cellCount, Colors.grey[800]!);
//           activeAnimations.clear();
//           return;
//         }

//         List<Map<String, dynamic>> animationsToRemove = [];
//         bool collisionOccurred = false;

//         for (var userAnim in activeAnimations) {
//           final userPos = userAnim['position'] as int;
//           final userCol = userAnim['color'] as Color;

//           // Çarpışma: Aynı hücrede veya kafa kafaya geçişte
//           if (currentPosition == userPos ||
//               (currentPosition - 1 == userPos && currentPosition > 0)) {
//             if (_areColorsEqual(currentColor, userCol)) {
//               userScore++;
//             } else {
//               computerScore++;
//             }

//             collisionOccurred = true;

//             // Çarpışma bölgesini temizle
//             cellColors[currentPosition] = Colors.grey[800]!;
//             if (currentPosition > 0) {
//               cellColors[currentPosition - 1] = Colors.grey[800]!;
//             }

//             userAnim['position'] = -1;
//             animationsToRemove.add(userAnim);
//           }
//         }

//         // Çarpışan kullanıcı animasyonlarını listeden çıkar
//         for (var anim in animationsToRemove) {
//           activeAnimations.remove(anim);
//         }

//         // KRİTİK NOKTA: Çarpışma varsa yukarıdaki rengi sıfırla ve döngüden çık
//         if (collisionOccurred) {
//           currentPosition = -1; // Bir sonraki tikte 0 olacak
//           _selectNewColor();
//           return;
//         }

//         // Çarpışma yoksa mevcut hücreyi boya
//         cellColors[currentPosition] = currentColor;

//         // Bir önceki hücreyi temizle (aktif kullanıcı animasyonu yoksa)
//         if (currentPosition > 0) {
//           bool isUserAnimThere = activeAnimations.any(
//             (anim) => anim['position'] == currentPosition - 1,
//           );
//           if (!isUserAnimThere) {
//             cellColors[currentPosition - 1] = Colors.grey[800]!;
//           }
//         }
//       });
//     });
//   }

//   void _startButtonAnimation(Color color, String colorName) {
//     final now = DateTime.now();
//     final lastPress = lastButtonPress[colorName] ?? DateTime(1970);

//     if (now.difference(lastPress).inSeconds < cooldownSeconds) return;

//     lastButtonPress[colorName] = now;
//     int buttonPosition = cellCount - 1;

//     final animationData = {'color': color, 'position': buttonPosition};
//     activeAnimations.add(animationData);

//     Timer.periodic(const Duration(milliseconds: 200), (t) {
//       if (!mounted) {
//         t.cancel();
//         return;
//       }

//       setState(() {
//         final position = animationData['position'] as int;
//         final col = animationData['color'] as Color;

//         if (position >= 0) {
//           // Çarpışma kontrolü
//           if (currentPosition == position ||
//               (currentPosition == position - 1 && currentPosition != -1)) {
//             if (_areColorsEqual(currentColor, col)) {
//               userScore++;
//             } else {
//               computerScore++;
//             }

//             cellColors[position] = Colors.grey[800]!;
//             if (currentPosition != -1)
//               cellColors[currentPosition] = Colors.grey[800]!;

//             currentPosition = -1; // Yukarıdan geleni sıfırla
//             _selectNewColor();

//             animationData['position'] = -1;
//             t.cancel();
//             activeAnimations.remove(animationData);
//             return;
//           }

//           cellColors[position] = col;
//           if (position < cellCount - 1) {
//             bool isSystemColorThere = currentPosition == position + 1;
//             if (!isSystemColorThere) {
//               cellColors[position + 1] = Colors.grey[800]!;
//             }
//           }
//           animationData['position'] = position - 1;
//         } else {
//           t.cancel();
//           activeAnimations.remove(animationData);
//         }
//       });
//     });
//   }

//   bool _areColorsEqual(Color color1, Color color2) {
//     return color1.value == color2.value;
//   }

//   void _resetScores() {
//     setState(() {
//       userScore = 0;
//       computerScore = 0;
//       currentPosition = -1;
//       cellColors = List.filled(cellCount, Colors.grey[800]!);
//       activeAnimations.clear();
//       _selectNewColor();
//     });
//   }

//   bool _isButtonCooldown(String colorName) {
//     final now = DateTime.now();
//     final lastPress = lastButtonPress[colorName] ?? DateTime(1970);
//     return now.difference(lastPress).inSeconds < cooldownSeconds;
//   }

//   @override
//   void dispose() {
//     animationTimer.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           // Butonlar
//           Padding(
//             padding: const EdgeInsets.only(right: 40),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 _buildColorButton('red', 'Kırmızı', Colors.white),
//                 const SizedBox(height: 20),
//                 _buildColorButton('green', 'Yeşil', Colors.black),
//                 const SizedBox(height: 20),
//                 _buildColorButton('blue', 'Mavi', Colors.white),
//               ],
//             ),
//           ),
//           // Boru
//           Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Container(
//                 decoration: BoxDecoration(
//                   border: Border.all(color: Colors.white30, width: 2),
//                   borderRadius: BorderRadius.circular(15),
//                 ),
//                 padding: const EdgeInsets.all(8),
//                 child: Column(
//                   children: List.generate(cellCount, (index) {
//                     return Container(
//                       width: 60,
//                       height: 25,
//                       margin: const EdgeInsets.symmetric(vertical: 1),
//                       decoration: BoxDecoration(
//                         color: cellColors[index],
//                         borderRadius: BorderRadius.circular(4),
//                         boxShadow: cellColors[index] != Colors.grey[800]
//                             ? [
//                                 BoxShadow(
//                                   color: cellColors[index].withOpacity(0.5),
//                                   blurRadius: 8,
//                                 ),
//                               ]
//                             : [],
//                       ),
//                     );
//                   }),
//                 ),
//               ),
//             ],
//           ),
//           // Skor
//           Padding(
//             padding: const EdgeInsets.only(left: 40),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 const Text(
//                   'Skor',
//                   style: TextStyle(color: Colors.white, fontSize: 24),
//                 ),
//                 const SizedBox(height: 20),
//                 _scoreCard('Bilgisayar', computerScore, Colors.blue),
//                 const SizedBox(height: 10),
//                 _scoreCard('Siz', userScore, Colors.green),
//                 const SizedBox(height: 30),
//                 ElevatedButton(
//                   onPressed: _resetScores,
//                   child: const Text('Sıfırla'),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildColorButton(String key, String label, Color textColor) {
//     bool isCooldown = _isButtonCooldown(key);
//     return ElevatedButton(
//       onPressed: isCooldown
//           ? null
//           : () => _startButtonAnimation(colorMap[key]!, key),
//       style: ElevatedButton.styleFrom(
//         backgroundColor: colorMap[key],
//         disabledBackgroundColor: colorMap[key]!.withOpacity(0.3),
//         minimumSize: const Size(120, 50),
//       ),
//       child: Text(
//         label,
//         style: TextStyle(color: isCooldown ? Colors.white30 : textColor),
//       ),
//     );
//   }

//   Widget _scoreCard(String label, int score, Color color) {
//     return Container(
//       width: 120,
//       padding: const EdgeInsets.all(10),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.2),
//         borderRadius: BorderRadius.circular(10),
//         border: Border.all(color: color),
//       ),
//       child: Column(
//         children: [
//           Text(
//             label,
//             style: const TextStyle(color: Colors.white70, fontSize: 12),
//           ),
//           Text(
//             score.toString(),
//             style: const TextStyle(
//               color: Colors.white,
//               fontSize: 28,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//**** Gemini Sonu */

// import 'package:flutter/material.dart';
// import 'dart:async';
// import 'dart:math';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Boru Animasyon',
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//         useMaterial3: true,
//       ),
//       home: const PipeAnimationScreen(),
//     );
//   }
// }

// class PipeAnimationScreen extends StatefulWidget {
//   const PipeAnimationScreen({super.key});

//   @override
//   State<PipeAnimationScreen> createState() => _PipeAnimationScreenState();
// }

// class _PipeAnimationScreenState extends State<PipeAnimationScreen> {
//   static const int cellCount = 24;
//   static const Map<String, Color> colorMap = {
//     'red': Color(0xFFFF0000),
//     'green': Color(0xFF00FF00),
//     'blue': Color(0xFF0000FF),
//   };
//   static const List<Color> randomColors = [
//     Color(0xFFFF0000), // Kırmızı
//     Color(0xFF00FF00), // Yeşil
//     Color(0xFF0000FF), // Mavi
//   ];

//   late List<Color> cellColors;
//   late Color currentColor;
//   late int currentPosition;
//   late Timer animationTimer;
//   late List<Map<String, dynamic>> activeAnimations;
//   late Map<String, DateTime> lastButtonPress;
//   late int userScore;
//   late int computerScore;
//   static const int cooldownSeconds = 2;

//   @override
//   void initState() {
//     super.initState();
//     _initializeAnimation();
//   }

//   void _initializeAnimation() {
//     cellColors = List.filled(cellCount, Colors.grey[800]!);
//     _selectNewColor();
//     currentPosition = -1;
//     activeAnimations = [];
//     lastButtonPress = {
//       'red': DateTime(1970),
//       'green': DateTime(1970),
//       'blue': DateTime(1970),
//     };
//     userScore = 0;
//     computerScore = 0;
//     _startAnimation();
//   }

//   void _selectNewColor() {
//     currentColor = randomColors[Random().nextInt(randomColors.length)];
//   }

//   void _startAnimation() {
//     animationTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
//       setState(() {
//         currentPosition++;

//         if (currentPosition >= cellCount) {
//           // Tüm hücreler geçildi, bilgisayara +1 puan
//           computerScore++;
//           _selectNewColor();
//           currentPosition = 0;
//           // Hücreleri sıfırla
//           cellColors = List.filled(cellCount, Colors.grey[800]!);
//           activeAnimations.clear();
//           return;
//         }

//         // Çarpışma kontrolü: rastgele renk ile aktif animasyonları kontrol et
//         List<Map<String, dynamic>> animationsToRemove = [];
//         bool currentPositionHasCollision = false;

//         for (var userAnim in activeAnimations) {
//           final userPos = userAnim['position'] as int;
//           final userCol = userAnim['color'] as Color;
//           bool collided = false;

//           // Aynı pozisyonda çarpışma
//           if (currentPosition == userPos) {
//             if (_areColorsEqual(currentColor, userCol)) {
//               userScore++;
//             } else {
//               computerScore++;
//             }
//             collided = true;
//             currentPositionHasCollision = true;
//             cellColors[currentPosition] = Colors.grey[800]!;
//           }
//           // Geçiş sırasında çarpışma (rastgele renk bir önceki pozisyonda user rengine temas ediyorsa)
//           else if (currentPosition - 1 == userPos && currentPosition > 0) {
//             if (_areColorsEqual(currentColor, userCol)) {
//               userScore++;
//               cellColors[currentPosition - 1] = Colors.grey[800]!;
//             } else {
//               computerScore++;
//               cellColors[currentPosition - 1] = Colors.grey[800]!;
//             }
//             collided = true;
//           }

//           if (collided) {
//             userAnim['position'] =
//                 -1; // Position'ı -1 yaparak timer'ın kendini temizlemesini sağla
//             animationsToRemove.add(userAnim);
//           }
//         }

//         // Çarpışan animasyonları kaldır
//         for (var anim in animationsToRemove) {
//           activeAnimations.remove(anim);
//         }

//         // Mevcut hücreyi yak (çarpışmadıysa)
//         if (!currentPositionHasCollision) {
//           cellColors[currentPosition] = currentColor;
//         }

//         // Bir önceki hücreyi söndür
//         if (currentPosition > 0) {
//           bool shouldClear = true;
//           // Eğer bir önceki hücrede aktif animasyon varsa temizleme
//           for (var userAnim in activeAnimations) {
//             if ((userAnim['position'] as int) == currentPosition - 1) {
//               shouldClear = false;
//               break;
//             }
//           }
//           if (shouldClear) {
//             cellColors[currentPosition - 1] = Colors.grey[800]!;
//           }
//         }
//       });
//     });
//   }

//   void _startButtonAnimation(Color color, String colorName) {
//     final now = DateTime.now();
//     final lastPress = lastButtonPress[colorName] ?? DateTime(1970);

//     if (now.difference(lastPress).inSeconds < cooldownSeconds) {
//       return; // Cooldown süresi geçmedi, ignorelamam
//     }

//     lastButtonPress[colorName] = now;

//     int buttonPosition = cellCount - 1; // Alttan başla (23)

//     final animationData = {'color': color, 'position': buttonPosition};
//     activeAnimations.add(animationData);

//     final timer = Timer.periodic(const Duration(milliseconds: 200), (t) {
//       setState(() {
//         final position = animationData['position'] as int;
//         final col = animationData['color'] as Color;

//         if (position >= 0) {
//           cellColors[position] = col;

//           // Çarpışma kontrolü: rastgele renk ile user renginin aynı position'da olup olmadığını kontrol et
//           if (currentPosition == position) {
//             if (_areColorsEqual(currentColor, col)) {
//               // Aynı renkle çarpıştı: user puan alır
//               userScore++;
//             } else {
//               // Farklı renkle çarpıştı: bilgisayar puan alır
//               computerScore++;
//             }
//             // Her iki ışını da söndür ve animasyonu bitir
//             cellColors[position] = Colors.grey[800]!;
//             animationData['position'] =
//                 -1; // Timer'ın kendini temizlemesini sağla
//             return;
//           }

//           if (position < cellCount - 1) {
//             cellColors[position + 1] = Colors.grey[800]!;
//           }

//           animationData['position'] = position - 1;
//         } else {
//           // Animasyon tamamlandı
//           t.cancel();
//           activeAnimations.remove(animationData);
//         }
//       });
//     });
//   }

//   bool _areColorsEqual(Color color1, Color color2) {
//     return color1.value == color2.value;
//   }

//   void _resetScores() {
//     setState(() {
//       userScore = 0;
//       computerScore = 0;
//     });
//   }

//   bool _isButtonCooldown(String colorName) {
//     final now = DateTime.now();
//     final lastPress = lastButtonPress[colorName] ?? DateTime(1970);
//     return now.difference(lastPress).inSeconds < cooldownSeconds;
//   }

//   @override
//   void dispose() {
//     animationTimer.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           // Sol taraf: Butonlar
//           Padding(
//             padding: const EdgeInsets.only(right: 40),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 // Kırmızı Buton
//                 ElevatedButton(
//                   onPressed: _isButtonCooldown('red')
//                       ? null
//                       : () => _startButtonAnimation(colorMap['red']!, 'red'),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: colorMap['red'],
//                     disabledBackgroundColor: Colors.red[900],
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 20,
//                       vertical: 15,
//                     ),
//                   ),
//                   child: Text(
//                     'Kırmızı',
//                     style: TextStyle(
//                       color: _isButtonCooldown('red')
//                           ? Colors.grey
//                           : Colors.white,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 // Yeşil Buton
//                 ElevatedButton(
//                   onPressed: _isButtonCooldown('green')
//                       ? null
//                       : () =>
//                             _startButtonAnimation(colorMap['green']!, 'green'),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: colorMap['green'],
//                     disabledBackgroundColor: Colors.green[900],
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 20,
//                       vertical: 15,
//                     ),
//                   ),
//                   child: Text(
//                     'Yeşil',
//                     style: TextStyle(
//                       color: _isButtonCooldown('green')
//                           ? Colors.grey
//                           : Colors.black,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 // Mavi Buton
//                 ElevatedButton(
//                   onPressed: _isButtonCooldown('blue')
//                       ? null
//                       : () => _startButtonAnimation(colorMap['blue']!, 'blue'),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: colorMap['blue'],
//                     disabledBackgroundColor: Colors.blue[900],
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 20,
//                       vertical: 15,
//                     ),
//                   ),
//                   child: Text(
//                     'Mavi',
//                     style: TextStyle(
//                       color: _isButtonCooldown('blue')
//                           ? Colors.grey
//                           : Colors.white,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           // Sağ taraf: Çubuk
//           Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               // Boru şeklindeki hücreler
//               Container(
//                 decoration: BoxDecoration(
//                   border: Border.all(color: Colors.white30, width: 2),
//                   borderRadius: BorderRadius.circular(15),
//                 ),
//                 padding: const EdgeInsets.all(8),
//                 child: Column(
//                   children: List.generate(cellCount, (index) {
//                     return Container(
//                       width: 60,
//                       height: 30,
//                       margin: const EdgeInsets.symmetric(vertical: 2),
//                       decoration: BoxDecoration(
//                         color: cellColors[index],
//                         borderRadius: BorderRadius.circular(8),
//                         boxShadow: cellColors[index] != Colors.grey[800]
//                             ? [
//                                 BoxShadow(
//                                   color: cellColors[index].withOpacity(0.6),
//                                   blurRadius: 10,
//                                   spreadRadius: 2,
//                                 ),
//                               ]
//                             : [],
//                       ),
//                     );
//                   }),
//                 ),
//               ),
//               const SizedBox(height: 30),
//               Text(
//                 'Boru Animasyon',
//                 style: Theme.of(
//                   context,
//                 ).textTheme.headlineSmall?.copyWith(color: Colors.white),
//               ),
//             ],
//           ),
//           // Sağ taraf: Skorbord ve Reset
//           Padding(
//             padding: const EdgeInsets.only(left: 40),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 // Skorbord başlığı
//                 Text(
//                   'Skor',
//                   style: Theme.of(
//                     context,
//                   ).textTheme.headlineSmall?.copyWith(color: Colors.white),
//                 ),
//                 const SizedBox(height: 30),
//                 // Bilgisayar Skoru
//                 Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 20,
//                     vertical: 15,
//                   ),
//                   decoration: BoxDecoration(
//                     color: Colors.blue[900],
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: Column(
//                     children: [
//                       Text(
//                         'Bilgisayar',
//                         style: Theme.of(context).textTheme.labelMedium
//                             ?.copyWith(color: Colors.white70),
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         computerScore.toString(),
//                         style: Theme.of(context).textTheme.headlineLarge
//                             ?.copyWith(
//                               color: Colors.white,
//                               fontWeight: FontWeight.bold,
//                             ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 // Kullanıcı Skoru
//                 Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 20,
//                     vertical: 15,
//                   ),
//                   decoration: BoxDecoration(
//                     color: Colors.green[900],
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: Column(
//                     children: [
//                       Text(
//                         'Siz',
//                         style: Theme.of(context).textTheme.labelMedium
//                             ?.copyWith(color: Colors.white70),
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         userScore.toString(),
//                         style: Theme.of(context).textTheme.headlineLarge
//                             ?.copyWith(
//                               color: Colors.white,
//                               fontWeight: FontWeight.bold,
//                             ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 30),
//                 // Reset Düğmesi
//                 ElevatedButton(
//                   onPressed: _resetScores,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.grey[700],
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 20,
//                       vertical: 12,
//                     ),
//                   ),
//                   child: const Text(
//                     'Sıfırla',
//                     style: TextStyle(color: Colors.white),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
