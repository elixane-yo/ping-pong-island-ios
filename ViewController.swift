import UIKit
import SpriteKit

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let skView = SKView(frame: view.bounds)
        view.addSubview(skView)
        
        let scene = GameScene(size: view.bounds.size)
        scene.scaleMode = .resizeFill
        skView.presentScene(scene)
        
        skView.showsFPS = true
        skView.showsNodeCount = true
    }
}