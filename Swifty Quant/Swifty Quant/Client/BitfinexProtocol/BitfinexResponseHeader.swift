//
//  BitfinexResponse.swift
//  Swifty Quant
//
//  Created by Cameron de Bruyn on 2020/08/02.
//  Copyright © 2020 HINTON AI (PTY) LTD. All rights reserved.
//

import Foundation


public struct BitfinexResponseHeader
{
    public let status: StatusCode
    public let meta: String
}

public extension BitfinexResponseHeader
{
    enum StatusCode: Int
    {
        // All statuses and subtypes
        case input                      = 10
        case sensitiveInput             = 11
        case success                    = 20
        case temporaryRedirect          = 30
        case permanentRedirect          = 31
        case temporaryFailure           = 40
        case serverUnavailable          = 41
        case cgiError                   = 42
        case proxyError                 = 43
        case slowDown                   = 44
        case permanentFailure           = 50
        case notFound                   = 51
        case gone                       = 52
        case proxyRequestRefused        = 53
        case badRequest                 = 59
        case clientCertificateRequested = 60
        case certificateNotAuthorised   = 61
        case certificateNotValid        = 62
        
        // Status type helpers
        public var isInput:                     Bool { rawValue / 10 == 1 }
        public var isSuccess:                   Bool { rawValue / 10 == 2 }
        public var isRedirect:                  Bool { rawValue / 10 == 3 }
        public var isTemporaryFailure:          Bool { rawValue / 10 == 4 }
        public var isPermanentFailure:          Bool { rawValue / 10 == 5 }
        public var isClientCertificateRequired: Bool { rawValue / 10 == 6 }
        
        // Other helpers
        public var isFailure: Bool { isTemporaryFailure || isPermanentFailure }
    }
}

extension BitfinexResponseHeader.StatusCode: CustomStringConvertible
{
    public var description: String
    {
        switch self
        {
        case .input:
            return "\(rawValue): input"
        case .sensitiveInput:
            return "\(rawValue): sensitiveInput"
        case .success:
            return "\(rawValue): success"
        case .temporaryRedirect:
            return "\(rawValue): temporaryRedirect"
        case .permanentRedirect:
            return "\(rawValue): permanentRedirect"
        case .temporaryFailure:
            return "\(rawValue): temporaryFailure"
        case .serverUnavailable:
            return "\(rawValue): serverUnavailable"
        case .cgiError:
            return "\(rawValue): cgiError"
        case .proxyError:
            return "\(rawValue): proxyError"
        case .slowDown:
            return "\(rawValue): slowDown"
        case .permanentFailure:
            return "\(rawValue): permanentFailure"
        case .notFound:
            return "\(rawValue): notFound"
        case .gone:
            return "\(rawValue): gone"
        case .proxyRequestRefused:
            return "\(rawValue): proxyRequestRefused"
        case .badRequest:
            return "\(rawValue): badRequest"
        case .clientCertificateRequested:
            return "\(rawValue): clientCertificateRequested"
        case .certificateNotAuthorised:
            return "\(rawValue): certificateNotAuthorised"
        case .certificateNotValid:
            return "\(rawValue): certificateNotValid"
        }
    }
}
