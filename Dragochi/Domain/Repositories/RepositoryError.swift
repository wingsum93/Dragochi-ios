//
//  RepositoryError.swift
//  Dragochi
//
//  Created by Codex on 12/2/2026.
//

import Foundation

enum RepositoryError: Error, Equatable {
    case notFound
    case invalidPlatformRawValue(String)
    case constraint(String)
}

