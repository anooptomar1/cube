//
//  SpawnPoint.swift
//  cube
//
//  Created by Ross Huelin on 20/03/2016.
//  Copyright © 2016 filmstarr. All rights reserved.
//

import Foundation
import SceneKit
import GameplayKit

class SpawnPoint: SCNNode {
    
    let events = EventManager()

    var lastSpawnTime: NSTimeInterval?
    
    var parent = SCNNode()
    var spawnPointNode = GKGraphNode2D()
    var originNode = GKGraphNode2D()
    
    init(parent: SCNNode, position: SCNVector3, size: CGFloat, spawnPointNode: GKGraphNode2D, originNode: GKGraphNode2D) {
        self.parent = parent
        self.spawnPointNode = spawnPointNode
        self.originNode = originNode

        super.init()
        
        let tile = SCNPlane(width: size, height: size)
        tile.firstMaterial?.diffuse.contents = UIColor.blackColor()
        self.geometry = tile
        self.eulerAngles = SCNVector3(GLKMathDegreesToRadians(-90), 0, 0)
        self.position = position

        parent.addChildNode(self)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func update(time: NSTimeInterval) {
        if (self.lastSpawnTime == nil) {
            self.lastSpawnTime = time
            return
        }
        
        if (time - self.lastSpawnTime! > 3.0) {
            self.spawn()
            self.lastSpawnTime = time
        }
    }
    
    func spawn() {
        let daemon = Daemon(parent: self.parent, position: self.position, initialNode: self.spawnPointNode, destinationNode: self.originNode)
        print("SpawnPoint:daemon created")
        self.events.trigger("spawn", information: daemon)
    }
}