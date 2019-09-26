//
//  ViewController.swift
//  BPNFCDemo
//
//  Created by baipeng on 2019/9/26.
//  Copyright © 2019 Apple Inc. All rights reserved.
//

import UIKit
import CoreNFC
import PassKit

class ViewController: UIViewController,NFCNDEFReaderSessionDelegate ,PKAddPassesViewControllerDelegate{

	@IBOutlet weak var messageLabel: UILabel!
	var nfcSession:NFCNDEFReaderSession?

	var passToAdd = PKPass()
	let passLibrary = PKPassLibrary()

	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.

	}

	@IBAction func scanPressed(_ sender: Any) {
		nfcSession = NFCNDEFReaderSession.init(delegate: self, queue: DispatchQueue.main, invalidateAfterFirstRead: true)
		nfcSession?.begin()
		
		print("开始扫描")
	}

	//添加钱包卡片
	@IBAction func addWalletBtn(_ sender: Any)   {
		 NSLog("------")
		 showWalletPass(fileName: "Lollipop")
	 }

	 //显示票据
	 func showWalletPass(fileName: String)  {
		 guard PKPassLibrary.isPassLibraryAvailable() else {
			 showAlert(message: "您的设备不支持wallet")
			 return
		 }

		 guard let fileUrl = Bundle.main.url(forResource: fileName, withExtension: "pkpass") else {
			 showAlert(message: "未找到票据凭证")

			 return
		 }

		 guard let passData = try? Data.init(contentsOf: fileUrl) else {
			 showAlert(message: "未找到票据证据")
			 return
		 }



		var error: Error? = nil
		var pass: PKPass? = nil
		do {
			pass = try PKPass(data: passData)
		} catch {
		}
		if error != nil {
			showAlert(message: "\(String(describing: error?.localizedDescription))")
			return
		}

		if PKAddPassesViewController.canAddPasses()
		 {
			showPass(pass: pass!)
		 }
		 else
		 {
			 showAlert(message: "设备不支持wallet")
		 }
	 }


	 //提示信息
	 func showAlert(message: String) {
		let alertVc = UIAlertController.init(title: "提示", message: message, preferredStyle: UIAlertController.Style.alert)
		let actionConfirm = UIAlertAction.init(title: "确定", style: UIAlertAction.Style.default) { _ in
		 }
		 alertVc.addAction(actionConfirm)
		 self.present(alertVc, animated: true, completion: nil)
	 }

	 //显示凭证信息
	 func showPass(pass: PKPass)  {
		 if passLibrary.containsPass(pass) {
			 showAlert(message: "凭证已经添加")
			 return
		 }
		 passToAdd = pass
		 let addPassVc = PKAddPassesViewController(pass: pass)
		addPassVc?.delegate = self
		 self.present(addPassVc!, animated: true, completion: nil)
	 }

	 func addfinish(message: String)  {
		 //guard let守护一定有值。如果没有，直接返回
		 guard passLibrary.containsPass(passToAdd) else {
			 return
		 }

		let actionConfirm = UIAlertAction.init(title: "查看", style: UIAlertAction.Style.default) { [ weak self] _ in
			 guard let passURL = self?.passToAdd.passURL else
			 {
				 return
			 }

			 if UIApplication.shared.canOpenURL(passURL) {
				 UIApplication.shared.open(passURL, options: [:], completionHandler: { _ in

				 })
			 }
		 }

		let actionCancel = UIAlertAction.init(title: "取消", style: UIAlertAction.Style.default, handler: nil)

		let alertVc = UIAlertController.init(title: "提示", message: message, preferredStyle: UIAlertController.Style.alert)
		 alertVc.addAction(actionConfirm)
		 alertVc.addAction(actionCancel)
		 self.present(alertVc, animated: true, completion: nil)

	 }


	///PKAddPassesViewControllerDelegate
	func addPassesViewControllerDidFinish(_ controller: PKAddPassesViewController) {
		   controller.dismiss(animated: true) { [weak self] in
			   guard let strongSelf = self else {
				   return
			   }
			   strongSelf.addfinish(message: "添加完成")

		   }
	   }


	///NFCNDEFReaderSessionDelegate
	public func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        print("The session was invalidated: \(error.localizedDescription)")
	}

	public func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
		print(messages)

		
	}
	@available(iOS 13.0, *)
	func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
		print(session.alertMessage)
	}

	@available(iOS 13.0, *)
	func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
		 print("ddd")
	}

}

