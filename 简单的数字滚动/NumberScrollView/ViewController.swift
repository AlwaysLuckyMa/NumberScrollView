//
//  ViewController.swift
//  NumberScrollView
//
//  Created by satoshi_umaM1 on 2023/10/27.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet var priceL: UILabel!
    var startPrice: CGFloat = 0.0
    var endPrice: CGFloat = 1800000.25
    private var animationDuration: TimeInterval = 0.5 // 总时间
    private var startTime: TimeInterval = 0.0
    private var displayLink: CADisplayLink?
    private var incrementPerFrame: CGFloat = 1.0 // 调整递增的幅度

    override func viewDidLoad() {
        super.viewDidLoad()
        startPriceAnimation()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        priceL.text = "0.00"
        startPriceAnimation()
    }

    func startPriceAnimation() {
        startTime = CACurrentMediaTime()
        displayLink = CADisplayLink(target: self, selector: #selector(updatePrice))
        displayLink?.add(to: .main, forMode: .common)
    }

    @objc func updatePrice() {
        let currentTime = CACurrentMediaTime()
        let elapsedTime = currentTime - startTime

        if elapsedTime >= animationDuration {
            startPrice = endPrice
        } else {
            let progress = elapsedTime / animationDuration
            startPrice = CGFloat(progress) * endPrice
        }
        priceL.text = formattedPrice(startPrice)

        if startPrice < endPrice {
            startPrice += incrementPerFrame
            if startPrice > endPrice {
                startPrice = endPrice
            }
        } else {
            displayLink?.invalidate()
        }
    }

    func formattedPrice(_ price: CGFloat) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.minimumFractionDigits = 2
        numberFormatter.maximumFractionDigits = 2
        return (numberFormatter.string(from: NSNumber(value: price)) ?? "0.00")
    }
}
