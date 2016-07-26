//
//  DopamineSyncer.swift
//  Pods
//
//  Created by Akash Desai on 7/25/16.
//
//

import Foundation


enum SyncState {
    case READY, SYNCING, STORING, REMOVING
}

protocol DopamineSyncer {
    var state:SyncState { get set }
//    var previousState:SyncState { get set }
}