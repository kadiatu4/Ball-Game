//
//  GameScene.swift
//  Ball Game
//
//  Created by Kadiatou Diallo on 7/6/16.
//  Copyright (c) 2016 Kadiatou Diallo. All rights reserved.
//

import SpriteKit

enum GameSceneState{
    case Title, Active, GameOver
}

class GameScene: SKScene, SKPhysicsContactDelegate{
    
    //UI Objects
    var ball: SKSpriteNode!
    var Obstacle1: SKNode!
    var Obstacle2: SKNode!
    var onPlatform: SKSpriteNode!
    var spawnTimer: CFTimeInterval = 0   //Timing for Obtacles
    var sinceTouch : CFTimeInterval = 0
    let fixedDelta: CFTimeInterval = 1.0/60.0 /* 60 FPS */
    let scrollSpeed: CGFloat = 200
    var scrollLayer: SKNode!
    var defaultObstacle: SKSpriteNode!
    var gameState: GameSceneState = .Title
    var scoreLabel: SKLabelNode!
    var finalScore: SKLabelNode!
    var points: Int = 0{
        didSet{
            scoreLabel.text = String(points)
            finalScore.text = String(points)
        }
    }
    var buttonPlay: MSButtonNode!
    var mainMenu: SKSpriteNode!
    var GameOverLabel: SKLabelNode!
    var GameOver: SKSpriteNode!
    var buttonReplay: MSButtonNode!
    var highscoreLabel: SKLabelNode!
    var highscore: SKLabelNode!

    var highscoreVal: Int = 0{
        didSet{
            highscore.text = String(highscoreVal)
        }
    
    }
    

    override func didMoveToView(view: SKView) {
        
        //Reference for the ball
        ball = self.childNodeWithName("//ball") as! SKSpriteNode
       
       //Reference for Obstacle 1 
        Obstacle1 = self.childNodeWithName("Obstacle1")
        
        //Reference for Obstacle 2
       Obstacle2 = self.childNodeWithName("Obstacle2")
        
        //Reference for the obstacle that holds Ball
        defaultObstacle = childNodeWithName("defaultObstacle") as! SKSpriteNode
        
        //Reference for Scroll Layer
        scrollLayer = self.childNodeWithName("scrollLayer")
        
        //Reference for On Platform
        onPlatform = childNodeWithName("//onPlatform") as! SKSpriteNode
        
        //Reference for Score Label
        scoreLabel = childNodeWithName("scoreLabel") as! SKLabelNode
        
        //Reference for Main Menu
        mainMenu = childNodeWithName("//mainMenu") as! SKSpriteNode
        
        //Reference for Play Button
        buttonPlay = childNodeWithName("buttonPlay") as! MSButtonNode
        
        //Reference for Replay Button
        buttonReplay = childNodeWithName("buttonReplay") as! MSButtonNode
        
        //Reference for Final Score
        finalScore = childNodeWithName("finalScore") as! SKLabelNode
        
        //Reference for High Score Label
        highscoreLabel = childNodeWithName("highscoreLabel") as! SKLabelNode
        
        //Reference for High Score Label
        highscore = childNodeWithName("highscore") as! SKLabelNode
        
        //Reference for Game Over Label
        GameOverLabel = childNodeWithName("GameOverLabel") as! SKLabelNode
        
        //Reference for the Game Over Scene
        GameOver = childNodeWithName("GameOver") as! SKSpriteNode
        

        //Play Button
        buttonPlay.selectedHandler = {
            //Start Game
            self.buttonPlay.zPosition = -2
            self.mainMenu.zPosition = -2
            self.gameState = .Active
            
        }
        
        let highscoreDefault = NSUserDefaults.standardUserDefaults()
        
        if (highscoreDefault.valueForKey("Highscore") != nil){
            
            highscoreVal = highscoreDefault.valueForKey("Highscore") as! NSInteger
        }

        
        /* Set physics contact delegate */
        physicsWorld.contactDelegate = self
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
    
        /* Disable touch if game state is not active */
        if gameState != .Active {return}
    
        /* Reset velocity, helps improve response against cumulative falling velocity */
        ball.physicsBody?.velocity = CGVectorMake(0, 0)

        //Apply vertical impulse
        ball.physicsBody?.applyImpulse(CGVectorMake(0, 250))
       
        /* Apply subtle rotation */
        ball.physicsBody?.applyAngularImpulse(1)
    
        /* Reset touch timer */
        sinceTouch = 0
        }
    override func update(currentTime: CFTimeInterval) {
        
        /* Disable touch if game state is not active */
        if gameState != .Active {return}
        
        /* Ensure only called while game running */
        if gameState == .GameOver{  gameOver() }
        
        /* Grab current velocity */
        
        let velocityY = ball.physicsBody?.velocity.dy ?? 0
       
        
        /* Check and cap vertical velocity */
        if velocityY > 400 {
            ball.physicsBody?.velocity.dy = 400
        }
        
        if ball.position.y >= 280 {
            ball.position.y = 280
        }
        
        if ball.position.y == onPlatform.position.y{
            self.ball.physicsBody?.collisionBitMask = 5
            
        }
        
        /* Apply falling rotation */
        if sinceTouch > 1.0 {
           let impulse = -20000 * fixedDelta
           ball.physicsBody?.applyAngularImpulse(CGFloat(impulse))
            ball.position.x += 20
            if ball.position.y > onPlatform.position.y || ball.position.y > defaultObstacle.position.y{
                  self.ball.physicsBody?.collisionBitMask = 0
                  self.ball.position.y = -20
                }
            gameOver()

        }
       
        /* Clamp rotation */
        ball.zRotation.clamp(CGFloat(45).degreesToRadians(),CGFloat(0).degreesToRadians())
        ball.physicsBody?.angularVelocity.clamp(-2, 2)
    
        
        /* Update last touch timer */
        sinceTouch += fixedDelta
        
        //Process world scrolling
        scrollWorld()
        
        //Updating Obstacle
        updateObstacle()
        
        /*Update time*/
        spawnTimer += fixedDelta
        
        if points > highscoreVal{
            highscoreVal = points
            let highscoreDefault = NSUserDefaults.standardUserDefaults()
            highscoreDefault.setValue(highscoreVal, forKey: "Highscore")
            highscoreDefault.synchronize()
        }
    
    }
    
    func scrollWorld(){
        //Scroll World
        scrollLayer.position.x -= scrollSpeed * CGFloat(fixedDelta)
        //Loop through Background Node
        for ground in scrollLayer.children as! [SKSpriteNode]{
            
            //Get ground node position, convert node position to scene space
            let backgroundPosition = scrollLayer.convertPoint(ground.position, toNode: self)
            //Check if background sprite has left the scene
            if backgroundPosition.x <= -ground.size.width / 2{
                /* Reposition ground sprite to the second starting position */
                let newPosition = CGPointMake( (self.size.width / 2) + ground.size.width, backgroundPosition.y)
                
                /* Convert new node position back to scroll layer space */
                ground.position = self.convertPoint(newPosition, toNode: scrollLayer)

            }
        }
    }
    
    func didBeginContact(contact: SKPhysicsContact) {
        
        /* Physics contact delegate implementation */
        
        /* Ensure only called while game running */
        if gameState != .Active { return }

        
         let contactA:SKPhysicsBody = contact.bodyA
        let contactB:SKPhysicsBody = contact.bodyB
        
        /* Get references to the physics body parent nodes */
        let nodeA = contactA.node!
        let nodeB = contactB.node!
     
        /* Did the ball land on the 'platform'? */
        if nodeA.name == "onPlatform" || nodeB.name == "onPlatform" {
        
            //Increment points
            points += 1
          
        }
        else if nodeA.name == "drop" || nodeB.name == "drop"{
            self.ball.physicsBody?.collisionBitMask = 0
            ball.position.y -= 20
            gameOver()
        }
       

        /* Stop any new angular velocity being applied */
        ball.physicsBody?.allowsRotation = false
        
        /* Reset angular velocity */
        ball.physicsBody?.angularVelocity = 0


    }
    
    func updateObstacle(){
        
        //Update Obstacle
        Obstacle1.position.x -= scrollSpeed * CGFloat(fixedDelta)
        Obstacle2.position.x -= scrollSpeed * CGFloat(fixedDelta)
        defaultObstacle.position.x -= scrollSpeed * CGFloat(fixedDelta)
        /* Loop through obstacle layer nodes */
        for obstacle in Obstacle1.children as! [SKReferenceNode] {
            
            /* Get obstacle node position, convert node position to scene space */
            let obstaclePosition = Obstacle1.convertPoint(obstacle.position, toNode: self)
            
            /* Check if obstacle has left the scene */
            if obstaclePosition.x <= -60{
                
                /* Remove obstacle node from obstacle layer */
                obstacle.removeFromParent()
            }
            
        }

        /* Time to add a new obstacle? */
        if spawnTimer >= 1.5 {
            
            /* Create a new obstacle reference object using our obstacle resource */
            let resourcePath1 = NSBundle.mainBundle().pathForResource("Obstacle_1", ofType: "sks")
            let newObstacle1 = SKReferenceNode (URL: NSURL (fileURLWithPath: resourcePath1!))
           
            let resourcePath2 = NSBundle.mainBundle().pathForResource("Obtacle_2", ofType: "sks")
            let newObstacle2 = SKReferenceNode (URL: NSURL (fileURLWithPath: resourcePath2!))
            
            //Create a new obstacle
            Obstacle1.addChild(newObstacle1)
            Obstacle2.addChild(newObstacle2)
            

            /* Generate new obstacle position, start just outside screen and with a random y value */
            let randomPosition = CGPointMake(360, CGFloat.random(min: 134, max: 382))
            
            /* Convert new node position back to obstacle layer space */
            newObstacle1.position = self.convertPoint(randomPosition, toNode: Obstacle1)
            newObstacle2.position = self.convertPoint(randomPosition, toNode: Obstacle2)
            
            
            // Reset spawn timer
            spawnTimer = 0
        }

    }
    func gameOver(){
        
        gameState = .GameOver
        /* Change play button selection handler */
        scoreLabel.zPosition = 0
        GameOver.zPosition = 15
        GameOverLabel.zPosition = 17
        finalScore.zPosition = 17
        buttonReplay.zPosition = 17
        highscoreLabel.zPosition = 17
        highscore.zPosition = 17

        buttonReplay.selectedHandler = {
            /* Grab reference to the SpriteKit view */
            let skView = self.view as SKView!
            
            /* Load Game scene */
            let scene = GameScene(fileNamed:"GameScene") as GameScene!
            
            /* Ensure correct aspect mode */
            scene.scaleMode = .AspectFill
            
            /* Restart GameScene */
            skView.presentScene(scene)
        }

    }
   
}
