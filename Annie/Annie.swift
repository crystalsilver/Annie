//
//  Annie.swift
//  Annie
//
//  Created by skyline on 15/1/6.
//  Copyright (c) 2015年 skyline. All rights reserved.
//

import Foundation

func escape(var text: String, quote: Bool=false, smart_amp: Bool=true) -> String {
    
    let escapeRegex = try! NSRegularExpression(pattern: "&(?!#?\\w+;)", options: NSRegularExpressionOptions.CaseInsensitive)
    
    if smart_amp {
        text = escapeRegex.stringByReplacingMatchesInString(text, options: NSMatchingOptions.ReportProgress, range: NSMakeRange(0, text.length), withTemplate: "&amp;")
    } else {
        text = text.stringByReplacingOccurrencesOfString("&", withString: "&amp;", options: NSStringCompareOptions.LiteralSearch, range: nil)
    }
    
    text = text.stringByReplacingOccurrencesOfString("<", withString: "&lt;", options: NSStringCompareOptions.LiteralSearch, range: nil)
    text = text.stringByReplacingOccurrencesOfString(">", withString: "&gt;", options: NSStringCompareOptions.LiteralSearch, range: nil)
    if quote {
        text = text.stringByReplacingOccurrencesOfString("\"", withString: "&quot;", options: NSStringCompareOptions.LiteralSearch, range: nil)
        text = text.stringByReplacingOccurrencesOfString("'", withString: "&#39;", options: NSStringCompareOptions.LiteralSearch, range: nil)
    }
    return text
}

func preprocessing(var text:String, tab: Int=4) -> String {
    let newlineRegex = try! NSRegularExpression(pattern: "\\r\\n|\\r", options: NSRegularExpressionOptions.CaseInsensitive)
    text = newlineRegex.stringByReplacingMatchesInString(text, options: NSMatchingOptions.ReportProgress, range: NSMakeRange(0, text.length), withTemplate: "\n")
    text = text.stringByReplacingOccurrencesOfString("\t", withString: " ".repeatString(tab))
    text = text.stringByReplacingOccurrencesOfString("\u{00a0}", withString: "")
    text = text.stringByReplacingOccurrencesOfString("\u{2424}", withString: "\n")
    
    let leadingSpaceRegex = try! NSRegularExpression(pattern: "^ +$", options: NSRegularExpressionOptions.AnchorsMatchLines)
    text = leadingSpaceRegex.stringByReplacingMatchesInString(text, options: NSMatchingOptions.ReportProgress, range: NSMakeRange(0, text.length), withTemplate: "")
    return text
}

func trimWhitespace(text: String) -> String {
    let regex = try! NSRegularExpression(pattern: "\\s", options: NSRegularExpressionOptions.CaseInsensitive)
    return regex.stringByReplacingMatchesInString(text, options: NSMatchingOptions.ReportProgress, range: NSMakeRange(0, text.length), withTemplate: "")
}

func getPurePattern(pattern:String) -> String {
    var p = pattern
    if pattern.hasPrefix("^") {
        p = pattern.substringFromIndex(pattern.startIndex.advancedBy(1))
    }
    return p
}

func keyify(key: String) -> String {
    let keyWhiteSpaceRegex = try! NSRegularExpression(pattern: "\\s+", options: NSRegularExpressionOptions.CaseInsensitive)
    return keyWhiteSpaceRegex.stringByReplacingMatchesInString(key.lowercaseString, options: NSMatchingOptions.ReportProgress, range: NSMakeRange(0, key.length), withTemplate: " ")
}

class BlockParser {
    var definedLinks = [String:[String:String]]()
    var tokens = [TokenBase]()
    var grammarRegexMap = [String:Regex]()
    
    let defaultRules = ["newline", "hrule", "block_code", "fences", "heading",
        "nptable", "lheading", "block_quote",
        "list_block", "block_html", "def_links",
        "def_footnotes", "table", "paragraph", "text"]
    
    let listRules = ["newline", "block_code", "fences", "lheading", "hrule",
        "block_quote", "list_block", "block_html", "text",]
    
    init() {
        let def_links_regex = "^ *\\[([^^\\]]+)\\]: *<?([^\\s>]+)>?(?: +[\"(]([^\n]+)[\")])? *(?:\n+|$)"
        let def_footnotes_regex = "^\\[\\^([^\\]]+)\\]: *([^\n]*(?:\n+|$)(?: {1,}[^\n]*(?:\n+|$))*)"
        let newline_regex = "^\n+"
        let heading_regex = "^ *(#{1,6}) *([^\n]+?) *#* *(?:\n+|$)"
        let lheading_regex = "^([^\n]+)\n *(=|-)+ *(?:\n+|$)"
        let fences_regex = "^ *(`{3,}|~{3,}) *(\\S+)? *\n([\\s\\S]+?)\\s\\1 *(?:\\n+|$)"
        let block_code_regex = "^( {4}[^\n]+\n*)+"
        let hrule_regex = "^ {0,3}[-*_](?: *[-*_]){2,} *(?:\n+|$)"
        let block_quote_regex = "^( *>[^\n]+(\n[^\n]+)*\n*)+"
        
        let list_block_regex = String(format: "^( *)([*+-]|\\d+\\.) [\\s\\S]+?(?:\\n+(?=\\1?(?:[-*_] *){3,}(?:\\n+|$))|\\n+(?=%@)|\\n{2,}(?! )(?!\\1(?:[*+-]|\\d+\\.) )\\n*|\\s*$)", def_links_regex)
        
        let list_item_regex = "^(( *)(?:[*+-]|\\d+\\.) [^\\n]*(?:\\n(?!\\2(?:[*+-]|\\d+\\.) )[^\\n]*)*)"
        let list_bullet_regex = "^ *(?:[*+-]|\\d+\\.) +"
        
        let paragraph_regex = String(format: "^((?:[^\\n]+\\n?(?!%@|%@|%@|%@|%@|%@|%@))+)\\n*",  getPurePattern(fences_regex).stringByReplacingOccurrencesOfString("\\1", withString: "\\2"), getPurePattern(list_block_regex).stringByReplacingOccurrencesOfString("\\1", withString: "\\3"), getPurePattern(hrule_regex), getPurePattern(heading_regex), getPurePattern(lheading_regex), getPurePattern(block_quote_regex), getPurePattern(def_links_regex))
        
        let text_regex = "^[^\n]+"
        
        //let def_footnotes_regex = self.grammarRegexMap["def_footnotes"]!
        
        addGrammar("def_links", regex: Regex(pattern: def_links_regex))
        addGrammar("def_footnotes", regex: Regex(pattern:def_footnotes_regex))
        addGrammar("newline", regex: Regex(pattern: newline_regex))
        addGrammar("heading", regex: Regex(pattern: heading_regex))
        addGrammar("lheading", regex: Regex(pattern: lheading_regex))
        addGrammar("fences", regex: Regex(pattern: fences_regex))
        addGrammar("block_code", regex: Regex(pattern: block_code_regex))
        addGrammar("hrule", regex: Regex(pattern: hrule_regex))
        addGrammar("block_quote", regex: Regex(pattern: block_quote_regex))
        
        
        addGrammar("list_block", regex: Regex(pattern: list_block_regex))
        addGrammar("list_item", regex: Regex(pattern: list_item_regex, options: NSRegularExpressionOptions.AnchorsMatchLines))
        addGrammar("list_bullet", regex: Regex(pattern: list_bullet_regex))
        addGrammar("paragraph", regex: Regex(pattern: paragraph_regex))
        addGrammar("text", regex: Regex(pattern: text_regex))
    }
    
    func addGrammar(name:String, regex:Regex) {
        grammarRegexMap[name] = regex
    }
    
    func forward(inout text:String, length:Int) {
        text.removeRange(Range<String.Index>(start: text.startIndex, end: text.startIndex.advancedBy(length)))
    }
    
    func parse(var text:String, rules: [String] = []) -> [TokenBase]{
        while !text.isEmpty {
            let token = getNextToken(text, rules: rules)
            tokens.append(token.token)
            forward(&text, length:token.length)
        }
        return tokens
    }
    
    func chooseParseFunction(name:String) -> (RegexMatch) -> TokenBase {
        switch name {
        case "newline":
            return parseNewline
        case "heading":
            return parseHeading
        case "lheading":
            return parseLHeading
        case "fences":
            return parseFences
        case "block_code":
            return parseBlockCode
        case "hrule":
            return parseHRule
        case "block_quote":
            return parseBlockQuote
        case "paragraph":
            return parseParagraph
        case "text":
            return parseText
        default:
            return parseText
        }
    }
    
    func getNextToken(text:String, var rules: [String]) -> (token:TokenBase, length:Int) {
        if rules.isEmpty {
            rules = defaultRules
        }
        for rule in rules {
            if let regex  = grammarRegexMap[rule] {
                if let m = regex.match(text) {
                    let forwardLength = m.group(0).length
                    
                    // Special case
                    if rule == "def_links" {
                        parseDefLinks(m)
                        return (TokenNone(), forwardLength)
                    }
                    
                    if rule == "list_block" {
                        parseListBlock(m)
                        return (TokenNone(), forwardLength)
                    }
                    
                    let parseFunction = chooseParseFunction(rule)
                    let tokenResult = parseFunction(m)
                    return (tokenResult, forwardLength)
                }
            }
        }
        // Move one character. Otherwise may case infinate loop
        return (TokenBase(type: " ", text: text.substringToIndex(text.startIndex.advancedBy(1))), 1)
    }
    
    func parseNewline(m: RegexMatch) -> TokenBase {
        let length = m.group(0).length
        if length > 1 {
            return NewLine()
        }
        return TokenNone()
    }
    func parseHeading(m: RegexMatch) -> TokenBase {
        return Heading(text: m.group(2), level: m.group(1).length)
    }
    
    func parseLHeading(m: RegexMatch) -> TokenBase {
        let level = m.group(2) == "=" ? 1 : 2;
        return Heading(text: m.group(1), level: level)
    }
    
    func parseFences(m: RegexMatch) -> TokenBase {
        return BlockCode(text: m.group(3), lang: m.group(2))
    }
    
    func parseBlockCode(m: RegexMatch) -> TokenBase {
        var code = String(m.group(0))
        let pattern = Regex(pattern: "^ {4}")
        if let match = pattern.match(code) {
            code.removeRange(match.range())
        }
        return BlockCode(text: code, lang: "")
    }
    
    func parseHRule(m: RegexMatch) -> TokenBase {
        return HRule()
    }
    
    func parseBlockQuote(m: RegexMatch) -> TokenBase {
        let start = BlockQuote(type: "blockQuoteStart", text: "")
        tokens.append(start)
        let cap = m.group(0)
        
        let pattern = Regex(pattern: "^ *> ?")
        var newCap = ""
        
        // NSRegularExpressoin doesn't support replacement in multilines
        // We have to manually split the captured String into multiple lines
        let lines = cap.componentsSeparatedByString("\n")
        for (_, var everyMatch) in lines.enumerate() {
            if let match = pattern.match(everyMatch) {
                everyMatch.removeRange(match.range())
                newCap += everyMatch + "\n"
            }
        }
        self.parse(newCap)
        return BlockQuote(type: "blockQuoteEnd", text: "")
    }
    
    func parseListBlock(m: RegexMatch) {
        let bull = m.group(2)
        let ordered = bull.rangeOfString(".") != nil
        tokens.append(ListBlock(type: "listBlockStart", ordered: ordered))
        let caps = m._str.componentsSeparatedByString("\n")
        let loose_list_regex = Regex(pattern: "\\n\\n(?!\\s*$)")
        
        var loose = false
        if loose_list_regex.match(m._str) != nil {
            loose = true
        }
        for cap in caps {
            processListItem(cap, bull: bull, loose:loose)
        }
        tokens.append(ListBlock(type: "listBlockEnd", ordered: ordered))
    }
    
    func processListItem(cap: String, bull: String, loose: Bool=false) {
        if trimWhitespace(cap).isEmpty {
            return
        }
        let list_item_regex = self.grammarRegexMap["list_item"]!
        
        if let caps = list_item_regex.match(cap) {
            var text = caps.group(0)
            let list_bullet_regex = self.grammarRegexMap["list_bullet"]!
            if let m = list_bullet_regex.match(text) {
                text.removeRange(m.range())
            }
            if loose {
                tokens.append(LooseListItem(type: "looseListItemStart"))
            } else {
                tokens.append(ListItem(type: "listItemStart"))
            }
            self.parse(text, rules: listRules)
        }
        if loose {
            tokens.append(LooseListItem(type: "looseListItemEnd"))
        } else {
            tokens.append(ListItem(type: "listItemEnd"))
        }
    }
    
    func parseDefLinks(m: RegexMatch) {
        let key = keyify(m.group(1))
        definedLinks[key] = [
            "link": m.group(2),
            "title": m.matchedString.count > 3 ? m.group(3) : ""
        ]
    }
    
    func parseParagraph(m: RegexMatch) -> TokenBase {
        let text = m.group(1)
        return Paragraph(text: text)
    }
    
    func parseText(m: RegexMatch) -> TokenBase {
        return TokenBase(type: "text", text: m.group(0))
    }
}

class InlineParser {
    var links = [String:[String:String]]()
    var grammarNameMap = [Regex:String]()
    var grammarList = [Regex]()
    var inLink = false
    
    init() {
        // Backslash escape
        addGrammar("escape", regex:Regex(pattern: "^\\\\([\\\\`*{}\\[\\]()#+\\-.!_>~|])")) // \* \+ \! ...
        addGrammar("autolink", regex: Regex(pattern :"^<([^ >]+(@|:\\/)[^ >]+)>"))
        addGrammar("url", regex: Regex(pattern :"^(https?:\\/\\/[^\\s<]+[^<.,:;\"\')\\]\\s])"))
        addGrammar("tag", regex: Regex(pattern: "^<!--[\\s\\S]*?-->|^<\\/\\w+>|^<\\w+[^>]*?>")) // html tag
        addGrammar("link", regex: Regex(pattern: "^!?\\[((?:\\[[^^\\]]*\\]|[^\\[\\]]|\\](?=[^\\[]*\\]))*)\\]\\(\\s*<?([\\s\\S]*?)>?(?:\\s+[\'\"]([\\s\\S]*?)[\'\"])?\\s*\\)"))
        addGrammar("reflink", regex: Regex(pattern: "^!?\\[((?:\\[[^^\\]]*\\]|[^\\[\\]]|\\](?=[^\\[]*\\]))*)\\]\\s*\\[([^^\\]]*)\\]"))
        addGrammar("nolink", regex: Regex(pattern: "^!?\\[((?:\\[[^\\]]*\\]|[^\\[\\]])*)\\]"))
        addGrammar("double_emphasis", regex: Regex(pattern: "^_{2}(.+?)_{2}(?!_)|^\\*{2}(.+?)\\*{2}(?!\\*)"))
        addGrammar("emphasis", regex: Regex(pattern: "^\\b_((?:__|.)+?)_\\b|^\\*((?:\\*\\*|.)+?)\\*(?!\\*)"))
        addGrammar("code", regex: Regex(pattern: "^(`+)\\s*(.*?[^`])\\s*\\1(?!`)"))
        addGrammar("linebreak", regex: Regex(pattern: "^ {2,}\\n(?!\\s*$)"))
        addGrammar("strikethrough", regex: Regex(pattern: "^~~(?=\\S)(.*?\\S)~~"))
        addGrammar("text", regex: Regex(pattern: "^[\\s\\S]+?(?=[\\\\<!\\[_*`~]|https?://| {2,}\n|$)"))
    }
    
    func addGrammar(name:String, regex:Regex) {
        grammarNameMap[regex] = name
        grammarList.append(regex)
    }
    
    func forward(inout text:String, length:Int) {
        text.removeRange(Range<String.Index>(start: text.startIndex, end: text.startIndex.advancedBy(length)))
    }
    
    func parse(inout text:String) {
        var result = ""
        while !text.isEmpty {
            let token = getNextToken(text)
            result += token.token.render()
            forward(&text, length:token.length)
        }
        text = result
    }
    
    
    func chooseOutputFunctionForGrammar(name:String) -> (RegexMatch) -> TokenBase {
        switch name {
        case "escape":
            return outputEscape
        case "autolink":
            return outputAutoLink
        case "link":
            return outputLink
        case "url":
            return outputURL
        case "tag":
            return outputTag
        case "reflink":
            return outputRefLink
        case "nolink":
            return outputNoLink
        case "double_emphasis":
            return outputDoubleEmphasis
        case "emphasis":
            return outputEmphasis
        case "code":
            return outputCode
        case "linebreak":
            return outputLineBreak
        case "strikethrough":
            return outputStrikeThrough
        case "text":
            return outputText
        default:
            return outputText
        }
    }
    
    func getNextToken(text:String) -> (token:TokenBase, length:Int) {
        for regex in grammarList {
            if let m = regex.match(text) {
                let name = grammarNameMap[regex]! // Name won't be nil
                let forwardLength = m.group(0).length
                
                let parseFunction = chooseOutputFunctionForGrammar(name)
                let tokenResult = parseFunction(m)
                if tokenResult is TokenNone {
                    continue
                }
                return (tokenResult, forwardLength)
            }
        }
        return (TokenBase(type: " ", text: text.substringToIndex(text.startIndex.advancedBy(1))) , 1)
    }
    
    func outputEscape(m: RegexMatch) -> TokenBase {
        return TokenBase(type: "text", text: m.group(1))
    }
    
    func outputAutoLink(m :RegexMatch) -> TokenBase {
        let link = m.group(1)
        var isEmail = false
        if m.group(2) == "@" {
            isEmail = true
        }
        return AutoLink(link: link, isEmail: isEmail)
    }
    func outputTag(m: RegexMatch) -> TokenBase {
        let text = m.group(0)
        let lowerText = text.lowercaseString
        if lowerText.hasPrefix("<a ") {
            self.inLink = true
        }
        if lowerText.hasPrefix("</a>") {
            self.inLink = false
        }
        return TokenBase(type: "tag", text: text)
    }
    
    func outputURL(m: RegexMatch) -> TokenBase {
        let link = m.group(1)
        if self.inLink {
            return TokenEscapedText(type: "text", text: link)
        } else {
            return AutoLink(link: link, isEmail: false)
        }
    }
    
    func outputLink(m: RegexMatch) -> TokenBase {
        return processLink(m, link: m.group(2), title: m.group(3))
    }
    
    func outputRefLink(m: RegexMatch) -> TokenBase {
        let key = keyify(m.group(2).isEmpty ? m.group(1) : m.group(2))
        if let ret = links[key] {
            // If links[key] exists, the link and title won't be nil
            // We can safely unwrap it
            return processLink(m, link: ret["link"]!, title: ret["title"]!)
        } else {
            return TokenNone()
        }
    }
    
    func outputNoLink(m: RegexMatch) -> TokenBase {
        let key = keyify(m.group(1))
        if let ret = self.links[key] {
            return processLink(m, link: ret["link"]!, title: ret["title"]!)
        } else {
            return TokenNone()
        }
    }
    
    func processLink(m: RegexMatch, link: String, title: String) -> TokenBase {
        let text = m.group(1)
        return Link(title: title, link: link, text: text)
    }
    
    func outputDoubleEmphasis(m: RegexMatch) -> TokenBase {
        var text = m.group(2).isEmpty ? m.group(1) : m.group(2)
        self.parse(&text)
        return DoubleEmphasis(text: text)
    }
    
    func outputEmphasis(m: RegexMatch) -> TokenBase {
        var text = m.group(2).isEmpty ? m.group(1) : m.group(2)
        self.parse(&text)
        return Emphasis(text: text)
    }
    
    func outputCode(m: RegexMatch) -> TokenBase {
        return InlineCode(text: m.group(2))
    }
    
    func outputLineBreak(m: RegexMatch) -> TokenBase {
        return LineBreak()
    }
    
    func outputStrikeThrough(m: RegexMatch) -> TokenBase {
        return StrikeThrough(text: m.group(1))
    }
    
    func outputText(m: RegexMatch) -> TokenBase {
        return TokenEscapedText(type: "text", text: m.group(0))
    }
}

let blockParser = BlockParser()
let inlineParser = InlineParser()

public func markdown(text:String) -> String {
    // Clean up
    blockParser.tokens = [TokenBase]()
    blockParser.definedLinks = [String:[String:String]]()
    inlineParser.links = [String:[String:String]]()
    return parse(text)
}

private func needInLineParsing(token: TokenBase) -> Bool {
    return token.type == "text" || token.type == "heading" || token.type == "paragraph"
}

private func parse(text:String) -> String {
    var result = String()
    let tokens = blockParser.parse(preprocessing(text))
    // Setup deflinks
    inlineParser.links = blockParser.definedLinks
    for token in tokens {
        if needInLineParsing(token) {
            inlineParser.parse(&token.text)
        }
        result += token.render()
    }
    return result
}


