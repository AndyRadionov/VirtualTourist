//
//  UiViewController+Alert.swift
//  VirtualTourist
//
//  Created by Andy on 23.05.2020.
//  Copyright © 2020 AndyRadionov. All rights reserved.
//

import UIKit

extension UIViewController {
    
    func showErrorAlert(_ error: ApiClient.ApiError, _ presenter: UIViewController) {
        showAlert(title: "Error", message: error.localizedDescription, presenter: presenter)
    }
    
    func showAlert(title: String, message: String, presenter: UIViewController) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { action in
                alert.dismiss(animated: true, completion: nil)
            }))
            presenter.present(alert, animated: true)
        }
    }
}
