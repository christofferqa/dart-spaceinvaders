library spaceinvaders;

import 'dart:async';
import 'dart:html';
import 'dart:math';

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
  loadImages([
    'player',
    'enemy',
    'rocket'
  ], (images) {
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

void loadImages(List<String> sources, callback) {
  Map<String, ImageElement> images = new Map<String, ImageElement>();
  for (String source in sources) {
    ImageElement img = new ImageElement(src: 'img/${source}.png');
    img.onLoad.listen((event) {
      images.putIfAbsent(source, () => img);
      if (images.length == sources.length) callback(images);
    });
  }
}

void toggleButtons() {
  startButton.disabled = !startButton.disabled;
  stopButton.disabled = !stopButton.disabled;
}

class Game {
  CanvasRenderingContext2D context;
  Player player;
  List<Rocket> playerRockets, enemyRockets;
  List<EnemyRow> enemyRows;
  int score, level, actionFlag;
  Timer tickId, movePlayerId, moveEnemyDownId;
  Random random = new Random();
  static ImageElement playerImage, enemyImage, rocketImage;
  static const int WIDTH = 800;
  static const int HEIGHT = 800;
  static const int LEFT = 37;
  static const int RIGHT = 39;
  static const int FIRE = 32;
  static const int NONE = 0;
  static const int DELAY = 20;
  static const int MOVE_DOWN_DELAY = 100;
  Game(CanvasElement canvas, ImageElement playerImage, ImageElement enemyImage, ImageElement rocketImage) {
    context = canvas.context2D;
    Game.playerImage = playerImage;
    Game.enemyImage = enemyImage;
    Game.rocketImage = rocketImage;
    playerRockets = new List<Rocket>();
    enemyRockets = new List<Rocket>();
    enemyRows = new List<EnemyRow>();
    player = new Player(context);
    score = 0;
    level = 1;
    window.onKeyDown.listen(handleKeyDown);
    window.onKeyUp.listen(handleKeyUp);
  }
  void setup() {
    drawStatics();
    initializeLevel();
  }

  void initializeLevel() {
    enemyRows.add(new EnemyRow(context, 60, 50));
    enemyRows.add(new EnemyRow(context, 60, 100));
    enemyRows.add(new EnemyRow(context, 60, 150));
    enemyRows.add(new EnemyRow(context, 60, 200));
  }

  void handleKeyDown(KeyboardEvent event) {
    if (event.keyCode == LEFT) {
      actionFlag = LEFT;
    } else if (event.keyCode == RIGHT) {
      actionFlag = RIGHT;
    } else if (event.keyCode == FIRE && playerRockets.length < 5) {
      playerRockets.add(new Rocket(context, player.rocketCenterX, player.rocketTop));
    }
  }

  void handleKeyUp(KeyboardEvent event) {
    if (event.keyCode == LEFT || event.keyCode == RIGHT) actionFlag = NONE;
  }

  void start() {
    tickId = new Timer.periodic(const Duration(milliseconds: DELAY), (_) => tick());
    movePlayerId = new Timer.periodic(const Duration(milliseconds: DELAY), (_) => movePlayer());
    int moveDelay = MOVE_DOWN_DELAY - 5 * level;
    moveEnemyDownId = new Timer.periodic(new Duration(milliseconds: moveDelay), (_) => moveEnemyDown());
  }

  void stop() {
    clearIntervals();
    drawStatics();
  }

  void tick() {
    drawStatics();
    player.draw();
    updateRocketPositions();
    updateEnemyPositions();
    checkCollisions();
  }

  void updateRocketPositions() {
    for (Rocket r in playerRockets.toList()) {
      r.updatePosition(0, Directions.UP * Rocket.DY);
      if (r.invalid) {
        int index = playerRockets.indexOf(r);
        playerRockets.removeRange(index, index + 1);
      }
    }
    for (Rocket r in enemyRockets.toList()) {
      r.updatePosition(0, Directions.DOWN * Rocket.DY);
      if (r.invalid) {
        int index = enemyRockets.indexOf(r);
        enemyRockets.removeRange(index, index + 1);
      }
    }
  }

  void updateEnemyPositions() {
    for (EnemyRow er in enemyRows) {
      er.updateEnemyPositions();
      if (er.reachedBottom()) gameOver();
    }
  }

  void checkCollisions() {
    for (EnemyRow er in enemyRows.toList()) {
      for (Enemy e in er.enemies.toList()) {
        for (Rocket r in playerRockets.toList()) {
          if (e.checkCollision(r)) {
            score++;
            int index = playerRockets.indexOf(r);
            playerRockets.removeRange(index, index + 1);
            er.removeEnemy(e);
            if (er.empty) {
              int index = enemyRows.indexOf(er);
              enemyRows.removeRange(index, index + 1);
            }
            if (enemyRows.isEmpty) advanceLevel();
            break;
          }
        }
      }
    }
    for (Rocket r in enemyRockets) {
      if (player.checkCollision(r)) {
        gameOver();
        break;
      }
    }
  }

  void movePlayer() {
    if (actionFlag == LEFT && player.x > 0) {
      player.updatePosition(Directions.LEFT * Player.DX, 0);
    } else if (actionFlag == RIGHT && player.x < Game.WIDTH - Player.SIZE) {
      player.updatePosition(Directions.RIGHT * Player.DX, 0);
    }
  }

  void moveEnemyDown() {
    for (EnemyRow er in enemyRows) {
      er.moveEnemyDown();
    }
    if (enemyRockets.length < 3 && random.nextDouble() > 0.95) {
      EnemyRow er = enemyRows[(random.nextDouble() * enemyRows.length).toInt()];
      Enemy e = er.enemies[(random.nextDouble() * er.enemies.length).toInt()];
      enemyRockets.add(new Rocket(context, e.rocketCenterX, e.rocketBottom));
    }
  }

  void advanceLevel() {
    level++;
    clearIntervals();
    drawStatics();
    playerRockets.clear();
    enemyRockets.clear();
    setup();
    start();
  }

  void clearIntervals() {
    tickId.cancel();
    movePlayerId.cancel();
    moveEnemyDownId.cancel();
  }

  void drawStatics() {
    GameDrawer.drawBackground(context);
    GameDrawer.updateScoreText(context, score);
    GameDrawer.updateLevelText(context, level);
    GameDrawer.drawBottomLine(context);
  }

  void gameOver() {
    clearIntervals();
    drawStatics();
    GameDrawer.drawGameOver(context);
    startButton.disabled = false;
    stopButton.disabled = true;
  }
}

class Player extends ScreenObject {
  static final int SIZE = 40;
  static final int DX = 10;
  Player(CanvasRenderingContext2D context) : super(context, 0, Game.HEIGHT - SIZE, SIZE, Game.playerImage) {
    draw();
  }
  void updatePosition(int dx, int dy) {
    x += dx;
    y += dy;
  }
}

class Rocket extends ScreenObject {
  static final int SIZE = 5;
  static final int DY = 10;
  Rocket(CanvasRenderingContext2D context, int x, int y) : super(context, x, y, SIZE, Game.rocketImage) {}
  bool get invalid => y < 0 || y > Game.HEIGHT;
}

class Enemy extends ScreenObject {
  int startX, direction;
  static final int SIZE = 40;
  static final int DX = 2;
  static final int DY = 1;
  Enemy(CanvasRenderingContext2D context, int direction, int x, int y) : super(context, x, y, SIZE, Game.enemyImage) {
    this.startX = x;
    this.direction = direction;
    draw();
  }
  bool get atBottom => y > 700;
  void updatePosition(int dx, int dy) {
    if (x >= startX + 2 * SIZE) direction = Directions.LEFT;
    else if (x <= startX) direction = Directions.RIGHT;
    super.updatePosition(direction * dx, dy);
  }
}

class EnemyRow {
  List<Enemy> enemies;
  EnemyRow(CanvasRenderingContext2D context, int startX, int startY) {
    enemies = new List<Enemy>();
    for (int i = 0; i < 10; i++) {
      enemies.add(new Enemy(context, Directions.RIGHT, startX + (i * 60), startY));
    }
  }
  void removeEnemy(Enemy e) {
    int index = enemies.indexOf(e);
    enemies.removeRange(index, index + 1);
  }

  bool get empty => enemies.isEmpty;
  void updateEnemyPositions() {
    for (Enemy e in enemies) {
      e.updatePosition(Enemy.DX, 0);
    }
  }

  void moveEnemyDown() {
    for (Enemy e in enemies) {
      e.updatePosition(0, Directions.DOWN * Enemy.DY);
    }
  }

  bool reachedBottom() {
    for (Enemy e in enemies) {
      if (e.atBottom) return true;
    }
    return false;
  }
}

class GameDrawer {
  static void drawBackground(CanvasRenderingContext2D context) {
    var grd = context.createLinearGradient(0, 0, Game.WIDTH, Game.HEIGHT);
    grd.addColorStop(0, '#8ED6FF');
    grd.addColorStop(1, '#004CB3');
    context.fillStyle = grd;
    context.fillRect(0, 0, Game.WIDTH, Game.HEIGHT);
  }

  static void drawBottomLine(CanvasRenderingContext2D context) {
    context.beginPath();
    context.moveTo(0, 740);
    context.lineTo(800, 740);
    context.strokeStyle = 'red';
    context.stroke();
  }

  static void updateScoreText(CanvasRenderingContext2D context, int score) {
    context.fillStyle = 'black';
    context.font = '20pt Calibri';
    context.fillText('Score: $score', 670, 30);
  }

  static void updateLevelText(CanvasRenderingContext2D context, int level) {
    context.fillStyle = 'black';
    context.font = '20pt Calibri';
    context.fillText('Level: $level', 550, 30);
  }

  static void drawGameOver(CanvasRenderingContext2D context) {
    context.fillStyle = 'black';
    context.font = '40pt Calibri';
    context.fillText('Game Over', Game.WIDTH / 2 - 125, Game.HEIGHT / 2);
  }
}

class Directions {
  static final int UP = -1;
  static final int DOWN = 1;
  static final int LEFT = -1;
  static final int RIGHT = 1;
}

class ScreenObject {
  CanvasRenderingContext2D context;
  int x, y, size;
  ImageElement image;
  ScreenObject(this.context, this.x, this.y, this.size, this.image);
  int get rocketCenterX => x + (size / 2).toInt() - (Rocket.SIZE / 2).toInt();
  int get rocketTop => y - Rocket.SIZE;
  int get rocketBottom => y + size + Rocket.SIZE;
  bool checkCollision(Rocket r) => ((r.x >= x && r.x < x + size) && (r.y >= y && r.y < y + size));
  void draw() {
    context.drawImage(image, x, y);
  }

  void updatePosition(int dx, int dy) {
    x += dx;
    y += dy;
    draw();
  }
}
