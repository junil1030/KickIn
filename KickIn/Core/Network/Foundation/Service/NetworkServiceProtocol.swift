//
//  NetworkServiceProtocol.swift
//  KickIn
//
//  Created by 서준일 on 12/16/25.
//

import Foundation

protocol NetworkServiceProtocol {
    func request<T: Decodable>(_ router: any APIRouter) async throws -> T
    func request(_ router: any APIRouter) async throws
    func upload<T: Decodable>(_ router: any APIRouter, files: [(data: Data, name: String, fileName: String, mimeType: String)]) async throws -> T
    func uploadWithProgress<T: Decodable>(
        _ router: any APIRouter,
        files: [(data: Data, name: String, fileName: String, mimeType: String)],
        progressHandler: @escaping (Double) -> Void
    ) async throws -> T
}
