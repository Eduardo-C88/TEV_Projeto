import Foundation

func -(left : CGPoint, right : CGPoint) -> CGPoint{
    return CGPoint(x: left.x - right.x, y: left.y - right.y )
}

func +(left : CGPoint, right : CGPoint) -> CGPoint{
    return CGPoint(x: left.x + right.x, y: left.y + right.y )
}

func *(point : CGPoint, scalar : CGFloat) -> CGPoint{
    return CGPoint(x: point.x * scalar, y: point.y * scalar )
}

func /(point : CGPoint, scalar : CGFloat) -> CGPoint{
    return CGPoint(x: point.x / scalar, y: point.y / scalar )
}

extension CGPoint{
    func normalized() -> CGPoint{
        return self / length()
    }
    func length() -> CGFloat{
        return sqrt(x * x + y * y)
    }
}
