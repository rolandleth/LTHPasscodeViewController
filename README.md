## String

```swift
"123"[2] // => 3
"123".length // => 3
"123" * 2 // => 123123
"123".containsString("12") // => true
"123".containsString("13") // => false
"123".isInt // => true; "123.0".isInt => false
"123".isFloat // => true; "123.0".isFloat => true; "123..0".isFloat => false
"123".toFloat // => 123.0
"123".toDouble // => 123.0
"123".toInt // => 123
"123".toBool // => true
"AvenirNext-Regular".uifont(16) // => UIFont(name: "AvenirNext-Regular", size: 16)
// If no size is supplied, UIFont.systemFontSize() is used
"myImage.png".uiimage() // => UIImage(named: "myImage.png")
```

## Int

```swift
5.isEven // => false
5.isOdd // => true
5.squared // => 25
5.square() // => 25
5.toFloat // => 5.0
5.times{ print("12345") } // => 1234512345
5.degreesToRadians // => 0.0872664600610733
```

## Float

```swift
5.0.degreesToRadians // => 0.0872664600610733
```

## Array

```swift
[1, 2].first // => 1
[1, 2].last // => 2
[1, 2] << 3 // => [1, 2, 3]
[1, 2] + 3 // => [1, 2, 3]
[1, 2] << "3", [1, 2] + "3" // different types => error
```

## Dictionary

```swift
[1: 1] += [2: 2] // => [1: 1, 2: 2]
[1: 1] << [2: 2] // => [1: 1, 2: 2]
[1: 1] + [2: 2] // => [1: 1, 2: 2]
[1: 1] << [2: "2"], [1: 1] += [2: "2"], [1: 1] + [2: "2"] // different types => error
```

## UIView

```swift
view << view1 // view.subviews = [view1]
view[0] // => view1
```

## AnyObject

```swift
var s: String? // Works with any Optional
s ||= "1" // => 1
s ||= "2" // => 1
s ||= 2 // different types => error
```

## UIImage

```swift
UIImage.imageWithColor(UIColor.redColor())
UIImage(named: "my-image").tintedImageWithColor(UIColor.redColor(), blendMode: kCGBlendModeHue)
```

## License
Licensed under MIT.

---

Feel free to contact me for any questions, I'd be more than happy to hear from you [@rolandleth](https://twitter.com/rolandleth) or at [roland@rolandleth.com](mailto:roland@rolandleth.com).