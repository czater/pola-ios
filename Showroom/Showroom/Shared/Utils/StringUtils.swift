import Foundation
import UIKit
import CocoaMarkdown

extension String {
    func heightWithConstrainedWidth(width: CGFloat, font: UIFont, numberOfLines: Int = 0) -> CGFloat {
        let constraintRect = CGSize(width: width, height: CGFloat.max)
        
        let boundingBox = self.boundingRectWithSize(constraintRect, options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: [NSFontAttributeName: font], context: nil)
        if numberOfLines == 0 {
            return boundingBox.height
        }
        
        return min(boundingBox.height, CGFloat(numberOfLines) * font.lineHeight)
    }
    
    var strikethroughString: NSMutableAttributedString {
        return NSMutableAttributedString(string: self, attributes: [NSStrikethroughStyleAttributeName: NSUnderlineStyle.StyleSingle.rawValue])
    }

    func stringWithStrikethroughBasePrice(basePrice: String, kern: Double? = nil) -> NSAttributedString {
        let string = self as NSString
        let range = string.rangeOfString(basePrice)
        let attributedString = NSMutableAttributedString(string: self)
        attributedString.addAttribute(NSStrikethroughStyleAttributeName, value: NSUnderlineStyle.StyleSingle.rawValue, range: range)
        attributedString.addAttribute(NSFontAttributeName, value: UIFont(fontType: .ProductListText), range: range)
        attributedString.addAttribute(NSForegroundColorAttributeName, value: UIColor(named: .DarkGray), range: range)
        if let kern = kern {
            attributedString.addAttribute(NSKernAttributeName, value: kern, range: range)
        }
        return attributedString
    }
    
    func stringWithHighlightedSubsttring(substring: String) -> NSMutableAttributedString {
        let string = self as NSString
        let range = string.rangeOfString(substring)
        let attributedString = NSMutableAttributedString(string: self)
        attributedString.addAttribute(NSForegroundColorAttributeName, value: UIColor(named: .Blue), range: range)
        return attributedString
    }
    
    func markdownToAttributedString(treatBoldAsNormalText treatBoldAsNormalText: Bool = false) -> NSAttributedString {
        let normalFont = UIFont(fontType: .Normal)
        let boldFont = UIFont(fontType: .NormalBold)
        
        let textAttributes = CMTextAttributes()
        textAttributes.textAttributes = [NSFontAttributeName: normalFont]
        textAttributes.strongAttributes = [NSFontAttributeName: treatBoldAsNormalText ? normalFont : boldFont]
        textAttributes.linkAttributes = [
            NSFontAttributeName: normalFont
        ]
        
        let document = CMDocument(data: dataUsingEncoding(NSUTF8StringEncoding), options: CMDocumentOptions())
        let renderer = CMAttributedStringRenderer(document: document, attributes: textAttributes)
        return renderer.render()
    }
}