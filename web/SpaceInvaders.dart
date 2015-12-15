library spaceinvaders;

import 'dart:async';
import 'dart:html';
import 'dart:math';

part 'Game.dart';
part 'Player.dart';
part 'Rocket.dart';
part 'Enemy.dart';
part 'EnemyRow.dart';
part 'GameDrawer.dart';
part 'Directions.dart';
part 'ScreenObject.dart';

CanvasElement canvas;
ButtonElement startButton, stopButton;
Game game;

void main() {
  canvas = querySelector('#canvas');
  startButton = querySelector('#start-button');
  startButton.onClick.listen(startGame);
  stopButton = querySelector('#stop-button');
  stopButton.onClick.listen(stopGame);
}

void startGame(MouseEvent event) {
  toggleButtons();
  
  /* Start game when images are done loading. */
  loadImages(['player', 'enemy', 'rocket'], (images) {
    game = new Game(canvas, images['player'], images['enemy'], images['rocket']);
    game.setup();
    game.start();
  });
}

void stopGame(MouseEvent event) {
  toggleButtons();
  game.stop();
  game = null;
}

/** 
 * Since images are not loaded in the constructor of ImageElement
 * we have to wait for them to load and use a callback when all
 * images have been loaded.
 */
void loadImages(List<String> sources, callback) {
  Map<String, ImageElement> images = new Map<String, ImageElement>();
  for (String source in sources) {
    ImageElement img = new ImageElement(src: 'img/${source}.png');
    img.onLoad.listen((event) {
      images.putIfAbsent(source, () => img);
      if (images.length == sources.length)
        callback(images);
    });
  }
}

void toggleButtons() {
  startButton.disabled = ! startButton.disabled;
  stopButton.disabled = ! stopButton.disabled;
}
