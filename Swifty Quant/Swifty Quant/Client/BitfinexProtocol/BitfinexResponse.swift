//
//  BitfinexResponse.swift
//  Swifty Quant
//
//  Created by Cameron de Bruyn on 2020/08/02.
//  Copyright © 2020 HINTON AI (PTY) LTD. All rights reserved.
//

import Foundation
import UniformTypeIdentifiers


public struct GeminiResponse
{
    public let header: GeminiResponseHeader
    public let body: Data?
    
    public var status: GeminiResponseHeader.StatusCode { header.status }
    public var meta: String { header.meta }
    
    public var rawMimeType: String? {
        guard status.isSuccess else { return nil }
        return meta.trimmingCharacters(in: .whitespaces)
    }
    
    public var mimeType: String? {
        guard let rawMimeType = rawMimeType else { return nil }
        return rawMimeType.split(separator: ";").first?.trimmingCharacters(in: .whitespaces)
    }
    public var mimeTypeParameters: [String: String]? {
        guard let rawMimeType = rawMimeType else { return nil }
        return rawMimeType.split(separator: ";").dropFirst().reduce(into: [String: String]()) { (parameters, parameter) in
            let parts = parameter.split(separator: "=").map { $0.trimmingCharacters(in: .whitespaces) }
            precondition(parts.count == 2)
            parameters[parts[0].lowercased()] = parts[1]
        }
    }
    @available(macOS 10.16, iOS 14.0, *)
    public var utiType: UTType? {
        guard let mimeType = mimeType else { return nil }
        return UTType.types(tag: mimeType, tagClass: .mimeType, conformingTo: nil).first
    }
    
    public var bodyText: String? {
        guard let body = body, let parameters = mimeTypeParameters else { return nil }
        let encoding: String.Encoding
        switch parameters["charset"]?.lowercased() {
        case nil, "utf-8":
            // The Gemini spec defines UTF-8 to be the default charset.
            encoding = .utf8
        case "us-ascii":
            encoding = .ascii
        default:
            // todo: log warning
            encoding = .utf8
        }
        return String(data: body, encoding: encoding)
    }
}
