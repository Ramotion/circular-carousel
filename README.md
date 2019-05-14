<img src="https://github.com/Ramotion/circular-carousel/blob/master/header.png">

<a href="https://github.com/Ramotion/circular-carousel">
<img align="left" src="https://github.com/Ramotion/circular-carousel/blob/master/Screenshots/ios_circular_carousel.gif" width="480" height="360" /></a>

<p><h1 align="left">CAROUSEL</h1></p>

<h4>List a collection of items in a horizontally scrolling view. A scaling factor controls the size of the items relative to the center.</h4>

___


<p><h6>We specialize in the designing and coding of custom UI for Mobile Apps and Websites.</h6>
<a href="https://dev.ramotion.com?utm_source=gthb&utm_medium=repo&utm_campaign=folding-cell">
<img src="https://github.com/ramotion/gliding-collection/raw/master/contact_our_team@2x.png" width="187" height="34"></a>
</p>
<p><h6>Stay tuned for the latest updates:</h6>
<a href="https://goo.gl/rPFpid" >
<img src="https://i.imgur.com/ziSqeSo.png/" width="156" height="28"></a></p>
<h6><a href="https://store.ramotion.com/product/iphone-x-clay-mockups?utm_source=gthb&utm_medium=special&utm_campaign=circular-carousel#demo">Get Free Mockup For your project →</a></h6>

</br>

[![CocoaPods](https://img.shields.io/cocoapods/p/FoldingCell.svg)](https://cocoapods.org/pods/FoldingCell)
[![CocoaPods](https://img.shields.io/cocoapods/v/FoldingCell.svg)](http://cocoapods.org/pods/FoldingCell)
[![Twitter](https://img.shields.io/badge/Twitter-@Ramotion-blue.svg?style=flat)](http://twitter.com/Ramotion)
<!--[![Travis](https://img.shields.io/travis/Ramotion/folding-cell.svg)](https://travis-ci.org/Ramotion/folding-cell)
[![codebeat badge](https://codebeat.co/badges/6f67da5d-c416-4bac-9fb7-c2dc938feedc)](https://codebeat.co/projects/github-com-ramotion-folding-cell)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Swift 4.0](https://img.shields.io/badge/Swift-4.0-green.svg?style=flat)](https://developer.apple.com/swift/)
[![Analytics](https://ga-beacon.appspot.com/UA-84973210-1/ramotion/folding-cell)](https://github.com/igrigorik/ga-beacon)!-->
[![Donate](https://img.shields.io/badge/Donate-PayPal-blue.svg)](https://paypal.me/Ramotion)

## Requirements

- iOS 12.0+
- Xcode 10.2+
- Swift 5.0+

## Installation

Just add the CircularCarousel directory to your project.

or use [CocoaPods](https://cocoapods.org) with Podfile:
```
pod 'CircularCarousel'
```

or just drag and drop the CircularCarousel directory to your project

## Solution
![Solution](https://raw.githubusercontent.com/Ramotion/folding-cell/master/Tutorial-resources/Solution.png)
## Usage

1) Create a custom view that will be used as a carousel item. In this tutorial we will just use a blank UIView.

2) Create a view controller or container view that handles datasource and delegate responses for the contained Carousel. 

```
	final class ContainerView : UITableViewCell, CircularCarouselDataSource, CircularCarouselDelegate {

	}
```

2.1) Add a reference to the carousel control and the selection of a delegate and datasource to your Carousel control.
``` 
	private weak var _carousel : CircularCarousel!
    @IBOutlet var carousel : CircularCarousel! {
        set {
            _carousel = newValue
            _carousel.delegate = self
            _carousel.dataSource = self
        }
        
        get {
            return _carousel
        }
    }
```

3) Implement the DataSource and Delegate functions. Some of the key functions are listed below.

3.1) Datasource 

```
	func numberOfItems(inCarousel carousel: CircularCarousel) -> Int {
        return /* Number of carousel items */
    }
```

```
	func carousel(_: CircularCarousel, viewForItemAt indexPath: IndexPath, reuseView view: UIView?) -> UIView {
    	var view = view as? UIVIew

    	if view == nil {
    		view = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
    	}

    	return view
    }
```

``` 
	func startingItemIndex(inCarousel carousel: CircularCarousel) -> Int {
        return /* Insert starting item index */
    }
```

3.2) Delegate

Select how you want the carousel to operate based on the control variables specified below :
```
	func carousel<CGFloat>(_ carousel: CircularCarousel, valueForOption option: CircularCarouselOption, withDefaultValue defaultValue: CGFloat) -> CGFloat {
	    switch option {
        case .itemWidth:
            return /* Select item width for carousel */
        /*  Insert one of the following handlers :
			case spacing
			case fadeMin
			case fadeMax
			case fadeRange
			case fadeMinAlpha
			case offsetMultiplier
			case itemWidth
			case scaleMultiplier
			case minScale
			case maxScale
        */
        default:
            return defaultValue
        }
	}
```

Handle the selection of a particular carousel item :
```
	func carousel(_ carousel: CircularCarousel, didSelectItemAtIndex index: Int) {
        /* Handle selection of the selected carousel item */
    }
```

Handle will begin scrolling :
```
	func carousel(_ carousel: CircularCarousel, willBeginScrollingToIndex index: Int) {

	}
```

To handle spacing between items depending on their offst from the center : 
```
	func carousel(_ carousel: CircularCarousel, spacingForOffset offset: CGFloat) -> CGFloat {        
        return /* Based on the offset from center, adjust the spacing of the item */
    }
```

<!--![1.1](https://raw.githubusercontent.com/Ramotion/folding-cell/master/Tutorial-resources/1.1.png)-->

<!--![1.2](https://raw.githubusercontent.com/Ramotion/folding-cell/master/Tutorial-resources/1.2.png)

Your result should be something like this picture:

![1.3](https://raw.githubusercontent.com/Ramotion/folding-cell/master/Tutorial-resources/1.3.png)-->

That's it, the Carousel is good to go!

## 📄 License

Carousel is released under the MIT license.
See [LICENSE](./LICENSE) for details.

This library is a part of a <a href="https://github.com/Ramotion/swift-ui-animation-components-and-libraries"><b>selection of our best UI open-source projects.</b></a>

If you use the open-source library in your project, please make sure to credit and backlink to www.ramotion.com

## 📱 Get the Showroom App for iOS to give it a try
Try this UI component and more like this in our iOS app. Contact us if interested.

<a href="https://itunes.apple.com/app/apple-store/id1182360240?pt=550053&ct=folding-cell&mt=8" >
<img src="https://github.com/ramotion/gliding-collection/raw/master/app_store@2x.png" width="117" height="34"></a>

<a href="https://dev.ramotion.com?utm_source=gthb&utm_medium=repo&utm_campaign=folding-cell">
<img src="https://github.com/ramotion/gliding-collection/raw/master/contact_our_team@2x.png" width="187" height="34"></a>
