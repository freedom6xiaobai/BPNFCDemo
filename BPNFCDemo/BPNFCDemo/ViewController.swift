//
//  ViewController.swift
//  BPNFCDemo
//
//  Created by baipeng on 2019/9/26.
//  Copyright © 2019 Apple Inc. All rights reserved.
//

import UIKit
import CoreNFC


extension NFCTypeNameFormat: CustomStringConvertible{
	public var description: String {
		   switch self {
		   case .nfcWellKnown: return "NFC Well Known type"
		   case .media: return "Media type"
		   case .absoluteURI: return "Absolute URI type"
		   case .nfcExternal: return "NFC External type"
		   case .unknown: return "Unknown type"
		   case .unchanged: return "Unchanged type"
		   case .empty: return "Empty payload"
		   @unknown default: return "Invalid data"
		   }
	   }
}
@available(iOS 13.0, *)
class ViewController: UIViewController,NFCNDEFReaderSessionDelegate,UITableViewDelegate,UITableViewDataSource{

	@IBOutlet weak var tableView: UITableView!
	var dataArray = [NFCNDEFMessage]()
    var session: NFCNDEFReaderSession?
	@IBOutlet weak var inputText: UITextView!
	var isWrite:Bool = false//判断
    var ndefMessage: NFCNDEFMessage?//写入nfc



	//MARK: - life cyle 1、控制器生命周期
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.
		self.tableView.delegate = self
		self.tableView.dataSource = self
	}
	//MARK: - 2、不同业务处理之间的方法以

	//MARK: - Network 3、网络请求

	//MARK: - Action Event 4、响应事件
	@IBAction func scanPressed(_ sender: Any) {
		self.view.endEditing(true)
		guard NFCNDEFReaderSession.readingAvailable else {
			let alertVC = UIAlertController(title: "扫不到", message: "设备不支持", preferredStyle: UIAlertController.Style.alert)
			alertVC.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
			self.present(alertVC, animated: true, completion: nil)
			return
		}
		print(Thread.current)
		self.isWrite = false
		session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
		session?.alertMessage = "Hold your iPhone near an NDEF tag to write the message."
		session?.begin()
		print("开始扫描"+"\(self.isWrite)")
	}
	@IBAction func writeBtnAction(_ sender: UIButton) {
		self.view.endEditing(true)
		if self.inputText.text.description == ""{
			print("输入参数")
			return
		}
		print(Thread.current)
		self.isWrite = true
		session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
		session?.alertMessage = "Hold your iPhone near an NDEF tag to write the message."
		session?.begin()
		print("开始写入"+"\(self.isWrite)")
	}


	//MARK: - Call back 5、回调事件
	func tagRemovalDetect(_ tag: NFCNDEFTag) {//轮询查标签id
		session?.connect(to: tag) { (error: Error?) in
            if error != nil || !tag.isAvailable {
                print("Restart polling")
				self.session?.restartPolling()
                return
            }
            DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + .milliseconds(500), execute: {
				self.tagRemovalDetect(tag)
            })
        }
    }

	///MARK:创建nfc写入对象
    func createURLPayload() -> NFCNDEFPayload? {
		var dateString: String?
		var testString: String?
		 DispatchQueue.main.sync {
			 let dateFormatter = DateFormatter()
			 dateFormatter.dateFormat = "yyyyMMdd HH:mm:ss"
			 dateString = dateFormatter.string(from: NSDate.now)
			 testString = self.inputText.text.description
		 }
		 var urlComponent = URLComponents(string: "https://www.lehe.com/")
		urlComponent?.queryItems = [URLQueryItem(name: "date", value: dateString),URLQueryItem(name: "test", value: testString)]
        print("url: %@", (urlComponent?.string)!)
        return NFCNDEFPayload.wellKnownTypeURIPayload(url: (urlComponent?.url)!)
    }

	//MARK: - Delegate 6、代理、数据源
	func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.dataArray.count
	}

	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return 40
	}

	func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return 0.01
	}

	func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
		return 0.01
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		var cell:UITableViewCell? = tableView.dequeueReusableCell(withIdentifier: "cell")
		if cell == nil {
			cell = UITableViewCell.init(style: .default, reuseIdentifier: "cell")
		}
		let message = self.dataArray[indexPath.row]
		let unit = message.records.count == 1 ? "Payload" : "Payloads"
		cell?.textLabel?.text = message.records.count.description + unit
		cell?.selectionStyle = UITableViewCell.SelectionStyle.none
		return cell ?? UITableViewCell.init()
	}

	//点击查看
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let message = self.dataArray[indexPath.row]
		let payload = message.records.first!
		var title:String?
		switch payload.typeNameFormat {
		case .nfcWellKnown:
			if  let type = String(data: payload.type, encoding: .utf8) {
				if let url = payload.wellKnownTypeURIPayload() {
					 title = "\(payload.typeNameFormat.description): \(type), \(url.absoluteString)"
				}else{
					var additionInfo: String? = ""
				    (additionInfo, _) = payload.wellKnownTypeTextPayload()
					title = "\(payload.typeNameFormat.description): \(type),\(additionInfo!)"
				}
			}
			break
		case .absoluteURI:
			if let text = String(data: payload.payload, encoding: .utf8) {
				title = text
			}
			break
		case .media:
			if let type = String(data: payload.type, encoding: .utf8) {
				title = type
			}
			break
		case.nfcExternal,.empty,.unknown,.unchanged:
			title = "..."
			break
		@unknown default:
			title = payload.typeNameFormat.description
			break
		}


		let alertVC = UIAlertController(title: title, message: nil, preferredStyle: UIAlertController.Style.alert)
		alertVC.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
		self.present(alertVC, animated: true, completion: nil)

	}

	//MARK:NFCNDEFReaderSessionDelegate
	func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
		if let readerError = error as? NFCReaderError {
			if (readerError.code != .readerSessionInvalidationErrorFirstNDEFTagRead)
				&& (readerError.code != .readerSessionInvalidationErrorUserCanceled){
				let alertVC = UIAlertController(title: "通信错误", message: error.localizedDescription, preferredStyle: UIAlertController.Style.alert)
				alertVC.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
				DispatchQueue.main.async {
					self.present(alertVC, animated: true, completion: nil)
				}
			}
		}
		self.session = nil
	}

	func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
		DispatchQueue.main.async {
			self.dataArray.append(contentsOf: messages)
			self.tableView .reloadData()
		}
	}

	//新方法
	@available(iOS 13.0, *)
	func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
		if tags.count > 1 {
			session.alertMessage = "More than 1 tag is detected, please remove all tags and try again."
            self.tagRemovalDetect(tags.first!)
			return
		}
		let tag = tags.first!
		session.connect(to: tag) { (error: Error?) in
			if nil != error {
				session.restartPolling()
				return
			}

			tag.queryNDEFStatus { (ndefStatus: NFCNDEFStatus, capacity :Int, error :Error?) in
		        if error != nil {
					session.invalidate(errorMessage: "Fail to determine NDEF status.  Please try again.")
					return
				}
				if self.isWrite {//写入
				if ndefStatus == .readOnly {
					  session.invalidate(errorMessage: "Tag is not writable.")
				  } else if ndefStatus == .readWrite {
					  if self.ndefMessage!.length > capacity {
						  session.invalidate(errorMessage: "Tag capacity is too small.  Minimum size requirement is \(self.ndefMessage!.length) bytes.")
						  return
					  }

					  tag.writeNDEF(self.ndefMessage!) { (error: Error?) in
						  if error != nil {
							  session.invalidate(errorMessage: "Update tag failed. Please try again.")
						  } else {
							  session.alertMessage = "Update success!"
							  session.invalidate()
						  }
					  }
				  } else {
					  session.invalidate(errorMessage: "Tag is not NDEF formatted.")
				  }

				}else{//读取
					if .notSupported == ndefStatus {
						session.alertMessage = "Tag is not NDEF compliant"
						session.invalidate()
						return
					}

					tag.readNDEF { (message: NFCNDEFMessage?, error :Error?) in
						var statusMessage: String
						if nil != error || nil == message {
							statusMessage = "Fail to read NDEF from tag"
						}else{
							statusMessage = "Found 1 NDEF message"
							DispatchQueue.main.async {
								self.dataArray.append(message!)
								self.tableView.reloadData()
							}
						}
						session.alertMessage = statusMessage
						session.invalidate()
					}

				}

			}
		}
	}

	func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
		if self.isWrite {
			print("初始化写入数据")
			let textPayload = NFCNDEFPayload.wellKnownTypeTextPayload(
				string: "Brought to you by the Great Fish Company",
				locale: Locale(identifier: "En")
			)
			let urlPayload = self.createURLPayload()
			ndefMessage = NFCNDEFMessage(records: [urlPayload!, textPayload!])
			print("MessageSize=%d", ndefMessage!.length)
		}
	}



	//MARK: - interface 7、UI处理

	//MARK: - lazy loading 8、懒加载



}
