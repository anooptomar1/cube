//
//  cube.swift
//  cube
//
//  Created by Ross Huelin on 10/10/2015.
//  Copyright © 2015 filmstarr. All rights reserved.
//

import Foundation
import UIKit
import QuartzCore
import SceneKit
import Darwin

class Cube {
    
    let πBy2 = Float(M_PI_2)
    let cubeSizeBy2:Float
    let xAxis = SCNVector3.init(x: 1.0, y: 0.0, z: 0.0)
    let zAxis = SCNVector3.init(x: 0.0, y: 0.0, z: 1.0)
    let origin = SCNVector3.init(x: 0.0, y: 0.0, z: 0.0)
    let rotationDurationReductionFactor = 0.95
    
    let cubeNode:SCNNode
    let cameraNode:SCNNode
    let cameraOrigin:SCNVector3
    let originalColour:UIColor

    let events = EventManager()
    
    var rotationDuration = 0.25
    var isRotating = false
    var pendingRotations:[(x: Float, z: Float)] = []
    var position = SCNVector3.init(x: 0.0, y: 0.0, z: 0.0)
    var isAlive = true
    
    init(cubeNode: SCNNode, cameraNode: SCNNode) {
        print("Cube:cube init")
        self.cameraNode = cameraNode
        self.cubeNode = cubeNode
        self.cameraOrigin = cameraNode.position
        self.originalColour = (self.cubeNode.geometry?.firstMaterial?.diffuse.contents)! as! UIColor

        var minVec = SCNVector3Zero
        var maxVec = SCNVector3Zero
        if self.cubeNode.getBoundingBoxMin(&minVec, max: &maxVec) {
           cubeSizeBy2 = (maxVec.x - minVec.x)/2
        }
        else {
            cubeSizeBy2 = 0.0
        }
        
        self.resetRotation(0.0, zOffset: 0.0)
    }
    
    func rotate(var x: Float, var z: Float) {
        if (isAlive) {
            if (!isRotating) {
                print("Cube:rotate cube")
                isRotating = true
                let currentPosition = self.cubeNode.position
                x = sign(x)
                z = sign(z)

                self.cubeNode.pivot = SCNMatrix4MakeTranslation(self.cubeSizeBy2 * x, -self.cubeSizeBy2, self.cubeSizeBy2 * z)
                self.cubeNode.position = SCNVector3(currentPosition.x + (self.cubeSizeBy2 * x), 0.0, currentPosition.z + (self.cubeSizeBy2 * z))
                self.position = SCNVector3(self.position.x + x, 0.0, self.position.z + z)
                if (x != 0.0) {
                    self.cubeNode.runAction(SCNAction.rotateByAngle(CGFloat(-πBy2 * x), aroundAxis: zAxis, duration: rotationDuration), completionHandler:{param in
                            self.finaliseRotation(self.cubeSizeBy2 * x, zOffset: 0.0)
                    })
                }
                if (z != 0.0) {
                    self.cubeNode.runAction(SCNAction.rotateByAngle(CGFloat(πBy2 * z), aroundAxis: xAxis, duration: rotationDuration), completionHandler:{param in
                            self.finaliseRotation(0.0, zOffset: self.cubeSizeBy2 * z)
                    })
                }
                self.updateCameraPosition(self.cubeSizeBy2 * 2 * x, zChange: self.cubeSizeBy2 * 2 * z)
                self.events.trigger("rotate", information: self.position)
            }
            else {
                print("Cube:queue rotation")
                self.rotationDuration *= self.rotationDurationReductionFactor
                self.pendingRotations += [(x: x, z: z)]
                print("Cube:rotation queue =", self.pendingRotations.count)
            }
        }
    }
    
    func finaliseRotation(xOffset: Float, zOffset: Float) {
        self.resetRotation(xOffset, zOffset: zOffset)
        self.isRotating = false
        
        //Check for any pending rotations that haven't been fulfilled
        if (self.pendingRotations.count != 0 && self.isAlive) {
            let rotation = self.pendingRotations[0]
            self.pendingRotations.removeAtIndex(0)
            self.rotate(rotation.x, z: rotation.z)
            self.rotationDuration /= self.rotationDurationReductionFactor
            print("Cube:rotation duration =",rotationDuration)
        }
    }
    
    func resetRotation(xOffset: Float, zOffset: Float) {
        self.isRotating = false
        self.cubeNode.position = SCNVector3(self.cubeNode.position.x + xOffset, 0.0, self.cubeNode.position.z + zOffset)
        self.cubeNode.rotation = SCNVector4(0.0, 0.0, 0.0, 0.0)
        self.cubeNode.pivot = SCNMatrix4MakeTranslation(0.0, -self.cubeSizeBy2, 0.0)
    }
    
    func updateCameraPosition(xChange: Float, zChange: Float) {
        print("Cube:position camera")

        SCNTransaction.begin()
        SCNTransaction.setAnimationDuration(1.0)
        SCNTransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut))
        cameraNode.position = SCNVector3Make(cameraNode.position.x + xChange, cameraNode.position.y, cameraNode.position.z + zChange)
        SCNTransaction.commit()
    }
    
    func positionObject(object: SCNNode, animationDuration: Double, position: SCNVector3) {
        print("Cube:position object")
        
        SCNTransaction.begin()
        SCNTransaction.setAnimationDuration(animationDuration)
        SCNTransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut))
        object.position = position
        SCNTransaction.commit()
        
    }
    
    //TODO: Try and use this to reduce duplicate code
    //TODO: Show simple count of number of steps or distance travelled
    //TODO: Time callback not firing when mid rotation
    func animateTransition(function: () -> Void, animationDuration: Double) {
        SCNTransaction.begin()
        SCNTransaction.setAnimationDuration(animationDuration)
        SCNTransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut))
        function()
        SCNTransaction.commit()
    }
    
    func die() {
        print("Cube:dying")
        
        let duration = 3.0
        self.isAlive = false
        self.pendingRotations.removeAll()
        
        //Change colour
        SCNTransaction.begin()
        SCNTransaction.setAnimationDuration(duration)
        SCNTransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut))
        self.cubeNode.geometry?.firstMaterial?.diffuse.contents = UIColor.blackColor()
        SCNTransaction.commit()
        
        //Position camera
        self.positionObject(self.cameraNode, animationDuration: duration, position: self.cameraOrigin)
        
        //Position cube
        self.position = self.origin
        self.positionObject(self.cubeNode, animationDuration: duration, position: self.origin)
        
        //Bring back to life
        NSTimer.scheduledTimerWithTimeInterval(duration, target:self, selector: "revive", userInfo: nil, repeats: false)
    }
    
    dynamic func revive() {
        print("Cube:reviving")
        self.isAlive = true
        self.pendingRotations.removeAll()
        let duration = 3.0
        SCNTransaction.begin()
        SCNTransaction.setAnimationDuration(duration)
        SCNTransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut))
        self.cubeNode.geometry?.firstMaterial?.diffuse.contents = self.originalColour
        SCNTransaction.commit()
    }
}