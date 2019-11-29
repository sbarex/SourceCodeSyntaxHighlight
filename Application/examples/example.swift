import UIKit

class ViewController: UIViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Declare String value
		let firstName:String = "Sergey"

		// Declare Int value
		let intNumber:Int=5
		
		// Call the "takeAway()" function we have extended the Int class with:
		print("5 take away 4 equals \(intNumber.takeAway(4))")
		
		// Call the greatTheWorld() function we have extended the String class with
		firstName.greatTheWorld()
	}
 
}

// Extend the String class in Swift
extension String {
	func greatTheWorld() {
		 print("Hello world")
	}
}

// Extend the Int class in Swift
extension Int {
	func takeAway(a:Int)->Int {
		return self-a;
	}
}
