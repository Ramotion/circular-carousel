<img src="https://github.com/Ramotion/folding-cell/blob/master/header.png">

<a href="https://github.com/Ramotion/folding-cell">
<img align="left" src="https://github.com/Ramotion/folding-cell/blob/master/Screenshots/foldingCell.gif" width="480" height="360" /></a>

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
<h6><a href="https://store.ramotion.com/product/iphone-x-clay-mockups?utm_source=gthb&utm_medium=special&utm_campaign=folding-cell#demo">Get Free Mockup For your project →</a></h6>

</br>

[![CocoaPods](https://img.shields.io/cocoapods/p/FoldingCell.svg)](https://cocoapods.org/pods/FoldingCell)
[![CocoaPods](https://img.shields.io/cocoapods/v/FoldingCell.svg)](http://cocoapods.org/pods/FoldingCell)
[![Twitter](https://img.shields.io/badge/Twitter-@Ramotion-blue.svg?style=flat)](http://twitter.com/Ramotion)
[![Travis](https://img.shields.io/travis/Ramotion/folding-cell.svg)](https://travis-ci.org/Ramotion/folding-cell)
[![codebeat badge](https://codebeat.co/badges/6f67da5d-c416-4bac-9fb7-c2dc938feedc)](https://codebeat.co/projects/github-com-ramotion-folding-cell)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Swift 4.0](https://img.shields.io/badge/Swift-4.0-green.svg?style=flat)](https://developer.apple.com/swift/)
[![Analytics](https://ga-beacon.appspot.com/UA-84973210-1/ramotion/folding-cell)](https://github.com/igrigorik/ga-beacon)
[![Donate](https://img.shields.io/badge/Donate-PayPal-blue.svg)](https://paypal.me/Ramotion)

## Requirements

- iOS 8.0+
- Xcode 9.0+

## Installation

Just add the RACarousel directory to your project.

or use [CocoaPods](https://cocoapods.org) with Podfile:
```
pod 'RACarousel'
```
or [Carthage](https://github.com/Carthage/Carthage) users can simply add Mantle to their `Cartfile`:
```
github "Ramotion/ra-carousel"
```

or just drag and drop the RACarousel directory to your project

## Solution
![Solution](https://raw.githubusercontent.com/Ramotion/folding-cell/master/Tutorial-resources/Solution.png)
## Usage

1) Create a custom view that will be used as a carousel item.

2) Create a view controller or container view that handles datasource and delegate responses for the contained Carousel. 

2.1) Add the selection of a delegate and datasource to your Carousel control.
``` private weak var _carousel : RACarousel!
    @IBOutlet var carousel : RACarousel! {
        set {
            _carousel = newValue
            _carousel.delegate = self
            _carousel.dataSource = self
        }
        
        get {
            return _carousel
        }
    }```

![1.1](https://raw.githubusercontent.com/Ramotion/folding-cell/master/Tutorial-resources/1.1.png)

3) Select how you want the carousel to operate based on the control variables specified below :

![1.2](https://raw.githubusercontent.com/Ramotion/folding-cell/master/Tutorial-resources/1.2.png)

Your result should be something like this picture:

![1.3](https://raw.githubusercontent.com/Ramotion/folding-cell/master/Tutorial-resources/1.3.png)


4) Specify the control variables in interface builder.

4.1) Add the delegate method to provide values to the Carousel from the container view or controller.

That's it, the Carousel is good to go.

``` swift
fileprivate struct C {
  struct CellHeight {
    static let close: CGFloat = *** // equal or greater foregroundView height
    static let open: CGFloat = *** // equal or greater containerView height
  }
}
```

5.2) Add property for calculate cells height

``` swift
     var cellHeights = (0..<CELLCOUNT).map { _ in C.CellHeight.close }
```

5.3) Override method:
``` swift
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return cellHeights[indexPath.row]
    }
```

5.4) Added code to method:
``` swift
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        guard case let cell as FoldingCell = tableView.cellForRowAtIndexPath(indexPath) else {
          return
        }

        var duration = 0.0
        if cellIsCollapsed {
            cellHeights[indexPath.row] = Const.openCellHeight
            cell.unfold(true, animated: true, completion: nil)
            duration = 0.5
        } else {
            cellHeights[indexPath.row] = Const.closeCellHeight
            cell.unfold(false, animated: true, completion: nil)
            duration = 0.8
        }

        UIView.animateWithDuration(duration, delay: 0, options: .CurveEaseOut, animations: { _ in
            tableView.beginUpdates()
            tableView.endUpdates()
        }, completion: nil)
    }
```
5.5) Control if the cell is open or closed
``` swift
  override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {

        if case let cell as FoldingCell = cell {
            if cellHeights![indexPath.row] == C.cellHeights.close {
                foldingCell.selectedAnimation(false, animated: false, completion:nil)
            } else {
                foldingCell.selectedAnimation(true, animated: false, completion: nil)
            }
        }
    }
```

6) Add this code to your new cell class
``` swift
    override func animationDuration(itemIndex:NSInteger, type:AnimationType)-> NSTimeInterval {

        // durations count equal it itemCount
        let durations = [0.33, 0.26, 0.26] // timing animation for each view
        return durations[itemIndex]
    }
```

## if don't use storyboard and xib files

Create foregroundView and containerView from code (steps 2 - 3) look example:
[Folding-cell-programmatically](https://github.com/ober01/Folding-cell-programmatically)

## 🗂 Check this library on other language:
<a href="https://github.com/Ramotion/folding-cell-android">
<img src="https://github.com/ramotion/navigation-stack/raw/master/Android_Java@2x.png" width="178" height="81"></a>


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
