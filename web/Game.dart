part of spaceinvaders;

/**
 * Author: Jimmy Pettersson.
 * 
 * Game class containing the overall logic of the game.
 * 
 * Known issues: Vertical sync issues.
 * 
 * */


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
  static const int DELAY = 20; // 50fps
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
  
  /** Sets up the initial game state and draws the game board. */
  void setup() {
    drawStatics();
    initializeLevel();
  }
  
  /** Add enemies to the level. */
  void initializeLevel() {
      enemyRows.add(new EnemyRow(context, 60, 50));
      enemyRows.add(new EnemyRow(context, 60, 100));
      enemyRows.add(new EnemyRow(context, 60, 150));
      enemyRows.add(new EnemyRow(context, 60, 200));
  }
  
  /** Event handler for when a key is pressed. */
  void handleKeyDown(KeyboardEvent event) {
    if (event.keyCode == LEFT) {
      actionFlag = LEFT;
    } else if (event.keyCode == RIGHT) {
      actionFlag = RIGHT;
    } else if (event.keyCode == FIRE && playerRockets.length < 5) {
      playerRockets.add(new Rocket(context, player.rocketCenterX, player.rocketTop));
    }
  }
  
  /** Event handler for when a key is relased. */
  void handleKeyUp(KeyboardEvent event) {
    if (event.keyCode == LEFT || event.keyCode == RIGHT) actionFlag = NONE;
  }
  
  /** Starts the game by starting the different timers. */
  void start() {
    tickId = new Timer.periodic(const Duration(milliseconds: DELAY), (_) => tick());
    movePlayerId = new Timer.periodic(const Duration(milliseconds: DELAY), (_) => movePlayer());
    int moveDelay = MOVE_DOWN_DELAY - 5 * level;
    moveEnemyDownId = new Timer.periodic(new Duration(milliseconds: moveDelay), (_) => moveEnemyDown());
  }
  
  /** Stops the current game. */
  void stop() {
    clearIntervals();
    drawStatics();
  }
  
  /** 
   * A game "tick" invoked each DELAY ms. 
   * Updates all the states of the game and checks for collisions.
   */
  void tick() {
    drawStatics();
    player.draw();
    updateRocketPositions();
    updateEnemyPositions();
    checkCollisions();
  }
  
  /** Updates the positions on all rockets in play. */
  void updateRocketPositions() {
    for (Rocket r in playerRockets.toList()) {
      r.updatePosition(0, Directions.UP * Rocket.DY);
      if (r.invalid) {
        int index = playerRockets.indexOf(r);
        playerRockets.removeRange(index, index+1);
      }
    }
    
    for (Rocket r in enemyRockets.toList()) {
      r.updatePosition(0, Directions.DOWN * Rocket.DY);
      if (r.invalid) {
        int index = enemyRockets.indexOf(r);
        enemyRockets.removeRange(index, index+1);
      }
    } 
  }
  
  /** Updates the position of all enemies and checks for game over. */
  void updateEnemyPositions() {
    for (EnemyRow er in enemyRows) {
      er.updateEnemyPositions();
      if (er.reachedBottom()) gameOver();
    }
  }
  
  /** Collision detection between rockets and enemies/player. */
  void checkCollisions() {
    /* Player rockets hitting enemies */
    for (EnemyRow er in enemyRows.toList()) {
      for (Enemy e in er.enemies.toList()) {
        for (Rocket r in playerRockets.toList()) {
          if (e.checkCollision(r)) {
            score++;
            int index = playerRockets.indexOf(r);
            playerRockets.removeRange(index, index+1);
            er.removeEnemy(e);
            if (er.empty) {
              int index = enemyRows.indexOf(er);
              enemyRows.removeRange(index, index+1);
            }
            
            if (enemyRows.isEmpty) advanceLevel();
            
            // This enemy has already been hit by a rocket, no need to loop over the rest.
            break;
          }
        }
      }
    }
    
    /* Enemy rockets hitting player */
    for (Rocket r in enemyRockets) {
      if (player.checkCollision(r)) {
        gameOver();
        break;
      }
    }
  }
  
  /** Moves the player. */
  void movePlayer() {
    if (actionFlag == LEFT && player.x > 0) {
      player.updatePosition(Directions.LEFT * Player.DX, 0);
    } else if (actionFlag == RIGHT && player.x < Game.WIDTH - Player.SIZE) {
      player.updatePosition(Directions.RIGHT * Player.DX, 0);
    }
  }
  
  /** Moves the enemies downward slowly. Acts on a separate timer. */
  void moveEnemyDown() {
    for (EnemyRow er in enemyRows) {
      er.moveEnemyDown();
    }
    
    /* Fire rockets at random on this timer */
    if (enemyRockets.length < 3 && random.nextDouble() > 0.95) {
      EnemyRow er = enemyRows[(random.nextDouble() * enemyRows.length).toInt()];
      Enemy e = er.enemies[(random.nextDouble() * er.enemies.length).toInt()];
      enemyRockets.add(new Rocket(context, e.rocketCenterX, e.rocketBottom));
    }
  }
  
  /** Advances the game one level. */
  void advanceLevel() {
    level++;
    clearIntervals();
    drawStatics();
    playerRockets.clear();
    enemyRockets.clear();
    setup();
    start();  
  }
  
  /** Clear all timers */
  void clearIntervals() {
    tickId.cancel();
    movePlayerId.cancel();
    moveEnemyDownId.cancel();
  }
  
  /** Draws the background gradient, the score and level texts and the bottom line */
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
