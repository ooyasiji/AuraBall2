let splashes = [];
let balls = [];
let numBalls = 4;
let allBallsClicked = false;
let score = 1000;
let losingAuraMessage = false;
let losingAuraMessageAlpha = 255;

function setup() {
  createCanvas(500, 500);
  background(135, 206, 235); // Light blue background
  for (let i = 0; i < numBalls; i++) {
    balls.push(new Ball());
  }
}

function draw() {
  background(135, 206, 235); // Light blue background
  
  for (let i = balls.length - 1; i >= 0; i--) {
    balls[i].update();
    balls[i].display();
  }
  
  for (let i = splashes.length - 1; i >= 0; i--) {
    let splash = splashes[i];
    splash.update();
    splash.display();
    
    // Remove the splash if it has faded out
    if (splash.isDone()) {
      splashes.splice(i, 1);
    }
  }
  
  if (allBallsClicked) {
    displayWinningMessage();
  }
  
  displayScore();
  
  if (losingAuraMessage) {
    displayLosingAuraMessage();
  }

  displayCredit();
}

function mousePressed() {
  if (allBallsClicked) {
    return;
  }

  let ballClicked = false;
  for (let i = balls.length - 1; i >= 0; i--) {
    if (dist(mouseX, mouseY, balls[i].x, balls[i].y) < balls[i].diameter / 2) {
      splashes.push(new Splash(mouseX, mouseY, "Good job!"));
      balls.splice(i, 1);
      ballClicked = true;
      break;
    }
  }
  
  if (!ballClicked) {
    splashes.push(new Splash(mouseX, mouseY, "Gotcha!"));
    score -= 25;
    losingAuraMessage = true;
    losingAuraMessageAlpha = 255;
  }
  
  if (balls.length === 0) {
    allBallsClicked = true;
  }
}

function keyPressed() {
  if (allBallsClicked && keyCode === ENTER) {
    restart();
  }
}

class Splash {
  constructor(x, y, message) {
    this.x = x;
    this.y = y;
    this.size = 0;
    this.maxSize = 150;
    this.alpha = 255;
    this.message = message;
  }
  
  update() {
    this.size += 4;
    this.alpha -= 3;
  }
  
  display() {
    fill(random(255), random(255), random(255), this.alpha);
    noStroke();
    ellipse(this.x, this.y, this.size);
    
    if (this.size > this.maxSize / 2) {
      fill(0, this.alpha);
      textSize(32);
      textStyle(BOLD);
      textAlign(CENTER, CENTER);
      text(this.message, this.x, this.y);
    }
  }
  
  isDone() {
    return this.alpha <= 0;
  }
}

class Ball {
  constructor() {
    this.x = random(width);
    this.y = random(height);
    this.diameter = 30;
    this.xSpeed = random(2, 5);
    this.ySpeed = random(2, 5);
  }
  
  update() {
    this.x += this.xSpeed;
    this.y += this.ySpeed;
    
    if (this.x < 0 || this.x > width) {
      this.xSpeed *= -1;
    }
    if (this.y < 0 || this.y > height) {
      this.ySpeed *= -1;
    }
  }
  
  display() {
    fill(255, 0, 0);
    noStroke();
    ellipse(this.x, this.y, this.diameter);
  }
}

function displayScore() {
  fill(0);
  textSize(20);
  textAlign(LEFT, TOP);
  text("Score: " + score, 10, 10);
}

function displayLosingAuraMessage() {
  fill(255, 0, 0, losingAuraMessageAlpha);
  textSize(32);
  textStyle(BOLD);
  textAlign(CENTER, CENTER);
  text("You are losing aura! D:", width / 2, height / 2);
  losingAuraMessageAlpha -= 5;
  
  if (losingAuraMessageAlpha <= 0) {
    losingAuraMessage = false;
  }
}

function displayWinningMessage() {
  fill(0);
  textSize(32);
  textStyle(BOLD);
  textAlign(CENTER, CENTER);
  text("Wow! You are the winner!", width / 2, height / 2);
  text("Final Score: " + score, width / 2, height / 2 + 40);
  textSize(20);
  text("Press Enter to Restart", width / 2, height / 2 + 80);
}

function displayCredit() {
  fill(0);
  textSize(16);
  textAlign(CENTER, BOTTOM);
  text("created by demi", width / 2, height - 10);
}

function restart() {
  allBallsClicked = false;
  splashes = [];
  balls = [];
  for (let i = 0; i < numBalls; i++) {
    balls.push(new Ball());
  }
  score = 1000;
}
