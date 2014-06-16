Includes Operator Overloading

## String

```swift
"123"[2] // => 3
"123".length // => 3
"123" * 2 // => 123123
"123".containsString("12") // => true
"123".containsString("13") // => false
"123".isInt // => true; "123.0".isInt => false
"123".isFloat // => true; "123.0".isFloat => true; "123..0".isFloat => false
```

## Int

```swift
5.isEven // => false
5.isOdd // => true
5.squared // => 25
5.square() // => 25
5.asFloat // => 5.0
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
[1, 2] += 3 // => [1, 2, 3]
let arr = [1, 2] + 3 // => [1, 2, 3]
// Using different types raises an error
[1, 2] += "3", [1, 2] << "3", [1, 2] + "3"
```

## Dictionary

```swift
[1: 1] += [2: 2] // => [1: 1, 2: 2]
[1: 1] << [2: 2] // => [1: 1, 2: 2]
let dic = [1: 1] + [2: 2] // => [1: 1, 2: 2]
// Using different types raises an error
[1: 1] << [2: "2"], [1: 1] += [2: "2"], [1: 1] + [2: "2"]
```

## UIView

```swift
view << view1 // view.subviews = [view1]
view[0] // => view1
```

## UIImage

```swift
UIImage.imageWithColor(UIColor.redColor())
UIImage(named: "my-image").tintedImageWithColor(UIColor.redColor(), blendMode: kCGBlendModeHue)
```

Feel free to contact me for any questions, I'd be more than happy to hear from you [@rolandleth](https://twitter.com/rolandleth).
  
## License
Licensed under MIT.