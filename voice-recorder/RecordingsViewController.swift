//
//  RecordingsViewController.swift
//  voice-recorder
//
//  Created by Tomas Radvansky on 20/11/2016.
//  Copyright © 2016 Tomas Radvansky. All rights reserved.
//

import Foundation
import UIKit
import Font_Awesome_Swift
import FDWaveformView
import AVFoundation
import SwiftDate
import FCUUID

class RecordinsViewController: UIViewController {
    var audioRecorder: AVAudioRecorder!
    
    @IBOutlet weak var mainButton: ALLocalizableButton!
    @IBOutlet weak var waveformView: WaveformView!
    
    @IBOutlet weak var createdLabel: UILabel!
    @IBOutlet weak var sizeLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    
    var createdDate = Date()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.mainButton.setFAIcon(icon: .FAStop, forState: .normal)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let filePath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] + "/" + FCUUID.uuid() + ".m4a"
        
        audioRecorder = audioRecorder(URL(fileURLWithPath:filePath))
        audioRecorder.record()
        self.createdDate = Date()
        self.createdLabel.text = Date().string(dateStyle: .short, timeStyle: .short, in: nil)
        self.durationLabel.text = stringFromTimeInterval(interval:Date().timeIntervalSince(self.createdDate))
        
        let displayLink = CADisplayLink(target: self, selector: #selector(updateMeters))
        displayLink.add(to: RunLoop.current, forMode: RunLoopMode.commonModes)
    }
    
    func stringFromTimeInterval(interval:TimeInterval) -> String {
        
        let seconds:Int = Int(interval.truncatingRemainder(dividingBy: 60.0))
        let minutes:Int = Int((interval / 60.0).truncatingRemainder(dividingBy: 60.0))
        let hours:Int = Int((interval / 3600))
        
        return String(format: "%0.2d:%0.2d:%0.2d",hours,minutes,seconds)
    }
    
    func updateMeters() {
        audioRecorder.updateMeters()
        let normalizedValue = pow(10, audioRecorder.averagePower(forChannel: 0) / 20)
        waveformView.updateWithLevel(CGFloat(normalizedValue))
        self.durationLabel.text = stringFromTimeInterval(interval:audioRecorder.currentTime)
        do
        {
            let path = audioRecorder.url.path
            if let size = try FileManager.default.attributesOfItem(atPath: path)[FileAttributeKey.size]
            {
                self.sizeLabel.text = ByteCountFormatter.string(fromByteCount: size as! Int64, countStyle: .file)
            }
            else
            {
                self.sizeLabel.text = "?"
            }
        }
        catch let error as NSError
        {
            print(error)
            self.sizeLabel.text = "?"
        }
    }
    
    func audioRecorder(_ filePath: URL) -> AVAudioRecorder {
        let recorderSettings: [String : AnyObject] = [
            AVSampleRateKey: 44100.0 as AnyObject,
            AVFormatIDKey: NSNumber(value: kAudioFormatMPEG4AAC),
            AVNumberOfChannelsKey: 2 as AnyObject,
            AVEncoderAudioQualityKey: AVAudioQuality.min.rawValue as AnyObject
        ]
        
        try! AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord)
        
        let audioRecorder = try! AVAudioRecorder(url: filePath, settings: recorderSettings)
        audioRecorder.isMeteringEnabled = true
        audioRecorder.prepareToRecord()
        
        return audioRecorder
    }
    
    @IBAction func mainButtonClicked(_ sender: Any) {
        audioRecorder.stop()
        self.dismiss(animated: true, completion: nil)
    }
    
}
