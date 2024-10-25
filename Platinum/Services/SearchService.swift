//
//  SearchService.swift
//  Platinum
//
//  Created by Larry Shannon on 10/24/24.
//

import Foundation

class SearchService: ObservableObject {
    static let shared = SearchService()
    
    @Published var searchText = ""
    
    
}
